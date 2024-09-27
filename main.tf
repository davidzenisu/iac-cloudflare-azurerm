terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
}

data "cloudflare_zone" "this" {
  for_each = toset(var.zone_name? ["default"] : [])

  name = var.zone_name
}

resource "cloudflare_record" "this" {
  for_each = var.dns_records

  zone_id = one(data.cloudflare_zone.this).id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  proxied = each.value.proxied
}
