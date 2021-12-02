variable "org_id" {
  type        = string
  description = "The organization ID for this Terraform workspace."
}

variable "project_id" {
  type        = string
  description = "The project ID for this Terraform workspace."
}

# Information for the image built in the previous Packer step is passed in
# as part of the Github Workflow using the Terraform `-var` argument.
variable "image_name" {
  type = string
}

# Unfortunately, images are rebuilt on every commit. This can be improved, but
# I'm limited by time.
variable "commit_hash" {
  type = string
}

variable "subnetwork" {
  type = string
}
