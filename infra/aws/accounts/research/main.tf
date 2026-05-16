terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "aws/accounts/research/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

# Account ID is plaintext per repo convention (it's already in the
# organization stack outputs). Hardcoding it lets the provider config
# resolve at init without needing a data source.
locals {
  research_account_id = "907199504666"
}

# Provider assumes the admin role AWS Organizations auto-creates in the
# member account. Both apply_role and plan_role have sts:AssumeRole on
# this target via OIDC stack policies.
provider "aws" {
  region = "ap-northeast-1"

  assume_role {
    role_arn = "arn:aws:iam::${local.research_account_id}:role/OrganizationAccountAccessRole"
  }
}

# Bucket name carries the owning account ID as prefix for global
# uniqueness without relying on a user-handle namespace.
resource "aws_s3_bucket" "experiments" {
  bucket = "${local.research_account_id}-experiments"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "experiments" {
  bucket = aws_s3_bucket.experiments.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "experiments" {
  bucket                  = aws_s3_bucket.experiments.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "experiments" {
  bucket = aws_s3_bucket.experiments.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "experiments_bucket" {
  value = aws_s3_bucket.experiments.id
}
