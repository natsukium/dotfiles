# Plan (read-only) role.
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
      values = [
        "global/*",
        "services/*",
        "aws/*",
      ]
    }
  }

  statement {
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::natsukium-tfstate/global/*",
      "arn:aws:s3:::natsukium-tfstate/services/*",
      "arn:aws:s3:::natsukium-tfstate/aws/*",
    ]
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

# Broad ReadOnlyAccess (vs per-service read) chosen because read access is
# low-risk and terraform refresh needs Get/List across many services.
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
