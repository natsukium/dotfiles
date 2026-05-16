provider "aws" {
  region = "us-east-2"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "global/oidc/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

# AWS still requires thumbprint_list to be non-empty in the provider schema,
# but it no longer validates thumbprints for GitHub's OIDC IdP (since 2023-07).
# Using a placeholder value as recommended by the community.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  aud_condition = {
    test     = "StringEquals"
    variable = "token.actions.githubusercontent.com:aud"
    values   = ["sts.amazonaws.com"]
  }
}

output "plan_role_arn" {
  value = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  value = aws_iam_role.apply.arn
}
