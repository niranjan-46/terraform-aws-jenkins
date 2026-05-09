variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "AWS region must be in format: us-east-1"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "jenkins"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "Project name must be lowercase, start with letter, max 20 chars"
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr))
    error_message = "VPC CIDR must be in valid CIDR format"
  }

  validation {
    condition     = var.vpc_cidr == "10.1.0.0/16"
    error_message = "Staging VPC CIDR must be 10.1.0.0/16"
  }
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large", "t3.xlarge"], var.instance_type)
    error_message = "Instance type must be t3.small, t3.medium, t3.large, or t3.xlarge"
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 20 and 100 GB"
  }
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.data_volume_size >= 20 && var.data_volume_size <= 1000
    error_message = "Data volume size must be between 20 and 1000 GB"
  }
}

variable "data_volume_device" {
  description = "Data volume device name"
  type        = string
  default     = "/dev/sdf"
}

variable "github_repo_url" {
  description = "GitHub repository URL for docker-compose"
  type        = string
  default     = ""
}

variable "github_secret_name" {
  description = "AWS Secrets Manager secret name for GitHub credentials"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token (for HTTPS cloning of private repos)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_private_key" {
  description = "Base64 encoded SSH private key (for SSH cloning of private repos)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}