provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "natsukium-tfstate"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.terraform_state.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

terraform {
  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "global/state/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}
