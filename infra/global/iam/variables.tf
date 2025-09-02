variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "natsukium-tfstate"
}

variable "allowed_user_ids" {
  description = "List of IAM user IDs allowed to assume the terraform-state-manager role"
  type        = list(string)
  default     = []  # Will be populated with actual user IDs
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "global"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "home-infrastructure"
}