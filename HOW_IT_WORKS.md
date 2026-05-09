# How Jenkins Server Works

## Overview

This document explains how the Jenkins server is deployed, runs, takes backups, and where all data is stored.

---

## 1. Server Deployment Flow

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│ Terraform   │───▶│   AWS        │───▶│   EC2       │───▶│  Jenkins     │
│ Init        │    │   Provision  │    │   Instance  │    │  Container   │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
```

### Step-by-Step:

1. **Terraform Init** - Downloads AWS provider, initializes S3 backend
2. **Terraform Apply** - Creates all AWS resources in sequence:
   - VPC & Networking → Security Groups → EC2 + EBS → EIP → DLM Policy
3. **User Data Script** - On first boot, EC2 executes `user_data.sh`:
   - Installs Docker & Docker Compose
   - Mounts data EBS volume to `/var/jenkins_data`
   - Clones docker-compose.yml from GitHub
   - Starts Jenkins container

---

## 2. How Jenkins Runs

### Container Architecture

```
┌─────────────────────────────────────────────┐
│              EC2 Instance (Ubuntu)           │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │         Docker Container                │ │
│  │                                         │ │
│  │   ┌───────────────────────────────┐    │ │
│  │   │      Jenkins LTS              │    │ │
│  │   │      (Port 8080)              │    │ │
│  │   │                               │    │ │
│  │   │   /var/jenkins_home          │    │ │
│  │   │        ↓                     │    │ │
│  │   └───────────┬───────────────────┘    │ │
│  │               │                        │ │
│  │   ┌───────────┴───────────────────┐    │ │
│  │   │   /var/jenkins_data            │    │ │
│  │   │   (EBS Volume - Persistent)   │    │ │
│  │   └───────────────────────────────┘    │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  Host: /var/jenkins_data ←── EBS Volume      │
└─────────────────────────────────────────────┘
```

### Start Commands (Inside EC2)

```bash
# Docker Compose starts Jenkins
cd /opt/jenkins
docker-compose up -d

# Access Jenkins
# http://<ELASTIC-IP>:8080
```

---

## 3. Data Storage Location

### Where is data stored?

| Data Type | Location | Storage Type |
|-----------|----------|--------------|
| **Jenkins Config** | `/var/jenkins_home` | EBS Volume ( mounted at `/var/jenkins_data`) |
| **Job Configs** | `/var/jenkins_home/jobs` | EBS Volume |
| **Build Artifacts** | `/var/jenkins_home/workspaces` | EBS Volume |
| **Plugins** | `/var/jenkins_home/plugins` | EBS Volume |
| **Build History** | `/var/jenkins_home/jobs/*/builds` | EBS Volume |

### Data Flow

```
Jenkins Container
      │
      ▼
/var/jenkins_home (inside container)
      │
      ▼
/var/jenkins_data (host directory)
      │
      ▼
/dev/nvme1n1 (EBS Volume - 50GB)
      │
      ▼
┌────────────────────────────────────────────┐
│  AWS EBS Volume (KMS Encrypted)            │
│  Volume ID: vol-xxxxxxxx                   │
│  Size: 50GB (GP3)                          │
│  Mount: /var/jenkins_data                  │
└────────────────────────────────────────────┘
```

---

## 4. Backup Process

### How Daily Snapshots Work

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS DLM (Data Lifecycle Manager)            │
│                                                                  │
│  Schedule: Daily (24 hours)                                     │
│  Retention: 7 days                                              │
│  Target: Jenkins Data EBS Volume                                │
│                                                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │ Day 1   │  │ Day 2   │  │ Day 3   │  │ Day 4   │  ...      │
│  │ Snap-1  │  │ Snap-2  │  │ Snap-3  │  │ Snap-4  │           │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘           │
│       │            │            │            │                 │
│       ▼            ▼            ▼            ▼                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  EBS Snapshot Retention Policy (Auto-Delete)           │   │
│  │  • Keep last 7 snapshots                                │   │
│  │  • Auto-delete older snapshots                          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Backup Configuration

| Setting | Value |
|---------|-------|
| **Schedule** | Every 24 hours |
| **Retention** | 7 days |
| **Target Volume** | Jenkins Data EBS |
| **Snapshot Type** | Consistent (crash-consistent) |
| **Copy Tags** | Yes (adds `BackupType=DailySnapshot`) |

### View Snapshots in AWS Console

```
AWS Console → EC2 → Elastic Block Store → Snapshots
```

Snapshot naming: `jenkins-{env}-daily-backup-*`

---

## 5. State Storage (Terraform)

### Where Terraform state is stored?

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS S3 Bucket                            │
│  Bucket: jenkins-{env}-terraform-state                      │
│  Key: infrastructure/terraform.tfstate                      │
│  Region: us-east-1                                          │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  terraform.tfstate                                    │  │
│  │  • VPC ID                                             │  │
│  │  • Subnet IDs                                         │  │
│  │  • Instance IDs                                       │  │
│  │  • Volume IDs                                         │  │
│  │  • All resource references                           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│                  AWS DynamoDB                               │
│  Table: jenkins-{env}-state-lock                            │
│  Purpose: Prevents concurrent terraform apply               │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  LockID              │  Status    │  Info            │  │
│  │  jenkins-dev:12345   │  LOCKED    │  terraform apply │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. CloudWatch Monitoring

### How Monitoring Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CLOUDWATCH MONITORING ARCHITECTURE                       │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    EC2 Instance                                      │    │
│  │                                                                       │    │
│  │   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │    │
│  │   │  CPU Metrics    │  │  Memory Metrics │  │  Disk Metrics   │     │    │
│  │   │  (cpu_usage)    │  │  (mem_used)     │  │  (disk_used)    │     │    │
│  │   └────────┬────────┘  └────────┬────────┘  └────────┬────────┘     │    │
│  │            │                    │                    │               │    │
│  │            └────────────────────┼────────────────────┘               │    │
│  │                                 ▼                                    │    │
│  │                    ┌─────────────────────┐                          │    │
│  │                    │  CloudWatch Agent  │                          │    │
│  │                    │  (Installed on EC2)│                          │    │
│  │                    └──────────┬──────────┘                          │    │
│  └────────────────────────────────┼────────────────────────────────────┘    │
│                                   │                                        │
│                                   ▼                                        │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                      AWS CloudWatch                                 │    │
│  │                                                                       │    │
│  │   ┌────────────────┐  ┌────────────────┐  ┌────────────────┐       │    │
│  │   │ CPU Alarm      │  │ Memory Alarm   │  │ Disk Alarm     │       │    │
│  │   │ Threshold: 80% │  │ Threshold: 85% │  │ Threshold: 85% │       │    │
│  │   └───────┬────────┘  └───────┬────────┘  └───────┬────────┘       │    │
│  │           └───────────────────┼───────────────────┘                 │    │
│  │                               ▼                                      │    │
│  │                    ┌─────────────────────┐                          │    │
│  │                    │    SNS Topic       │                          │    │
│  │                    │   (Email Alerts)   │                          │    │
│  │                    └─────────────────────┘                          │    │
│  │                                                                       │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### CloudWatch Agent Installation

The CloudWatch agent is installed via user data script on EC2 first boot:

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
```

### Metrics Collected

| Metric | Namespace | Collection Interval |
|--------|-----------|---------------------|
| CPU Utilization | CWAgent | 60 seconds |
| Memory Usage | CWAgent | 60 seconds |
| Disk Usage | CWAgent | 60 seconds |
| Disk I/O | CWAgent | 60 seconds |

### CloudWatch Alarms

| Alarm Name | Metric | Threshold | Action |
|------------|--------|-----------|--------|
| `jenkins-{env}-cpu-utilization-high` | CPUUtilization | > 80% | SNS Alert |
| `jenkins-{env}-memory-utilization-high` | mem_used_percent | > 85% | SNS Alert |
| `jenkins-{env}-disk-root-high` | disk_used_percent | > 85% | SNS Alert |
| `jenkins-{env}-jenkins-service-down` | Docker running | < 1 | SNS Alert |
| `jenkins-{env}-ebs-iops-high` | VolumeWriteOps | > 10000 | SNS Alert |

### View Metrics in AWS Console

```
AWS Console → CloudWatch → Metrics → All Metrics
├── CWAgent
│   ├── InstanceId = i-xxxxx
│   └── metric = mem_used_percent, disk_used_percent, cpu_usage
└── AWS/EC2
    ├── InstanceId = i-xxxxx
    └── metric = CPUUtilization
```

### View Alarms in AWS Console

```
AWS Console → CloudWatch → Alarms → All Alarms
├── jenkins-dev-cpu-utilization-high
├── jenkins-dev-memory-utilization-high
├── jenkins-dev-disk-root-high
└── jenkins-dev-jenkins-service-down
```

### CloudWatch Log Groups

| Log Group | Retention | Description |
|-----------|-----------|-------------|
| `/jenkins/jenkins-{env}/jenkins-server` | 7 days | Jenkins application logs |
| `/jenkins/jenkins-{env}/docker` | 7 days | Docker container logs |

---

## 7. Quick Commands

### Connect to Jenkins Server

```bash
ssh -i your-key.pem ubuntu@<ELASTIC-IP>
```

### Check Docker Status

```bash
docker ps
docker-compose -f /opt/jenkins/docker-compose.yml ps
```

### View Jenkins Logs

```bash
docker logs jenkins
```

### Get Initial Admin Password

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Check Data Volume

```bash
ls -la /var/jenkins_data
df -h /var/jenkins_data
```

### Manual Backup (Snapshot)

```bash
aws ec2 create-snapshot \
  --volume-id vol-xxxxxxxx \
  --description "Manual backup - $(date)"
```

---

## Summary

| Component | Description |
|-----------|-------------|
| **Deployment** | Terraform creates EC2 + EBS + EIP |
| **Startup** | User data script clones docker-compose and starts Jenkins |
| **Data Location** | EBS volume mounted at `/var/jenkins_data` |
| **Backup** | DLM creates daily snapshots, keeps 7 days |
| **State** | S3 bucket stores Terraform state |
| **Locking** | DynamoDB prevents concurrent apply |
| **Monitoring** | CloudWatch agent collects CPU, Memory, Disk metrics |
| **Alarms** | SNS notifications for CPU >80%, Memory >85%, Disk >85%, Jenkins down |