data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_18:Personal lab state bucket omits access logging to avoid creating and retaining a second log bucket; production should enable centralized access logging.
  #checkov:skip=CKV_AWS_145:Low-cost learning lab uses SSE-S3 AES256; production should evaluate a customer-managed KMS key.
  bucket        = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Project = var.project_name
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "gha_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repository}:environment:lab"]
    }
  }
}

resource "aws_iam_role" "terraform" {
  name               = "${var.project_name}-github-terraform"
  assume_role_policy = data.aws_iam_policy_document.gha_trust.json
}

# Personal-learning-account compromise only. In a production organization,
# replace this with an approved least-privilege provisioning policy and boundary.
resource "aws_iam_role_policy_attachment" "terraform_admin" {
  #checkov:skip=CKV_AWS_274:Personal single-account bootstrap lab only; the trust policy is repository/environment scoped. Replace AdministratorAccess with a least-privilege provisioning policy for production.
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
