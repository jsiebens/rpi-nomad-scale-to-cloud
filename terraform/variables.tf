variable "stack_name" {
  description = "The name to prefix onto resources."
  type        = string
  default     = "hashistack"
}

variable "region" {
  description = "The AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "The AWS region AZs to deploy into."
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "instance_type" {
  description = "The EC2 instance type to launch for Nomad clients."
  type        = string
  default     = "t3.small"
}

variable "retry_join" {
  description = "The retry join configuration to use."
  type        = string
}

variable "tailscale_auth_key" {
  type = string
}