resource "cloudflare_zero_trust_tunnel_cloudflared" "origin" {
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-gcp-origin"
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "origin" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.origin.id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "origin" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.origin.id

  config = {
    ingress = [
      {
        hostname = var.domain_name
        service  = "http://localhost:8080"
      },
      {
        hostname = "www.${var.domain_name}"
        service  = "http://localhost:8080"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

resource "cloudflare_dns_record" "apex" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  content = "${cloudflare_zero_trust_tunnel_cloudflared.origin.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Managed by Terraform; routes the apex through Cloudflare Tunnel."
}

resource "cloudflare_dns_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www.${var.domain_name}"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.origin.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Managed by Terraform; routes www through Cloudflare Tunnel."
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "brotli" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "brotli"
  value      = "on"
}

resource "cloudflare_zone_setting" "minimum_tls" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "tls_1_3" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

resource "cloudflare_ruleset" "static_site_methods" {
  count = var.enable_static_site_waf ? 1 : 0

  zone_id     = var.cloudflare_zone_id
  name        = "${var.project_name} static-site methods"
  description = "Blocks write methods until the static site intentionally adds an API or form."
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    {
      action      = "block"
      description = "Allow only GET and HEAD on the portfolio hostnames"
      enabled     = true
      expression  = "(http.host in {\"${var.domain_name}\" \"www.${var.domain_name}\"} and not http.request.method in {\"GET\" \"HEAD\"})"
      ref         = "block_non_read_methods"
    }
  ]
}

resource "cloudflare_zone_dnssec" "origin" {
  count = var.enable_dnssec ? 1 : 0

  zone_id = var.cloudflare_zone_id
  status  = "active"
}
