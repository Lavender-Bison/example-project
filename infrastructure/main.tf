# Define infrastructure for a single two node managed instance group of VMs, load balanced
# using a public HTTP/s load balancer.

resource "google_service_account" "webserver" {
  account_id   = "web-server"
  display_name = "Web Server Service Account"
}

resource "google_compute_instance_template" "webserver" {
  name_prefix = "webserver"
  description = "This template is used to create web server instances."

  # Used for the firewall rule that allows Ansible to SSH into machines.
  tags = ["ansible-ssh"]

  labels = {

    # Labels are used to group instances in the future Ansible postbuild step,
    # so I'll use this to group this machine into a "webserver" group.
    # One could theorhetically have groups like "db" or "microservice-[x]".
    ansible = "webserver"
  }

  instance_description = "Instance responsable for acting as a web server in the example-project."
  machine_type         = "e2-small"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create the instance based on the image passed in that comes from the previous Packer build step.
  disk {
    source_image = "projects/${var.project_id}/global/images/${var.image_name}-${var.commit_hash}"
    auto_delete  = true
    boot         = true
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

  lifecycle {
    create_before_destroy = true
  }

}

# This health check will fail until we run the final postbuild Ansible. This is fine.
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
    instance_template = google_compute_instance_template.webserver.id
  }

  target_size = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}