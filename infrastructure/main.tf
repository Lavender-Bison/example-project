resource "google_service_account" "webserver" {
  account_id   = "web-server"
  display_name = "Web Server Service Account"
}

resource "google_compute_instance" "webserver_1" {
  name        = "webserver-1-${var.commit_hash}"
  description = "Simple webserver that hosts a static website with Nginx."
  zone        = "us-central1-a"

  # Used for the firewall rule that allows Ansible to SSH into machines.
  tags = ["ansible-ssh", "web-server"]

  labels = {

    # Labels are used to group instances in the future Ansible postbuild step,
    # so I'll use this to group this machine into a "webserver" group.
    # One could theorhetically have groups like "db" or "microservice-[x]".
    ansible = "webserver"
  }

  machine_type = "e2-small"

  # Needed so Terraform can replace the machine.
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {

      // Create the instance based on the image passed in that comes from the previous Packer build step.
      image = "projects/${var.project_id}/global/images/${var.image_name}-${var.commit_hash}"
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    # External IP just because I don't have a private network for this demo.
    access_config {
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.webserver.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

}

resource "google_compute_instance" "webserver_2" {
  name        = "webserver-2-${var.commit_hash}"
  description = "Simple webserver that hosts a static website with Nginx."
  zone        = "us-central1-a"

  # Used for the firewall rule that allows Ansible to SSH into machines.
  tags = ["ansible-ssh", "web-server"]

  labels = {

    # Labels are used to group instances in the future Ansible postbuild step,
    # so I'll use this to group this machine into a "webserver" group.
    # One could theorhetically have groups like "db" or "microservice-[x]".
    ansible = "webserver"
  }

  machine_type = "e2-small"

  # Needed so Terraform can replace the machine.
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {

      // Create the instance based on the image passed in that comes from the previous Packer build step.
      image = "projects/${var.project_id}/global/images/${var.image_name}-${var.commit_hash}"
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    # External IP just because I don't have a private network for this demo.
    access_config {
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.webserver.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

resource "google_compute_instance_group" "webservers_instance_group" {
  name        = "webservers"
  description = "The group of Nginx webservers."

  instances = [
    google_compute_instance.webserver_1.self_link,
    google_compute_instance.webserver_2.self_link,
  ]

  named_port {
    name = "http"
    port = 80
  }

  zone = "us-central1-a"

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    create = "20m"
    delete = "20m"
    update = "20m"
  }
}

resource "google_compute_global_address" "example" {
  name    = "example"
  project = var.project_id
}

resource "google_compute_managed_ssl_certificate" "example" {
  name    = "example"
  project = var.project_id
  managed {
    domains = [var.dns_name]
  }
}

resource "google_compute_health_check" "example" {
  name = "example"

  timeout_sec        = 1
  check_interval_sec = 1

  http_health_check {
    port = "80"
  }
}

resource "google_compute_backend_service" "example" {
  name        = "example"
  project     = var.project_id
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30
  enable_cdn  = true
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    client_ttl                   = 7200
    max_ttl                      = 10800
    negative_caching             = true
    signed_url_cache_max_age_sec = 7200
  }

  health_checks = [
    google_compute_health_check.example.id
  ]

  backend {
    group = google_compute_instance_group.webservers_instance_group.id
  }
}

resource "google_compute_url_map" "example" {
  name            = "example"
  project         = var.project_id
  default_service = google_compute_backend_service.example.id
}

resource "google_compute_target_https_proxy" "example" {
  name    = "example"
  project = var.project_id
  url_map = google_compute_url_map.example.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.example.id
  ]
}

resource "google_compute_global_forwarding_rule" "example" {
  name       = "example"
  project    = var.project_id
  target     = google_compute_target_https_proxy.example.id
  port_range = "443"
  ip_address = google_compute_global_address.example.address
}
