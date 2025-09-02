resource "aws_iam_role" "terraform_state_manager" {
  name                 = "terraform-state-manager"
  path                 = "/service-roles/"
  max_session_duration = 14400 # 4 hours
  description          = "Role for managing Terraform state in S3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeRoleWithMFA"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.account_id}:root" # Allow any user in the account with proper conditions
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          StringEquals = {
            "aws:userid" = var.allowed_user_ids # Restrict to specific user IDs
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "terraform-state-manager"
      Purpose     = "Terraform state management"
      MinimalRole = "true"
    }
  )
}

