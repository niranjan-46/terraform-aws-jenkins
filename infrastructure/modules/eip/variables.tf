variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}