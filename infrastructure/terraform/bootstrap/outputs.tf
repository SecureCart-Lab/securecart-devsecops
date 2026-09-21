output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

output "terraform_role_arn" {
  value = aws_iam_role.terraform.arn
}
