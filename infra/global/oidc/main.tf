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

# --- Plan (read-only) role ---
# Assumable from PRs and main branch pushes, with read-only S3 access.
# terraform plan runs with -lock=false so no PutObject is needed.

data "aws_iam_policy_document" "plan_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = local.aud_condition.test
      variable = local.aud_condition.variable
      values   = local.aud_condition.values
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:natsukium/dotfiles:ref:refs/heads/main",
        "repo:natsukium/dotfiles:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "github-actions-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_assume.json
}

data "aws_iam_policy_document" "tfstate_read" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::natsukium-tfstate"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["global/*"]
    }
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::natsukium-tfstate/global/*"]
  }
}

resource "aws_iam_policy" "tfstate_read" {
  name   = "tfstate-read"
  policy = data.aws_iam_policy_document.tfstate_read.json
}

resource "aws_iam_role_policy_attachment" "plan_tfstate" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.tfstate_read.arn
}

# --- Apply (write) role ---
# Assumable only from main branch, with read/write S3 access for state management.

data "aws_iam_policy_document" "apply_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = local.aud_condition.test
      variable = local.aud_condition.variable
      values   = local.aud_condition.values
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:natsukium/dotfiles:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name               = "github-actions-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_assume.json
}

data "aws_iam_policy_document" "tfstate_write" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::natsukium-tfstate"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["global/*"]
    }
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::natsukium-tfstate/global/*"]
  }
}

resource "aws_iam_policy" "tfstate_write" {
  name   = "tfstate-write"
  policy = data.aws_iam_policy_document.tfstate_write.json
}

resource "aws_iam_role_policy_attachment" "apply_tfstate" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.tfstate_write.arn
}

output "plan_role_arn" {
  value = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  value = aws_iam_role.apply.arn
}
