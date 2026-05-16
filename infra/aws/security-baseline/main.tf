terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "aws/security-baseline/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "organization" {
  backend = "s3"
  config = {
    bucket = "natsukium-tfstate"
    key    = "aws/organization/terraform.tfstate"
    region = "us-east-2"
  }
}
