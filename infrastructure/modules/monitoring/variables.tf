variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID for monitoring"
  type        = string
}

variable "ebs_volume_id" {
  description = "EBS volume ID for monitoring"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}