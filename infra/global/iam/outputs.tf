output "terraform_state_manager_role_arn" {
  description = "ARN of the terraform-state-manager role"
  value       = aws_iam_role.terraform_state_manager.arn
}

output "terraform_state_manager_role_name" {
  description = "Name of the terraform-state-manager role"
  value       = aws_iam_role.terraform_state_manager.name
}

output "terraform_state_access_policy_arn" {
  description = "ARN of the terraform-state-access policy"
  value       = aws_iam_policy.terraform_state_access.arn
}

output "assume_role_command" {
  description = "Command to assume the terraform-state-manager role"
  value       = <<-EOT
    aws sts assume-role \
      --role-arn ${aws_iam_role.terraform_state_manager.arn} \
      --role-session-name terraform-session \
      --serial-number arn:aws:iam::${local.account_id}:mfa/YOUR_MFA_DEVICE \
      --token-code YOUR_MFA_CODE
  EOT
}

output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}