variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "securecart"
}

variable "environment" {
  type    = string
  default = "lab"
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
}

variable "github_owner" {
  type = string
}

variable "github_repository" {
  type    = string
  default = "securecart-devsecops"
}

variable "admin_principal_arn" {
  type        = string
  description = "IAM role/user ARN that receives EKS cluster-admin access."
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the EKS public API endpoint. Use /32 for the EC2 workstation."
}
