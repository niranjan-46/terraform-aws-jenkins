variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type - UPGRADED to t3.large for better Jenkins performance"
  type        = string
  default     = "t3.large"  # UPGRADED: Better performance for Jenkins workloads
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
  default     = 50
}

variable "data_volume_device" {
  description = "Data volume device name"
  type        = string
  default     = "/dev/nvme1n1"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub repository URL"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}