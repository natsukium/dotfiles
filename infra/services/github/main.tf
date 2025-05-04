terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
    sops = {
      source = "carlpett/sops"
    }
  }

  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "global/services/github/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

data "sops_file" "github-token" {
  source_file = "secrets.yaml"
}

provider "github" {
  owner = "natsukium"
  token = data.sops_file.github-token.data["token"]
}

resource "github_user_ssh_key" "default" {
  title = "tomoya.otabi@gmail.com"
  key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPPimMzL7CcpSpmf1QisRFxdp1e/3C21GZsoyDgZvIu"
}

resource "github_user_gpg_key" "default" {
  armored_public_key = file("${path.module}/../../../homes/shared/gpg/keys.txt")
}

