# This example uses a custom built image that includes hosts a simple web server.

resource "google_service_account" "webserver" {
  account_id   = "web-server"
  display_name = "Web Server Service Account"
}

resource "google_compute_instance_template" "webserver" {
  name        = "webserver-template"
  description = "This template is used to create web server instances."

  tags = ["foo", "bar"]

  labels = {
    ansible = "webserver"
  }

  instance_description = "description assigned to instances"
  machine_type         = "e2-small"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image      = "projects/${var.project_id}/global/images/${var.image_name}-${var.commit_hash}"
    auto_delete       = true
    boot              = true
  }

  network_interface {
    network = "default"
  }

  metadata = {
    foo = "bar"
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.webserver.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/"
    port         = "8080"
  }
}

resource "google_compute_instance_group_manager" "webserver" {
  name = "webserver-igm"

  base_instance_name = "web"
  zone               = "us-central1-a"

  version {
    instance_template  = google_compute_instance_template.webserver.id
  }

  target_pools = [google_compute_target_pool.webserver.id]
  target_size  = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}