terraform {
  required_version = ">= 1.10.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
  
  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "terraform_state_logging" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.log_bucket[0].id
  target_prefix = "terraform-state-logs/"
}

resource "aws_s3_bucket" "log_bucket" {
  count = var.enable_logging ? 1 : 0

  bucket = "${var.state_bucket_name}-logs"

  lifecycle {
    prevent_destroy = true
  }
  
  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.log_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}