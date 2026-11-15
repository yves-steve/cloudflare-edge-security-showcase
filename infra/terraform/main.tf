locals {
  labels = {
    application = var.project_name
    managed_by  = "terraform"
    purpose     = "cloudflare-showcase"
  }
}

resource "google_compute_network" "origin" {
  name                    = "${var.project_name}-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "origin" {
  name                     = "${var.project_name}-subnet"
  ip_cidr_range            = "10.42.0.0/24"
  network                  = google_compute_network.origin.id
  region                   = var.gcp_region
  private_ip_google_access = true
}

# Custom VPCs already have an implied deny-ingress rule. This explicit rule keeps
# the security property visible in plans and in the GCP console.
resource "google_compute_firewall" "deny_internet_ingress" {
  name      = "${var.project_name}-deny-internet-ingress"
  network   = google_compute_network.origin.name
  direction = "INGRESS"
  priority  = 1000

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.project_name}-origin"]
}

resource "google_compute_router" "origin" {
  count = var.enable_cloud_nat ? 1 : 0

  name    = "${var.project_name}-router"
  network = google_compute_network.origin.id
  region  = var.gcp_region
}

resource "google_compute_router_nat" "origin" {
  count = var.enable_cloud_nat ? 1 : 0

  name                               = "${var.project_name}-nat"
  router                             = google_compute_router.origin[0].name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

resource "google_compute_instance" "origin" {
  name         = "${var.project_name}-origin"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["${var.project_name}-origin"]
  labels       = local.labels

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.origin.id

    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    block-project-ssh-keys = "true"
    enable-oslogin         = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    cloudflared_image = var.cloudflared_image
    index_html_b64    = base64encode(file("${path.module}/../../site/index.html"))
    nginx_conf_b64    = base64encode(file("${path.module}/../../site/nginx.conf"))
    script_js_b64     = base64encode(file("${path.module}/../../site/script.js"))
    styles_css_b64    = base64encode(file("${path.module}/../../site/styles.css"))
    tunnel_token      = data.cloudflare_zero_trust_tunnel_cloudflared_token.origin.token
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  depends_on = [google_compute_router_nat.origin]
}
