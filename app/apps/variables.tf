variable "location" {
  description = "The location for this application deployment"
}

variable "app_name" {
  description = "The root name for this application deployment"
}

variable "commit_version" {
  description = "The commit version for this application deployment"
}

variable "custom_domain" {
  description = "The custom domain for this application deployment"
}

variable "deploy_utils" {
  description = "Whether to deploy the utils container"
  default     = false
}