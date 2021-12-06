# Define infrastructure for a single two node managed instance group of VMs, load balanced
# using a public HTTP/s load balancer.

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

  lifecycle {
    create_before_destroy = false
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
}
