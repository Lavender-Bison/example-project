variable "network_project_id" {
  type = string
}

variable "project_id" {
  type = string
}

variable "service_account" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "zone" {
  type = string
}

variable "image_family" {
  type = string
}

variable "image_name" {
  type = string
}

variable "commit_hash" {
  type = string
}

source "googlecompute" "gce" {
  enable_integrity_monitoring = true
  enable_secure_boot          = true
  enable_vtpm                 = true
  image_description           = "The image for the example-project blog instance."
  image_family                = "${var.image_family}"
  image_name                  = "${var.image_name}-${var.commit_hash}"
  network_project_id          = "${var.network_project_id}"
  omit_external_ip            = false
  project_id                  = "${var.project_id}"
  service_account_email       = "${var.service_account}"
  source_image_family         = "ubuntu-2004-lts"
  ssh_username                = "ubuntu"
  subnetwork                  = "${var.subnetwork}"
  use_iap                     = false
  use_internal_ip             = false
  use_os_login                = true
  zone                        = "${var.zone}"
  tags = [
    "packer-build-machine"
  ]
}

build {
  sources = ["source.googlecompute.gce"]

  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
  }
}
