terraform {
  backend "s3" {
    bucket       = "natsukium-tfstate"
    key          = "global/iam/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
