variable "org_id" {
  type        = string
  description = "The organization ID for this Terraform workspace."
}

variable "project_id" {
  type        = string
  description = "The project ID for this Terraform workspace."
}

variable "image_name" {
  type = string
}

variable "commit_hash" {
  type = string
}
