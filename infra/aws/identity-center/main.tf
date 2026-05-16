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
    key          = "aws/identity-center/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

# IdC is regional and its region was fixed at console enablement to
# ap-northeast-1. The provider region must match for the SSO and
# identitystore APIs to find the instance.
provider "aws" {
  region = "ap-northeast-1"
}

data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

# Identity Center has no Terraform resource for instance creation; the
# instance is enabled manually in the management account console. This
# data source picks it up.
data "aws_ssoadmin_instances" "main" {}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "organization" {
  backend = "s3"
  config = {
    bucket = "natsukium-tfstate"
    key    = "aws/organization/terraform.tfstate"
    region = "us-east-2"
  }
}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

# === Users ===
resource "aws_identitystore_user" "tomoya" {
  identity_store_id = local.identity_store_id

  display_name = "Tomoya Otabi"
  user_name    = "tomoya"

  name {
    given_name  = "Tomoya"
    family_name = "Otabi"
  }

  emails {
    value   = data.sops_file.secrets.data["tomoya_email"]
    primary = true
  }
}

resource "aws_identitystore_user" "hikari" {
  identity_store_id = local.identity_store_id

  display_name = "Hikari Otabi"
  user_name    = "hikari"

  name {
    given_name  = "Hikari"
    family_name = "Otabi"
  }

  emails {
    value   = data.sops_file.secrets.data["hikari_email"]
    primary = true
  }
}

# === Groups ===
resource "aws_identitystore_group" "admins" {
  identity_store_id = local.identity_store_id
  display_name      = "admins"
  description       = "Account administrators across all member accounts."
}

resource "aws_identitystore_group" "members" {
  identity_store_id = local.identity_store_id
  display_name      = "members"
  description       = "Non-admin members of the organization."
}

resource "aws_identitystore_group_membership" "tomoya_admins" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.admins.group_id
  member_id         = aws_identitystore_user.tomoya.user_id
}

resource "aws_identitystore_group_membership" "hikari_members" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.members.group_id
  member_id         = aws_identitystore_user.hikari.user_id
}

# === Permission Sets ===
resource "aws_ssoadmin_permission_set" "administrator_access" {
  instance_arn     = local.instance_arn
  name             = "AdministratorAccess"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_access" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# PowerUserAccess grants full access except IAM and Organizations
# management, preventing members from elevating their own privileges or
# modifying org-level resources.
resource "aws_ssoadmin_permission_set" "power_user_access" {
  instance_arn     = local.instance_arn
  name             = "PowerUserAccess"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "power_user_access" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.power_user_access.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# === Account assignments ===
resource "aws_ssoadmin_account_assignment" "admins_management" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn

  principal_type = "GROUP"
  principal_id   = aws_identitystore_group.admins.group_id

  target_type = "AWS_ACCOUNT"
  target_id   = data.aws_caller_identity.current.account_id
}

resource "aws_ssoadmin_account_assignment" "admins_research" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn

  principal_type = "GROUP"
  principal_id   = aws_identitystore_group.admins.group_id

  target_type = "AWS_ACCOUNT"
  target_id   = data.terraform_remote_state.organization.outputs.research_account_id
}

resource "aws_ssoadmin_account_assignment" "members_research" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.power_user_access.arn

  principal_type = "GROUP"
  principal_id   = aws_identitystore_group.members.group_id

  target_type = "AWS_ACCOUNT"
  target_id   = data.terraform_remote_state.organization.outputs.research_account_id
}

output "sso_instance_arn" {
  value = local.instance_arn
}

output "identity_store_id" {
  value = local.identity_store_id
}
