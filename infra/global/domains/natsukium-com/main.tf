terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    sops = {
      source = "carlpett/sops"
    }
  }

  backend "s3" {
    bucket       = "natsukium-tfstate"
    encrypt      = true
    key          = "global/domains/natsukium-com/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

data "sops_file" "cloudflare-secret" {
  source_file = "secrets.yaml"
}

provider "cloudflare" {
  api_token = data.sops_file.cloudflare-secret.data["api_token"]
}

locals {
  records = {
    blog = {
      content = "natsukium-com.pages.dev"
      name    = "natsukium.com"
      proxied = true
      type    = "CNAME"
    }
    www = {
      content = "natsukium.com"
      name    = "www"
      proxied = true
      type    = "CNAME"
    }
    attic = {
      content = "1af5e046-7d0f-4fa4-9366-69eb490d5119.cfargotunnel.com"
      name    = "cache"
      proxied = true
      type    = "CNAME"
    }
    forgejo = {
      content = "acfc103f-c6b4-4cef-8269-e1985b80e1ac.cfargotunnel.com"
      name    = "git"
      proxied = true
      type    = "CNAME"
    }
    bluesky = {
      content = "\"did=did:plc:wy2g5mzv3k273vqhns2cxnuy\""
      name    = "_atproto"
      proxied = false
      type    = "TXT"
    }
    keyoxide = {
      content = "\"openpgp4fpr:DCCB2D69E06EEAA48904F8A12D5ADD7530F56A42\"" # spellchecker:disable-line
      name    = "natsukium.com"
      proxied = false
      type    = "TXT"
    }
    email = {
      content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
      name    = "natsukium.com"
      proxied = false
      type    = "TXT"
    }
  }
}

resource "cloudflare_dns_record" "record" {
  for_each = local.records
  content  = each.value.content
  name     = each.value.name
  proxied  = each.value.proxied
  ttl      = 1
  type     = each.value.type
  zone_id  = "d318cc678ba046e46f9a7bc69f735764"
}
