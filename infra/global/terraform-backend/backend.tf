terraform {
  backend "s3" {
    bucket       = "natsukium-tfstate"
    key          = "global/terraform-backend/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true  # S3 native state locking (Terraform >= 1.10)
  }
}