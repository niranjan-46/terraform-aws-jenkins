# ==============================================================================
# Environment: Dev
# Purpose: Jenkins infrastructure for development environment
# Commit: ci(dev): Configure dev environment Terraform orchestration
# ==============================================================================

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ------------------------------------------------------------------------------
# AWS Provider Configuration
# Configures AWS as the cloud provider with default tags
# Commit: chore(provider): Configure AWS provider with default tags
# ------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# ------------------------------------------------------------------------------
# AWS Caller Identity
# Retrieves current AWS account information for resource tagging
# Commit: chore(aws): Get current AWS account identity
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# Local Values
# Common tags and account ID for consistent resource labeling
# Commit: chore(locals): Define common tags for all resources
# ------------------------------------------------------------------------------
locals {
  account_id = data.aws_caller_identity.current.account_id
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}

# ------------------------------------------------------------------------------
# Module: State Storage
# Creates S3 bucket and DynamoDB table for Terraform state management
# Commit: feat(state): Provision state storage infrastructure
# ------------------------------------------------------------------------------
module "state_storage" {
  source = "../../modules/state"

  environment = var.environment
  project_name = var.project_name

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Module: Network
# Creates VPC, subnets, IGW, NAT Gateway, and route tables
# Commit: feat(network): Provision networking infrastructure
# ------------------------------------------------------------------------------
module "network" {
  source = "../../modules/network"

  environment       = var.environment
  project_name      = var.project_name
  vpc_cidr          = var.vpc_cidr
  availability_zone = var.availability_zone

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Module: Security
# Creates security groups with required ingress/egress rules
# Commit: feat(security): Provision security groups for Jenkins
# ------------------------------------------------------------------------------
module "security" {
  source = "../../modules/security"

  environment         = var.environment
  project_name        = var.project_name
  vpc_id              = module.network.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Module: Jenkins Instance
# Creates EC2 instance with IAM role, EBS volumes, and user data
# Commit: feat(compute): Provision Jenkins EC2 instance
# ------------------------------------------------------------------------------
module "jenkins_instance" {
  source = "../../modules/compute"

  environment          = var.environment
  project_name         = var.project_name
  subnet_id            = module.network.public_subnet_id
  security_group_ids   = [module.security.jenkins_sg_id]
  key_name             = var.key_name
  instance_type        = var.instance_type
  root_volume_size     = var.root_volume_size
  data_volume_size     = var.data_volume_size
  data_volume_device   = var.data_volume_device
  availability_zone    = var.availability_zone
  github_repo_url      = var.github_repo_url

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Module: Elastic IP
# Allocates and associates static public IP with Jenkins instance
# Commit: feat(eip): Provision elastic IP for Jenkins server
# ------------------------------------------------------------------------------
module "elastic_ip" {
  source = "../../modules/eip"

  environment  = var.environment
  project_name = var.project_name
  instance_id  = module.jenkins_instance.instance_id

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Module: Backup
# Creates DLM lifecycle policy for daily EBS snapshots
# Commit: feat(backup): Configure automated backup for Jenkins data
# ------------------------------------------------------------------------------
module "backup" {
  source = "../../modules/backup"

  environment  = var.environment
  project_name = var.project_name
  volume_id    = module.jenkins_instance.data_volume_id

  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# Module: Monitoring
# Creates CloudWatch alarms and monitoring for Jenkins server
# Commit: feat(monitoring): Provision CloudWatch monitoring and alarms
# ------------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  environment    = var.environment
  project_name   = var.project_name
  instance_id    = module.jenkins_instance.instance_id
  ebs_volume_id  = module.jenkins_instance.data_volume_id

  tags = local.common_tags
}