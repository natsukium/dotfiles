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
  cloudflare_account_id = "dd87ce894022aec81eacd8ff1948438e"
  zone_id               = "d318cc678ba046e46f9a7bc69f735764"
  records = {
    dotfiles = {
      content = "natsukium.github.io"
      name    = "dotfiles.natsukium.com"
      proxied = true
      type    = "CNAME"
    }
    attic = {
      content = "1af5e046-7d0f-4fa4-9366-69eb490d5119.cfargotunnel.com"
      name    = "cache.natsukium.com"
      proxied = true
      type    = "CNAME"
    }
    niks3 = {
      # write path: presigned-URL minting only. Reads go to nix-cache via R2.
      content = "acfc103f-c6b4-4cef-8269-e1985b80e1ac.cfargotunnel.com"
      name    = "niks3.natsukium.com"
      proxied = true
      type    = "CNAME"
    }
    forgejo = {
      content = "acfc103f-c6b4-4cef-8269-e1985b80e1ac.cfargotunnel.com"
      name    = "git.natsukium.com"
      proxied = true
      type    = "CNAME"
    }
    matrix = {
      # cloudflared origin for the homeserver itself; clients and federation
      # are pointed here by the apex Worker below, not directly via DNS.
      content = "acfc103f-c6b4-4cef-8269-e1985b80e1ac.cfargotunnel.com"
      name    = "matrix.natsukium.com"
      proxied = true
      type    = "CNAME"
    }
    bluesky = {
      content = "\"did=did:plc:wy2g5mzv3k273vqhns2cxnuy\""
      name    = "_atproto.natsukium.com"
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
  zone_id  = local.zone_id
}

# apex delegation for Matrix discovery.
# server_name = natsukium.com lets us use @user:natsukium.com mxids.
resource "cloudflare_workers_script" "matrix_well_known" {
  account_id  = local.cloudflare_account_id
  script_name = "matrix-well-known"
  content     = file("${path.module}/matrix-well-known.js")
  main_module = "matrix-well-known.js"
}

resource "cloudflare_workers_route" "matrix_well_known" {
  zone_id = local.zone_id
  pattern = "natsukium.com/.well-known/matrix/*"
  script  = cloudflare_workers_script.matrix_well_known.script_name
}

# Per-commit tree, blame and history pages form an unbounded URL space that
# Forgejo cannot cache. A scraper spread over residential proxies walks it at
# one or two requests per IP, so IP-based blocking misses it.
# Logged-in users are not exempted: a session-cookie check is trivially forged,
# and a solved challenge is remembered for the challenge passage window anyway.
resource "cloudflare_ruleset" "zone_custom_firewall" {
  zone_id = local.zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [
    {
      description = "Challenge per-commit Forgejo pages"
      action      = "managed_challenge"
      enabled     = true
      expression = join(" ", [
        "http.host eq \"git.natsukium.com\" and (",
        "http.request.uri.path contains \"/src/commit/\"",
        "or http.request.uri.path contains \"/blame/commit/\"",
        "or http.request.uri.path contains \"/commits/commit/\"",
        "or http.request.uri.path contains \"/raw/commit/\"",
        ")",
      ])
    },
  ]
}

# Separate from the Attic bucket: niks3's standard binary-cache layout is
# incompatible with Attic's chunked store.
resource "cloudflare_r2_bucket" "nix_cache_niks3" {
  account_id = local.cloudflare_account_id
  name       = "nix-cache-niks3"
}

resource "cloudflare_r2_bucket" "restic_backup" {
  account_id = local.cloudflare_account_id
  name       = "restic-backup"
}

# Public read path: clients pull straight from R2 (CDN-cached), bypassing the
# tunnel. Cloudflare manages this DNS record itself, hence not in local.records.
resource "cloudflare_r2_custom_domain" "nix_cache_niks3" {
  account_id  = local.cloudflare_account_id
  zone_id     = local.zone_id
  bucket_name = cloudflare_r2_bucket.nix_cache_niks3.name
  domain      = "nix-cache.natsukium.com"
  enabled     = true
  min_tls     = "1.2"
}
