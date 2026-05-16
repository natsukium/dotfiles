# SCPs attach to the Workloads OU, which contains member accounts only.
# The management account is intentionally outside the OU so guardrails
# cannot lock out org-level admin operations.

# Region restriction: deny API calls outside ap-northeast-1 except for
# global services (no region) or services anchored to specific regions
# regardless of caller location.
data "aws_iam_policy_document" "scp_region_restriction" {
  statement {
    effect = "Deny"
    not_actions = [
      "iam:*",
      "organizations:*",
      "account:*",
      "support:*",
      "sts:*",
      "cloudfront:*",
      "route53:*",
      "route53domains:*",
      "waf:*",
      "wafv2:*",
      "shield:*",
      "globalaccelerator:*",
      "tag:*",
      "aws-portal:*",
      "budgets:*",
      "ce:*",
      "cur:*",
      "savingsplans:*",
      "trustedadvisor:*",
      "health:*",
    ]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-1"]
    }
  }
}

resource "aws_organizations_policy" "region_restriction" {
  name        = "region-restriction"
  description = "Deny API calls outside ap-northeast-1 except for global services."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_region_restriction.json
}

resource "aws_organizations_policy_attachment" "region_restriction_workloads" {
  policy_id = aws_organizations_policy.region_restriction.id
  target_id = data.terraform_remote_state.organization.outputs.workloads_ou_id
}

# Enforce SSO: deny creation of IAM users and any credentials that bypass
# Identity Center. aws_identitystore_user resources go through the
# Identity Center API and are unaffected.
data "aws_iam_policy_document" "scp_deny_iam_users" {
  statement {
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "deny_iam_users" {
  name        = "deny-iam-users"
  description = "Deny creation of IAM users, access keys, and console login profiles to enforce SSO-only identity."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_deny_iam_users.json
}

resource "aws_organizations_policy_attachment" "deny_iam_users_workloads" {
  policy_id = aws_organizations_policy.deny_iam_users.id
  target_id = data.terraform_remote_state.organization.outputs.workloads_ou_id
}

# Protect the audit trail: deny actions that would let a member account
# disable or tamper with CloudTrail. SCPs do not apply to service-linked
# roles, so CloudTrail's own log delivery continues to work.
data "aws_iam_policy_document" "scp_protect_cloudtrail" {
  statement {
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_cloudtrail" {
  name        = "protect-cloudtrail"
  description = "Deny actions that would disable or tamper with CloudTrail."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_protect_cloudtrail.json
}

resource "aws_organizations_policy_attachment" "protect_cloudtrail_workloads" {
  policy_id = aws_organizations_policy.protect_cloudtrail.id
  target_id = data.terraform_remote_state.organization.outputs.workloads_ou_id
}
