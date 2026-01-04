terraform {
  required_providers {
    hydra = {
      source = "DeterminateSystems/hydra"
    }
    sops = {
      source = "carlpett/sops"
    }
  }

  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "global/services/hydra/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

data "sops_file" "hydra-secret" {
  source_file = "secrets.yaml"
}

provider "hydra" {
  host     = "http://kilimanjaro:3000"
  password = data.sops_file.hydra-secret.data["hydra-password"]
  username = "natsukium"
}

resource "hydra_project" "nixpkgs" {
  name         = "nixpkgs"
  display_name = "nixpkgs"
  homepage     = "https://github.com/NixOS/nixpkgs"
  description  = "Nix Packages collection & NixOS"
  owner        = "natsukium"
  enabled      = true
  visible      = true
}

locals {
  python_jobset = {
    master = {
      name           = "python-master"
      description    = "Python job set for master branch"
      check_interval = 0
      repo           = "https://github.com/NixOS/nixpkgs.git master"
    }
    python-updates = {
      name           = "python-updates"
      description    = "Python job set for python-updates branch"
      check_interval = 10800
      repo           = "https://github.com/NixOS/nixpkgs.git python-updates"
    }
  }
}

resource "hydra_jobset" "nixpkgs" {
  for_each    = local.python_jobset
  project     = hydra_project.nixpkgs.name
  state       = "enabled"
  visible     = true
  name        = each.value.name
  type        = "legacy"
  description = each.value.description

  nix_expression {
    file  = "pkgs/top-level/release-python.nix"
    input = "nixpkgs"
  }

  input {
    name              = "nixpkgs"
    type              = "git"
    value             = each.value.repo
    notify_committers = false
  }

  input {
    name              = "officialRelease"
    type              = "boolean"
    value             = "false"
    notify_committers = false
  }

  input {
    name              = "supportedSystems"
    type              = "nix"
    value             = "[ \"x86_64-linux\" ]"
    notify_committers = false
  }

  check_interval    = each.value.check_interval
  scheduling_shares = 1
  keep_evaluations  = 0

  email_notifications = false
  email_override      = ""
}

resource "hydra_project" "dotfiles" {
  name         = "dotfiles"
  display_name = "dotfiles"
  homepage     = "https://github.com/natsukium/dotfiles"
  description  = "Personal NixOS/Darwin configurations"
  owner        = "natsukium"
  enabled      = true
  visible      = true
}

resource "hydra_jobset" "dotfiles-staging-next" {
  project     = hydra_project.dotfiles.name
  state       = "enabled"
  visible     = true
  name        = "staging-next"
  type        = "flake"
  description = "Daily build with nixpkgs staging-next"

  flake_uri = "github:natsukium/dotfiles/staging-next"

  check_interval    = 43200
  scheduling_shares = 10
  keep_evaluations  = 14

  email_notifications = false
  email_override      = ""
}
