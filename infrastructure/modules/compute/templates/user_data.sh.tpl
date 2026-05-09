#!/bin/bash
set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Jenkins server initialization..."

# ==============================================================================
# Update and Install Base Packages
# ==============================================================================
log "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl git jq awscli docker.io docker-compose

# ==============================================================================
# Start Docker Service
# ==============================================================================
log "Starting Docker service..."
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# ==============================================================================
# Format and Mount Data Volume
# ==============================================================================
log "Formatting data volume if not already formatted..."
if ! file -s /dev/nvme1n1 | grep -q "ext4"; then
    mkfs.ext4 -F /dev/nvme1n1
fi

log "Creating mount point and mounting data volume..."
mkdir -p /var/jenkins_data
mount /dev/nvme1n1 /var/jenkins_data
echo '/dev/nvme1n1 /var/jenkins_data ext4 defaults,nofail 0 2' >> /etc/fstab

# ==============================================================================
# Install and Configure CloudWatch Agent
# Commit: chore(monitoring): Install CloudWatch agent for metrics collection
# ==============================================================================
log "Installing CloudWatch agent..."
cd /tmp

# Download CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

# Install CloudWatch agent
dpkg -i -E amazon-cloudwatch-agent.deb

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "agent": {
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent", "inodes_free"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent", "mem_available_percent", "mem_total"],
        "metrics_collection_interval": 60
      },
      "diskio": {
        "measurement": ["write_bytes", "read_bytes", "write_count", "read_count"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  },
  "logs": {
    "log_stream_name": "jenkins-server",
    "log_group_name": "/jenkins/jenkins-${environment}/jenkins-server",
    "file_path": "/var/log/jenkins/jenkins.log",
    "datetime_format": "%Y-%m-%d %H:%M:%S"
  }
}
CWCONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

log "CloudWatch agent installed and started"

# ==============================================================================
# Clone Docker Compose from GitHub
# ==============================================================================
log "Cloning docker-compose from GitHub..."
if [ -n "${github_repo_url}" ]; then
    cd /opt
    rm -rf jenkins
    git clone "${github_repo_url}" jenkins
    cd jenkins
else
    log "No GitHub URL provided, creating docker-compose locally..."
    mkdir -p /opt/jenkins
    cat > /opt/jenkins/docker-compose.yml << 'EOF'
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: unless-stopped
    privileged: true
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - /var/jenkins_data:/var/jenkins_home
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
EOF
fi

# ==============================================================================
# Start Jenkins Container
# ==============================================================================
log "Starting Jenkins container..."
cd /opt/jenkins
docker-compose up -d

log "Waiting for Jenkins to initialize..."
for i in {1..30}; do
    if curl -sf http://localhost:8080/login > /dev/null 2>&1; then
        log "Jenkins is ready!"
        break
    fi
    sleep 10
done

log "Jenkins setup complete!"
log "Initial admin password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword