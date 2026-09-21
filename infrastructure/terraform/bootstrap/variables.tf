variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "securecart"
}

variable "github_owner" {
  type        = string
  description = "GitHub user or organization that owns the engineering repository."
}

variable "github_repository" {
  type    = string
  default = "securecart-devsecops"
}
