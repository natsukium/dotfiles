terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    sops = {
      source = "carlpett/sops"
    }
  }

  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "aws/organization/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

# feature_set "ALL" (not "CONSOLIDATED_BILLING") so SCPs and Identity Center
# can be attached in later stacks.
resource "aws_organizations_organization" "main" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "sso.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
    "account.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# Workloads OU isolates SCP targets from the management account; attaching
# guardrails to the org root risks self-lockout.
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.main.roots[0].id

  lifecycle {
    prevent_destroy = true
  }
}

# close_on_deletion = false: closure is a 90-day irreversible operation
# that should be triggered deliberately via the console, not by terraform.
resource "aws_organizations_account" "research" {
  name              = "research"
  email             = data.sops_file.secrets.data["research_root_email"]
  parent_id         = aws_organizations_organizational_unit.workloads.id
  close_on_deletion = false

  tags = {
    Purpose = "research"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "organization_id" {
  value = aws_organizations_organization.main.id
}

output "workloads_ou_id" {
  value = aws_organizations_organizational_unit.workloads.id
}

output "research_account_id" {
  value = aws_organizations_account.research.id
}
