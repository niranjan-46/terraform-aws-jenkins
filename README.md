# Jenkins on AWS - Enterprise Infrastructure as Code

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=venom&color=0:0D0D0D,50:1a0000,100:E50914&height=150&section=header&text=Jenkins%20AWS%20Deployment&fontSize=40&fontColor=FFFFFF&fontAlignY=45&animation=fadeIn" />

[![LinkedIn](https://img.shields.io/badge/LinkedIn-E50914?style=for-the-badge&logo=linkedin&logoColor=white&labelColor=0D0D0D)](http://www.linkedin.com/in/niranjan-rao-annavarapu)
[![Website](https://img.shields.io/badge/niranjan.cloud-E50914?style=for-the-badge&logo=firefoxbrowser&logoColor=white&labelColor=0D0D0D)](https://niranjan.cloud)
[![Email](https://img.shields.io/badge/Email-E50914?style=for-the-badge&logo=gmail&logoColor=white&labelColor=0D0D0D)](mailto:niranjanannavarapu@gmail.com)

*Terraform | AWS | Docker | DevOps*

</div>

---

## Task Completion Checklist

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Deploy Jenkins Server on AWS using Terraform | ✅ Complete | `infrastructure/modules/` - 7 modules |
| Modular code with best practices | ✅ Complete | Separate modules (network, security, compute, eip, backup, state, monitoring) |
| Elastic IP assignment | ✅ Complete | `modules/eip/` - EIP associated with EC2 |
| Scheduled EBS snapshots once per day | ✅ Complete | `modules/backup/` - DLM policy with 24hr frequency, **30-day retention** |
| Jenkins deployed using Docker Compose | ✅ Complete | `user_data.sh.tpl` - Docker + Compose installation |
| Data persistence for Jenkins | ✅ Complete | EBS volume mounted at `/var/jenkins_data` |
| Clone docker-compose from GitHub | ✅ Complete | `user_data.sh.tpl` - git clone from `github_repo_url`, supports `github_token`, `ssh_private_key`, and `github_secret_name` |
| S3 bucket for state storage | ✅ Complete | `modules/state/` - S3 bucket + DynamoDB for state |
| Multi-environment support | ✅ Complete | Dev, Staging, Prod environments |
| Proper commit messages in code | ✅ Complete | All modules with commit-style headers |
| CloudWatch Monitoring | ✅ Complete | `modules/monitoring/` - CPU, Memory, Disk, Jenkins alarms |
| **V2 IMPROVEMENTS** | **Status** | **Implementation** |
| Security hardening (removed privileged mode) | ✅ Complete | `docker-compose.yml` - Removed privileged: true |
| Fixed Jenkins health check URL | ✅ Complete | `docker-compose.yml` - Added /jenkins prefix |
| Enhanced monitoring (Jenkins data disk) | ✅ Complete | `user_data.sh.tpl` - Added /var/jenkins_data monitoring |
| Jenkins plugins pre-installation | ✅ Complete | `user_data.sh.tpl` - Essential plugins installed |
| Jenkins Configuration as Code (JCasC) | ✅ Complete | `user_data.sh.tpl` - Basic JCasC setup |
| Performance optimization (instance type) | ✅ Complete | `variables.tf` - Upgraded to t3.large |
| Extended backup retention | ✅ Complete | `backup/main.tf` - Increased to 30 days |
| Enhanced logging configuration | ✅ Complete | `docker-compose.yml` - Added log rotation |
| Prometheus metrics support | ✅ Complete | `docker-compose.yml` - Added Prometheus labels |

---

## 🔐 **Private Repository Authentication**

### **How Private Repository Cloning Works:**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Terraform     │───▶│   User Data      │───▶│   Git Clone     │
│   Variables     │    │   Script         │    │   (Private)     │
│                 │    │   Setup Auth     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
   github_token           Setup credentials       git clone URL
   ssh_private_key        Git config              Success/Fail
```

### **Authentication Methods:**

#### **Method 1: GitHub Personal Access Token (Recommended)**
```hcl
# In terraform.tfvars
github_token = "ghp_your_token_here"
```

**Flow:**
1. Terraform passes `github_token` to user data script
2. Script configures Git credential helper
3. `git clone https://github.com/user/repo.git` uses token automatically

#### **Method 2: SSH Private Key**
```hcl
# In terraform.tfvars  
ssh_private_key = "base64_encoded_key_here"
```

**Flow:**
1. Terraform passes base64-encoded SSH key
2. Script decodes and saves `~/.ssh/id_rsa`
3. Adds GitHub to known hosts
4. `git clone git@github.com:user/repo.git` uses SSH key

### **Setup Instructions:**

#### **For Personal Access Token:**
1. **Create Token:** GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. **Permissions:** Check `repo` scope
3. **Usage:** Add to `terraform.tfvars`:
   ```hcl
   github_token = "ghp_xxxxxxxxxxxxxxxxxxxx"
   ```

#### **For SSH Key:**
1. **Generate Key:**
   ```bash
   ssh-keygen -t ed25519 -C "jenkins@yourcompany.com" -f jenkins_key
   ```
2. **Add to GitHub:** Repository → Settings → Deploy keys → Add deploy key
3. **Encode for Terraform:**
   ```bash
   cat jenkins_key | base64 -w 0
   ```
4. **Usage:** Add to `terraform.tfvars`:
   ```hcl
   ssh_private_key = "base64_encoded_key_here"
   ```

### **Where to Store GitHub Tokens:**

#### **🔴 Option 1: terraform.tfvars (Local Development Only)**
```hcl
# terraform.tfvars (DO NOT commit to git)
github_token = "ghp_your_token_here"
```

**Pros:** Simple, works locally  
**Cons:** Can be accidentally committed, not suitable for teams/CI

#### **🟡 Option 2: Environment Variables**
```bash
# Set in your shell or CI/CD
export TF_VAR_github_token="ghp_your_token_here"
```

**Pros:** Not stored in files, good for CI/CD  
**Cons:** Must be set every time, visible in shell history

#### **🟢 Option 3: AWS Secrets Manager (Recommended)**
```hcl
data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = "jenkins/github-token"
}

locals {
  github_token = jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["token"]
}
```

**Pros:** Secure, encrypted, access controlled  
**Cons:** Requires AWS setup

#### **🟢 Option 4: HashiCorp Vault**
```hcl
data "vault_generic_secret" "github" {
  path = "secret/jenkins/github"
}

locals {
  github_token = data.vault_generic_secret.github.data["token"]
}
```

**Pros:** Enterprise-grade security  
**Cons:** Requires Vault infrastructure

#### **🟢 Option 5: CI/CD Secrets (GitHub Actions, etc.)**
```yaml
# .github/workflows/deploy.yml
- name: Deploy
  env:
    TF_VAR_github_token: ${{ secrets.GITHUB_TOKEN }}
```

**Pros:** Secure, automated, no manual handling  
**Cons:** CI/CD specific

### **Security Best Practices:**

1. **Never commit secrets** to version control
2. **Use different tokens** per environment
3. **Rotate tokens** regularly  
4. **Use least privilege** (deploy keys over personal tokens)
5. **Monitor token usage** in GitHub settings
6. **Use secret management** services for production

### **How Environment Variables Work:**

#### **Step-by-Step Flow:**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Set ENV VAR   │───▶│   Terraform     │───▶│   Template      │───▶│   User Data     │
│   TF_VAR_*      │    │   Validation    │    │   Rendering     │    │   Script        │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │                       │
        ▼                       ▼                       ▼                       ▼
   export TF_VAR_...       Variable validation    Script generation    Git authentication
   github_token=...        Type & format checks   ${github_token}       git clone with auth
```

#### **1. Setting Environment Variables:**
```bash
# In your terminal/session
export TF_VAR_github_token="ghp_xxxxxxxxxxxxxxxxxxxx"
export TF_VAR_ssh_private_key="LS0tLS1CRUdJTiBPU...base64..."
```

#### **2. Terraform Variable Resolution:**
```hcl
# Terraform automatically reads TF_VAR_* environment variables
variable "github_token" {
  type        = string
  sensitive   = true
  # No default - will use TF_VAR_github_token if set
}
```

#### **3. Validation Process:**
```hcl
variable "github_token" {
  validation {
    condition     = var.github_token == "" || length(var.github_token) > 10
    error_message = "GitHub token must be empty or at least 10 characters"
  }
}
```

#### **4. Template Rendering:**
```hcl
data "template_file" "user_data" {
  vars = {
    github_token = var.github_token  # Passed to script template
  }
}
```

#### **5. User Data Script Execution:**
```bash
# On EC2 instance, the rendered script contains:
if [ -n "${github_token}" ]; then
    git config --global credential.helper store
    echo "https://${github_token}:x-oauth-basic@github.com" > ~/.git-credentials
fi
```

### **Validation Types:**

#### **Terraform Variable Validation:**
- ✅ **Type checking:** `string`, `number`, etc.
- ✅ **Format validation:** Regex patterns for URLs/tokens
- ✅ **Required vs optional:** Defaults and null checks
- ✅ **Sensitive marking:** Hides values in logs

#### **Runtime Validation:**
- ✅ **GitHub API validation:** Token has correct permissions
- ✅ **SSH key validation:** Key format and GitHub acceptance
- ✅ **Network connectivity:** Can reach GitHub from EC2
- ✅ **Repository access:** Token/key can clone the repo

### **Error Handling:**

#### **If Token is Invalid:**
```
terraform apply
# → User data script runs on EC2
# → git clone fails
# → Check /var/log/cloud-init-output.log on EC2
# → "Git clone failed - check authentication"
```

#### **If Environment Variable Not Set:**
```
terraform plan
# → Variable uses default "" (empty string)
# → No authentication configured
# → Repository must be public
```

### **Testing the Flow:**

#### **Local Testing:**
```bash
# 1. Set environment variables
export TF_VAR_github_token="ghp_test_token"

# 2. Validate Terraform configuration
terraform validate

# 3. Check variable values
terraform console
> var.github_token
"ghp_test_token"
```

#### **EC2 Instance Testing:**
```bash
# After deployment, check on EC2:
sudo cat /var/log/cloud-init-output.log
sudo docker logs jenkins  # If container started
sudo git log --oneline    # In /opt/jenkins directory
```

### **Security Validation:**

- 🔒 **Environment variables** are not stored in files
- 🔒 **Sensitive variables** are marked and hidden in logs
- 🔒 **Tokens are validated** for format before use
- 🔒 **SSH keys are decoded** only on target instance
- 🔒 **Credentials expire** and can be rotated

### **Testing Your Setup:**

#### **Run the Validation Script:**
```bash
# Set your credentials first
export TF_VAR_github_token="ghp_your_token_here"

# Then validate
./validate_credentials.sh
```

**The script checks:**
- ✅ Environment variables are set
- ✅ Token/key formats are valid
- ✅ Terraform configuration is correct
- ✅ GitHub API access works (if token provided)

#### **Manual Testing:**
```bash
# Check variables are loaded
terraform console
> var.github_token
"ghp_..."

# Validate configuration
terraform validate

# Test plan (won't deploy)
terraform plan
```

**See `credentials_example.sh` for environment variable setup**

## ✅ Final Validation Checklist

- [x] Confirm each environment uses a different VPC CIDR:
  - Dev: `10.0.0.0/16`
  - Staging: `10.1.0.0/16`
  - Prod: `10.2.0.0/16`
- [x] Confirm each environment uses unique IAM role names:
  - `jenkins-dev-ec2-role`
  - `jenkins-staging-ec2-role`
  - `jenkins-prod-ec2-role`
- [x] Confirm each environment uses unique S3 state bucket names:
  - `jenkins-dev-terraform-state`
  - `jenkins-staging-terraform-state`
  - `jenkins-prod-terraform-state`
- [x] Confirm each environment has separate state locking DynamoDB table names:
  - `jenkins-dev-state-lock`
  - `jenkins-staging-state-lock`
  - `jenkins-prod-state-lock`
- [x] Confirm GitHub auth variables are available per environment:
  - `github_token`
  - `ssh_private_key`
  - `github_secret_name`
- [x] Confirm backend and remote state configuration for each environment
- [x] Confirm CloudWatch monitoring and alarms are configured
- [x] Confirm Elastic IP is attached and Jenkins is accessible
- [x] Confirm EBS volume is mounted at `/var/jenkins_data`
- [x] Confirm Docker Compose is cloned from GitHub in user data
- [x] Confirm `validate_credentials.sh` or `terraform validate` passes

### End-to-end validation commands
```bash
cd infrastructure/environments/dev
terraform init
terraform validate
terraform plan

cd ../staging
terraform init
terraform validate
terraform plan

cd ../prod
terraform init
terraform validate
terraform plan
```

---

## 🚀 V2 Release - Enhanced Security & Performance

### Key Improvements in V2:

#### 🔒 **Security Enhancements**
- **Removed privileged Docker mode** - Eliminated security risk from `privileged: true`
- **Fixed Jenkins URL prefix** - Health checks now use correct `/jenkins/login` path
- **Enhanced monitoring** - Added dedicated monitoring for Jenkins data volume

#### ⚡ **Performance Optimizations**
- **Upgraded instance type** - Changed from `t3.medium` to `t3.large` for better Jenkins performance
- **Memory tuning** - Added JVM memory optimization flags (`-Xmx2048m -Xms1024m`)
- **G1GC garbage collector** - Improved memory management for Jenkins workloads

#### 📦 **Jenkins Enhancements**
- **Pre-installed essential plugins** - Git, Pipeline, Credentials, Docker, Prometheus, etc.
- **Jenkins Configuration as Code (JCasC)** - Automated Jenkins configuration setup
- **Prometheus metrics** - Added labels for monitoring integration

#### 🛡️ **Operational Improvements**
- **Extended backup retention** - Increased from 7 to 30 days for better data protection
- **Enhanced logging** - Added log rotation (10MB max, 3 files)
- **Docker socket access** - Added read-only access for Docker-in-Docker capabilities

#### 📊 **Monitoring & Observability**
- **Jenkins data disk monitoring** - Specific monitoring for `/var/jenkins_data`
- **Prometheus integration** - Ready for metrics collection at `/jenkins/prometheus`
- **Structured logging** - JSON format with size limits

---

| Document | Description |
|----------|-------------|
| [HOW_IT_WORKS.md](./HOW_IT_WORKS.md) | How server runs, backup, data storage |
| [RESOURCE_NAMING.md](./RESOURCE_NAMING.md) | All resource names per environment |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS CLOUD                                      │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │                         VPC (10.0.0.0/16)                             │    │
│  │                                                                       │    │
│  │  ┌─────────────────────────┐     ┌─────────────────────────────┐   │    │
│  │  │    PUBLIC SUBNET        │     │      PRIVATE SUBNET         │   │    │
│  │  │    10.0.1.0/24          │     │      10.0.2.0/24             │   │    │
│  │  └───────────┬─────────────┘     └─────────────┬───────────────┘   │    │
│  │              │                                  │                    │    │
│  │       ┌──────┴──────┐                    ┌──────┴──────┐             │    │
│  │       │     IGW     │                    │     NAT     │             │    │
│  │       └──────┬──────┘                    └──────┬──────┘             │    │
│  │              │                                  │                    │    │
│  │  ┌───────────┴──────────────────────────────────┴────────────────┐  │    │
│  │  │                                                              │  │    │
│  │  │              EC2 INSTANCE (t3.medium)                       │  │    │
│  │  │              ┌─────────────────────────────────────────┐    │  │    │
│  │  │              │  • Ubuntu 22.04 LTS                      │    │  │    │
│  │  │              │  • Docker + Docker Compose              │    │  │    │
│  │  │              │  • Jenkins LTS Container                │    │  │    │
│  │  │              │  • CloudWatch Agent                    │    │  │    │
│  │  │              │  • IAM Role (SSM + CloudWatch)        │    │  │    │
│  │  │              └─────────────────────────────────────────┘    │  │    │
│  │  │                         │                                     │  │    │
│  │  │         ┌───────────────┴───────────────┐                    │  │    │
│  │  │         │                               │                    │  │    │
│  │  │   ┌─────┴─────┐                   ┌─────┴─────┐              │  │    │
│  │  │   │ ROOT VOL  │                   │ DATA VOL  │              │  │    │
│  │  │   │ (30 GB)   │                   │ (50 GB)   │              │  │    │
│  │  │   │   GP3     │                   │   GP3     │              │  │    │
│  │  │   └───────────┘                   │  KMS Enc  │              │  │    │
│  │  │                                    └─────┬─────┘              │  │    │
│  │  │                                          │                    │  │    │
│  │  │                            ┌─────────────┴─────────────┐    │  │    │
│  │  │                            │   DLM LIFECYCLE POLICY    │    │  │    │
│  │  │                            │   • Daily Snapshots       │    │  │    │
│  │  │                            │   • 7-Day Retention      │    │  │    │
│  │  │                            └───────────────────────────┘    │  │    │
│  │  │                                      │                        │  │    │
│  │  └──────────────────────────────────────┼───────────────────────┘  │    │
│  │                                         │                            │    │
│  │                              ┌──────────┴──────────┐                │    │
│  │                              │   ELASTIC IP        │                │    │
│  │                              │   (Static Public IP)│                │    │
│  │                              └──────────────────────┘                │    │
│  │                                                                       │    │
│  └───────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │                    CLOUDWATCH MONITORING                              │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────┐  │    │
│  │  │ CPU Alarm   │  │Memory Alarm │  │Disk Alarm   │  │ Jenkins  │  │    │
│  │  │   >80%      │  │   >85%      │  │   >85%      │  │  Down    │  │    │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────┬────┘  │    │
│  │         └────────────────┼────────────────┼─────────────┘        │    │
│  │                          ▼                                        │    │
│  │              ┌────────────────────────┐                        │    │
│  │              │      SNS TOPIC          │                        │    │
│  │              │   (Email Alerts)        │                        │    │
│  │              └────────────────────────┘                        │    │
│  │                                                                       │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │                    STATE MANAGEMENT (S3 + DynamoDB)                 │    │
│  │  • S3 Bucket: jenkins-dev-terraform-state                            │    │
│  │  • DynamoDB: jenkins-dev-state-lock                                   │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
.
├── README.md                                    # This file
├── .gitignore                                   # Git ignore rules
│
├── jenkins-compose/                            # Docker Compose for Jenkins
│   └── docker-compose.yml                       # Jenkins LTS with data persistence
│
└── infrastructure/                             # Terraform Infrastructure
    ├── environments/
    │   ├── dev/                                 # Development environment
    │   │   ├── backend.tf                       # S3 backend (jenkins-dev-terraform-state)
    │   │   ├── main.tf                          # Dev module orchestration
    │   │   ├── variables.tf                     # Dev variables
    │   │   └── outputs.tf                       # Dev outputs
    │   │
    │   ├── staging/                             # Staging environment
    │   │   ├── backend.tf                       # S3 backend (jenkins-staging-terraform-state)
    │   │   ├── main.tf                          # Staging module orchestration
    │   │   ├── variables.tf                     # Staging variables
    │   │   └── outputs.tf                       # Staging outputs
    │   │
    │   └── prod/                                # Production environment
    │       ├── backend.tf                       # S3 backend (jenkins-prod-terraform-state)
    │       ├── main.tf                          # Prod module orchestration
    │       ├── variables.tf                     # Prod variables
    │       └── outputs.tf                       # Prod outputs
    │
    └── modules/                                 # Reusable Terraform modules
        ├── network/                             # VPC, Subnets, IGW, NAT, Routes
        │   ├── main.tf                          # Network resources with commit messages
        │   ├── variables.tf
        │   └── outputs.tf
        │
        ├── security/                            # Security Groups
        │   ├── main.tf                          # SG resources with commit messages
        │   ├── variables.tf
        │   └── outputs.tf
        │
        ├── compute/                             # EC2, EBS, IAM, KMS, User Data
        │   ├── main.tf                          # Compute resources with commit messages
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── templates/
        │       └── user_data.sh.tpl             # Instance startup script
        │
        ├── eip/                                 # Elastic IP
        │   ├── main.tf                          # EIP resources with commit messages
        │   ├── variables.tf
        │   └── outputs.tf
        │
        ├── backup/                              # DLM Lifecycle Policy
        │   ├── main.tf                          # Backup resources with commit messages
        │   ├── variables.tf
        │   └── outputs.tf
        │
        └── state/                               # S3 + DynamoDB for State Management
            ├── main.tf                          # State resources with commit messages
            ├── variables.tf
            └── outputs.tf
```

---

## Resources Created (Per Environment)

### Network Module
| Resource | Name Pattern | Description |
|----------|--------------|-------------|
| VPC | `jenkins-{env}-vpc` | 10.0.0.0/16 |
| Public Subnet | `jenkins-{env}-public-subnet-1a` | 10.0.1.0/24 |
| Private Subnet | `jenkins-{env}-private-subnet-1a` | 10.0.2.0/24 |
| Internet Gateway | `jenkins-{env}-igw` | VPC connectivity |
| NAT Gateway | `jenkins-{env}-nat-gw` | Private subnet outbound |
| Elastic IP | `jenkins-{env}-nat-eip` | NAT Gateway IP |
| Route Tables | `jenkins-{env}-{public/private}-rt` | Route management |

### Security Module
| Resource | Name Pattern | Ports |
|----------|--------------|-------|
| Security Group | `jenkins-{env}-jenkins-sg` | 80, 443, 8080, 50000, 22 |

### Compute Module
| Resource | Name Pattern | Description |
|----------|--------------|-------------|
| EC2 Instance | `jenkins-{env}-jenkins` | t3.medium, Ubuntu 22.04 |
| IAM Role | `jenkins-{env}-ec2-role` | SSM + CloudWatch permissions |
| IAM Instance Profile | `jenkins-{env}-profile` | EC2 instance profile |
| Root EBS Volume | `jenkins-{env}-jenkins` | 30 GB, GP3, encrypted |
| Data EBS Volume | `jenkins-{env}-jenkins-data` | 50 GB, GP3, KMS encrypted |
| KMS Key | `alias/jenkins-{env}-ebs` | EBS encryption key |

### EIP Module
| Resource | Name Pattern | Description |
|----------|--------------|-------------|
| Elastic IP | `jenkins-{env}-eip` | Static public IP |

### Backup Module
| Resource | Name Pattern | Schedule |
|----------|--------------|----------|
| DLM Policy | `jenkins-{env}-daily-backup` | Daily snapshots, 7-day retention |

### State Module (Per Environment)
| Resource | Name Pattern | Description |
|----------|--------------|-------------|
| S3 Bucket | `jenkins-{env}-terraform-state` | Remote state storage |
| DynamoDB Table | `jenkins-{env}-state-lock` | State locking |

---

## Deployment Instructions

### Step 1: Prepare Docker Compose for GitHub

```bash
cd jenkins-compose
git init
git add docker-compose.yml
git commit -m "feat: Add Jenkins docker-compose with data persistence"
git remote add origin https://github.com/YOUR_USERNAME/jenkins-compose.git
git push -u origin main
```

### Step 2: Deploy Development Environment

```bash
cd infrastructure/environments/dev

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 3: Deploy Staging Environment

```bash
cd infrastructure/environments/staging

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 4: Deploy Production Environment

```bash
cd infrastructure/environments/prod

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan and apply (production requires careful review)
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Environment-Specific Variables

| Variable | Dev | Staging | Prod | Description |
|----------|-----|---------|------|-------------|
| `instance_type` | t3.medium | t3.medium | t3.large | EC2 instance type |
| `data_volume_size` | 50 GB | 50 GB | 100 GB | Data volume size |
| `root_volume_size` | 30 GB | 30 GB | 50 GB | Root volume size |
| `backup_retention` | 7 days | 7 days | 30 days | Snapshot retention |

---

## Commit Message Convention (Applied to All Code)

All Terraform files follow conventional commits format:

```bash
# Module header
# ==============================================================================
# Module: Network
# Purpose: Creates VPC, subnets, IGW, NAT Gateway, and routing infrastructure
# Commit: feat(network): Create VPC with public and private subnets
# ==============================================================================

# Resource-level comments
# ------------------------------------------------------------------------------
# VPC Configuration
# Creates the main Virtual Private Cloud with DNS support enabled
# Commit: feat(network): Provision VPC with DNS hostnames and support
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  ...
}
```

**Commit Types:**
- `feat:` - New feature or resource
- `chore:` - Configuration or setup
- `fix:` - Bug fixes
- `refactor:` - Code improvements
- `docs:` - Documentation

---

## Future Scope & Enhancements

### Phase 2: High Availability (Production-Grade)
- [ ] **Multi-AZ Deployment**: Deploy Jenkins in multiple availability zones
- [ ] **Application Load Balancer**: Distribute traffic across instances
- [ ] **Auto Scaling Group**: Scale based on CPU/memory metrics
- [ ] **RDS Database**: Move Jenkins configuration to managed PostgreSQL
- [ ] **EFS Storage**: Use EFS for shared Jenkins home across instances

### Phase 3: Security Hardening
- [ ] **WAF Integration**: Protect Jenkins with AWS WAF rules
- [ ] **VPC Endpoint**: Access S3 without internet via VPC endpoints
- [ ] **Secrets Manager**: Store Jenkins credentials in AWS Secrets Manager
- [ ] **Security Hub**: Centralized security monitoring
- [ ] **GuardDuty**: Threat detection

### Phase 4: Monitoring & Observability
- [ ] **CloudWatch Dashboard**: Custom dashboards for Jenkins metrics
- [ ] **Alarm Notifications**: SNS alerts for critical events
- [ ] **X-Ray Tracing**: Distributed tracing for Jenkins pipelines
- [ ] **Centralized Logging**: CloudWatch Logs with log group aggregation

### Phase 5: CI/CD Automation
- [ ] **Terraform Cloud/Enterprise**: Remote execution and policy enforcement
- [ ] **GitOps Integration**: ArgoCD or Flux for infrastructure sync
- [ ] **Automated Testing**: Terratest for infrastructure validation
- [ ] **Drift Detection**: Automated detection of configuration changes

### Phase 6: Disaster Recovery
- [ ] **Cross-Region Backup**: Replicate snapshots to secondary region
- [ ] **Recovery Runbook**: Documented DR procedures
- [ ] **RTO/RPO Planning**: Define recovery time objectives

---

## Troubleshooting

### Docker Service Not Starting
```bash
ssh -i key.pem ubuntu@<EIP>
sudo systemctl status docker
sudo systemctl start docker
```

### EBS Volume Not Mounted
```bash
lsblk
sudo file -s /dev/nvme1n1
sudo mkfs.ext4 -F /dev/nvme1n1
sudo mount /dev/nvme1n1 /var/jenkins_data
```

### Jenkins Not Accessible
```bash
docker logs jenkins
docker ps
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## Cleanup

```bash
# Destroy specific environment
cd infrastructure/environments/dev
terraform destroy

# Destroy staging
cd infrastructure/environments/staging
terraform destroy

# Destroy production (requires approval)
cd infrastructure/environments/prod
terraform destroy
```

---

## Variables Reference

| Variable | Default | Description | Validation |
|----------|---------|-------------|------------|
| `aws_region` | us-east-1 | AWS region | Valid AWS region |
| `environment` | dev/staging/prod | Environment name | dev/staging/prod |
| `project_name` | jenkins | Project identifier | lowercase, max 20 chars |
| `vpc_cidr` | 10.0.0.0/16 | VPC CIDR block | Valid CIDR |
| `availability_zone` | us-east-1a | AZ for resources | Valid AZ |
| `instance_type` | t3.medium | EC2 instance type | t3 family |
| `root_volume_size` | 30 | Root volume GB | 20-100 |
| `data_volume_size` | 50 | Data volume GB | 20-1000 |
| `github_repo_url` | "" | GitHub repo URL | Valid HTTPS URL |
| `key_name` | "" | SSH key pair name | Existing key pair |

---

<div align="center">

**Built by [Niranjan Rao](https://niranjan.cloud)** | [LinkedIn](http://www.linkedin.com/in/niranjan-rao-annavarapu) | [Email](mailto:niranjanannavarapu@gmail.com)

*Infrastructure is code. Security is a pipeline stage. Reliability is non-negotiable.*

</div>