# Apply (write) role.
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
      values = [
        "global/*",
        "services/*",
        "aws/*",
      ]
    }
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::natsukium-tfstate/global/*",
      "arn:aws:s3:::natsukium-tfstate/services/*",
      "arn:aws:s3:::natsukium-tfstate/aws/*",
    ]
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

# Per-stack managed policies (vs AdministratorAccess) to bound blast radius
# if the OIDC token leaks. New stacks add their own policies here.
resource "aws_iam_role_policy_attachment" "apply_organizations" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"
}

# AWSOrganizationsFullAccess covers iam:CreateServiceLinkedRole only for
# organizations itself; sso/cloudtrail/guardduty SLRs need this extra grant.
data "aws_iam_policy_document" "apply_iam_slr" {
  statement {
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:DeleteServiceLinkedRole",
      "iam:GetServiceLinkedRoleDeletionStatus",
    ]
    resources = ["arn:aws:iam::*:role/aws-service-role/*"]
  }
}

resource "aws_iam_policy" "apply_iam_slr" {
  name   = "apply-iam-service-linked-role"
  policy = data.aws_iam_policy_document.apply_iam_slr.json
}

resource "aws_iam_role_policy_attachment" "apply_iam_slr" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.apply_iam_slr.arn
}

# Identity Center management splits across two AWS-managed policies: the
# master account scope (permission sets, account assignments) and the
# identity store scope (users, groups, memberships). Both are needed for
# the infra/aws/identity-center stack to apply end-to-end.
resource "aws_iam_role_policy_attachment" "apply_sso_master" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator"
}

resource "aws_iam_role_policy_attachment" "apply_sso_directory" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSSODirectoryAdministrator"
}

# AWSSSOMasterAccountAdministrator omits SAML provider management on the
# provider that IdC creates and depends on (AWSSSO_*_DO_NOT_DELETE).
# aws_ssoadmin_account_assignment internally calls Get/Create/Update on
# this provider during assignment lifecycle. Scoped to AWSSSO_* providers
# to avoid touching unrelated SAML configurations.
data "aws_iam_policy_document" "apply_sso_saml" {
  statement {
    actions = [
      "iam:GetSAMLProvider",
      "iam:CreateSAMLProvider",
      "iam:UpdateSAMLProvider",
      "iam:DeleteSAMLProvider",
      "iam:TagSAMLProvider",
      "iam:UntagSAMLProvider",
      "iam:ListSAMLProviderTags",
    ]
    resources = ["arn:aws:iam::*:saml-provider/AWSSSO_*"]
  }
}

resource "aws_iam_policy" "apply_sso_saml" {
  name   = "apply-sso-saml-provider"
  policy = data.aws_iam_policy_document.apply_sso_saml.json
}

resource "aws_iam_role_policy_attachment" "apply_sso_saml" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.apply_sso_saml.arn
}

# Lets apply_role self-update the OIDC stack via CI. ARN patterns bound
# the blast radius — IAM resources outside this stack's naming conventions
# are unreachable. Self-trust edits remain possible; PR review and console
# recovery are the mitigations.
data "aws_iam_policy_document" "apply_iam_oidc" {
  statement {
    actions = [
      "iam:Get*",
      "iam:List*",
      "iam:Create*",
      "iam:Delete*",
      "iam:Update*",
      "iam:Put*",
      "iam:Tag*",
      "iam:Untag*",
      "iam:Attach*",
      "iam:Detach*",
      "iam:AddClient*",
      "iam:RemoveClient*",
      "iam:SetDefault*",
    ]
    resources = [
      "arn:aws:iam::*:role/github-actions-*",
      "arn:aws:iam::*:policy/tfstate-*",
      "arn:aws:iam::*:policy/apply-*",
      "arn:aws:iam::*:oidc-provider/token.actions.githubusercontent.com",
    ]
  }
}

resource "aws_iam_policy" "apply_iam_oidc" {
  name   = "apply-iam-oidc-stack"
  policy = data.aws_iam_policy_document.apply_iam_oidc.json
}

resource "aws_iam_role_policy_attachment" "apply_iam_oidc" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.apply_iam_oidc.arn
}
