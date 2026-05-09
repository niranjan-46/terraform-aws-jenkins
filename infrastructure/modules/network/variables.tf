variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}