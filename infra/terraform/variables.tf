variable "project_name" {
  description = "Short lowercase name used as a prefix for cloud resources."
  type        = string
  default     = "edgeward"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 3-21 lowercase letters, numbers, or hyphens and start with a letter."
  }
}

variable "gcp_project_id" {
  description = "Google Cloud project ID with billing enabled."
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region. Keep an eligible US region for the e2-micro Free Tier."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Google Cloud zone for the origin VM."
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Compute Engine machine type for the static origin."
  type        = string
  default     = "e2-micro"
}

variable "enable_cloud_nat" {
  description = "Create Cloud NAT so the origin VM has outbound access without a public IP. This has a small cost."
  type        = bool
  default     = true
}

variable "assign_external_ip" {
  description = "Assign an external IP for outbound access. No inbound firewall rule is created and the IP is never put in DNS."
  type        = bool
  default     = false
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the Tunnel."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for domain_name."
  type        = string
}

variable "domain_name" {
  description = "Apex domain already activated on Cloudflare, for example example.com."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$", var.domain_name))
    error_message = "domain_name must be a lowercase fully qualified domain such as example.com."
  }
}

variable "enable_static_site_waf" {
  description = "Create a custom WAF rule that blocks methods other than GET and HEAD for the static site hostnames."
  type        = bool
  default     = true
}

variable "enable_dnssec" {
  description = "Enable Cloudflare DNSSEC. Publish the output DS record at the registrar to complete the chain of trust."
  type        = bool
  default     = false
}

check "origin_has_outbound_path" {
  assert {
    condition     = var.enable_cloud_nat || var.assign_external_ip
    error_message = "Enable Cloud NAT or assign an external IP so cloudflared can connect outbound."
  }
}
