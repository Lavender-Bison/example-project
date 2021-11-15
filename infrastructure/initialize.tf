terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.79.0"
    }
  }

  backend "gcs" {
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}