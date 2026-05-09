# ==============================================================================
# Module: Compute
# Purpose: Creates EC2 instance, EBS volumes, IAM roles, and user data scripts
# Commit: feat(compute): Provision Jenkins EC2 with IAM role and EBS volumes
# ==============================================================================

# ------------------------------------------------------------------------------
# AMI Data Source
# Fetches latest Ubuntu 22.04 LTS AMI from AWS Marketplace
# Commit: chore(compute): Use latest Ubuntu 22.04 LTS AMI
# ------------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ------------------------------------------------------------------------------
# User Data Template
# Cloud-init script for instance initialization and Jenkins deployment
# Commit: chore(compute): Configure user data for Docker and Jenkins setup
# ------------------------------------------------------------------------------
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh.tpl")

  vars = {
    github_repo_url = var.github_repo_url
    docker_volume   = var.data_volume_device
  }
}

# ------------------------------------------------------------------------------
# IAM Role for EC2
# Provides SSM and CloudWatch permissions to Jenkins instance
# Commit: feat(compute): Create IAM role with SSM and CloudWatch policies
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: SSM Core
# Enables Systems Manager session manager for secure shell access
# Commit: feat(compute): Attach SSM managed instance core policy
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: CloudWatch Agent
# Enables CloudWatch monitoring and logging
# Commit: feat(compute): Attach CloudWatch agent server policy
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ------------------------------------------------------------------------------
# IAM Instance Profile
# Allows EC2 instance to assume IAM role
# Commit: feat(compute): Create IAM instance profile for EC2
# ------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-profile"
  role = aws_iam_role.ec2_role.name

  tags = var.tags
}

# ------------------------------------------------------------------------------
# EC2 Instance: Jenkins Server
# Provisions t3.medium instance with Jenkins and Docker
# Commit: feat(compute): Launch Jenkins EC2 instance with proper configuration
# ------------------------------------------------------------------------------
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name != "" ? var.key_name : null
  iam_instance_profile       = aws_iam_instance_profile.ec2_profile.name
  user_data                   = data.template_file.user_data.rendered
  associate_public_ip_address = true
  ebs_optimized               = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint      = "enabled"
    http_tokens        = "required"
    instance_metadata_tags = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins"
  })
}

# ------------------------------------------------------------------------------
# KMS Key for EBS Encryption
# Creates customer managed key for data volume encryption
# Commit: feat(compute): Create KMS key for EBS data volume encryption
# ------------------------------------------------------------------------------
resource "aws_kms_key" "ebs" {
  description             = "KMS key for Jenkins data volume"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

# ------------------------------------------------------------------------------
# KMS Key Alias
# Friendly name for the KMS key
# Commit: feat(compute): Create alias for EBS encryption KMS key
# ------------------------------------------------------------------------------
resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# ------------------------------------------------------------------------------
# Data EBS Volume: Jenkins Home
# Persistent storage for Jenkins data and configurations
# Commit: feat(compute): Create KMS-encrypted EBS volume for Jenkins data
# ------------------------------------------------------------------------------
resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins-data"
  })
}

# ------------------------------------------------------------------------------
# EBS Volume Attachment
# Attaches data volume to EC2 instance for Jenkins home directory
# Commit: feat(compute): Attach data volume to Jenkins instance
# ------------------------------------------------------------------------------
resource "aws_volume_attachment" "data" {
  device_name = var.data_volume_device
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.jenkins.id
  force_detach = true
}