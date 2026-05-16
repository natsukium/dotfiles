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
