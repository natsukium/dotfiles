variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "natsukium-tfstate"
}

variable "enable_logging" {
  description = "Enable S3 access logging for the state bucket"
  type        = bool
  default     = false
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

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "natsukium"
    Project     = var.project
  }
}