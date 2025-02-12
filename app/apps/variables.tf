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

variable "ingress_domain_name" {
  description = "The domain name for API ingress controller"
  default     = "api.ingress.${var.custom_domain}"
}

variable "deploy_utils" {
  description = "Whether to deploy the utils container"
  default     = false
}

variable "use_cache" {
  description = "Whether to use Redis cache"
  default     = true
}