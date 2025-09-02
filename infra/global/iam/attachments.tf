resource "aws_iam_role_policy_attachment" "terraform_state_manager_s3_access" {
  role       = aws_iam_role.terraform_state_manager.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

resource "aws_iam_role_policy_attachment" "terraform_state_manager_minimal" {
  role       = aws_iam_role.terraform_state_manager.name
  policy_arn = aws_iam_policy.terraform_minimal_permissions.arn
}