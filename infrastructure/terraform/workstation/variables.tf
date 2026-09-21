variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name used for SSH."
}

variable "ssh_cidr" {
  type        = string
  description = "Your current public IPv4 address in /32 CIDR form, for example 203.0.113.10/32."
}

variable "instance_type" {
  type        = string
  default     = "t3a.large"
  description = "Cost-conscious workstation size with enough memory for Docker and SonarQube Community."
}
