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

# Create CloudWatch agent configuration with Jenkins-specific metrics
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
        "resources": ["*", "/var/jenkins_data"]
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
# Setup Git Authentication for Private Repositories
# Supports GitHub token, SSH key, and AWS Secrets Manager
# ==============================================================================
log "Setting up Git authentication for private repositories..."

if [ -n "${github_secret_name}" ]; then
    log "🔐 Fetching GitHub secret from AWS Secrets Manager..."
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "${github_secret_name}" --query SecretString --output text)
    github_token=$(echo "${SECRET_JSON}" | jq -r '.github_token // empty')
    ssh_private_key=$(echo "${SECRET_JSON}" | jq -r '.ssh_private_key // empty')

    if [ -n "${github_token}" ]; then
        log "✅ GitHub token retrieved from Secrets Manager"
    fi
    if [ -n "${ssh_private_key}" ]; then
        log "✅ SSH private key retrieved from Secrets Manager"
    fi
fi

# Method 1: GitHub Personal Access Token (HTTPS)
if [ -n "${github_token}" ]; then
    log "🔑 Configuring GitHub token authentication..."
    git config --global credential.helper store
    echo "https://${github_token}:x-oauth-basic@github.com" > ~/.git-credentials
    log "✅ GitHub token configured for HTTPS authentication"

# Method 2: SSH Private Key
elif [ -n "${ssh_private_key}" ]; then
    log "🔐 Setting up SSH key authentication..."
    mkdir -p ~/.ssh
    echo "${ssh_private_key}" | base64 -d > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts
    git config --global core.sshCommand "ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes"
    log "✅ SSH key configured for Git authentication"

else
    log "⚠️  No authentication provided - repository must be public"
    log "   For private repos, set 'github_token', 'ssh_private_key', or 'github_secret_name'"
fi

# ==============================================================================
# Clone Docker Compose from GitHub
# Now supports both public and private repositories
# ==============================================================================
log "Cloning docker-compose from GitHub..."
if [ -n "${github_repo_url}" ]; then
    cd /opt
    rm -rf jenkins

    log "📥 Executing: git clone ${github_repo_url}"
    if git clone "${github_repo_url}" jenkins; then
        log "✅ Repository cloned successfully"
        cd jenkins
    else
        log "❌ Git clone failed - check authentication and repository URL"
        log "   Repository URL: ${github_repo_url}"
        exit 1
    fi
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
    if curl -sf http://localhost:8080/jenkins/login > /dev/null 2>&1; then  # FIXED: Added /jenkins prefix
        log "Jenkins is ready!"
        break
    fi
    sleep 10
done

# ==============================================================================
# Install Essential Jenkins Plugins (Post-Deployment)
# Commit: feat(jenkins): Install essential plugins for better functionality
# ==============================================================================
log "Installing essential Jenkins plugins..."
docker exec jenkins jenkins-plugin-cli --plugins \
  git:5.0.0 \
  workflow-aggregator:596.v8c21c96320e0 \
  credentials-binding:523.vd859a_4b_122e6 \
  timestamper:1.25 \
  cloudbees-folder:6.815.v0dd5a_cb_40e0a_ \
  antisamy-markup-formatter:162.v0e6ec0fcfcf6 \
  pam-auth:1.10 \
  matrix-auth:3.1.5 \
  email-ext:2.102 \
  mailer:463.vedf8358e006b_ \
  prometheus:2.2.1 \
  docker-workflow:563.vd5d2e5c4007f \
  docker-plugin:1.4

# ==============================================================================
# Create Jenkins Configuration as Code (JCasC) Setup
# Commit: feat(jenkins): Configure Jenkins with JCasC for better automation
# ==============================================================================
log "Setting up Jenkins Configuration as Code..."
mkdir -p /var/jenkins_data/casc_configs

# Create basic JCasC configuration
cat > /var/jenkins_data/casc_configs/jenkins.yaml << 'EOF'
jenkins:
  systemMessage: "Jenkins Server - Managed by Terraform"
  numExecutors: 2
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "${ADMIN_PASSWORD}"
  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"
  crumbIssuer:
    standard:
      excludeClientIPFromCrumb: false
  slaveAgentPort: 50000
unclassified:
  location:
    url: "http://localhost:8080/jenkins/"
  mailer:
    smtpHost: "localhost"
    adminAddress: "admin@yourcompany.com"
EOF

log "Jenkins setup complete!"
log "Access Jenkins at: http://<ELASTIC-IP>:8080/jenkins"
log "Initial admin password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword