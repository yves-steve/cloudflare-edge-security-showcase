output "site_urls" {
  description = "Public site URLs served through Cloudflare."
  value = [
    "https://${var.domain_name}",
    "https://www.${var.domain_name}"
  ]
}

output "tunnel_id" {
  description = "Cloudflare Tunnel identifier."
  value       = cloudflare_zero_trust_tunnel_cloudflared.origin.id
}

output "origin_private_ip" {
  description = "Private address of the GCP origin."
  value       = google_compute_instance.origin.network_interface[0].network_ip
}

output "origin_external_ip" {
  description = "External origin address in low-cost mode, or null in the secure default mode. Never publish this in DNS."
  value       = try(google_compute_instance.origin.network_interface[0].access_config[0].nat_ip, null)
}

output "dnssec_ds_record" {
  description = "When DNSSEC is enabled, publish this DS record at the registrar."
  value       = try(cloudflare_zone_dnssec.origin[0].ds, null)
}
