variable "location" {
  description = "The location for this application deployment"
}

variable "app_name" {
  description = "The root name for this application deployment"
}

variable "tags" {
  description = "The tags for this application deployment"
  type        = string
}

variable "commit_version" {
  description = "The commit version for this application deployment"
}

variable "custom_domain" {
  description = "The custom domain for this application deployment"
}

variable "ingress_domain_name" {
  description = "The domain name for API ingress controller"
  default = null
}

variable "deploy_utils" {
  description = "Whether to deploy the utils container"
  default     = false
}

variable "use_cache" {
  description = "Whether to use Redis cache"
  default     = true
}

variable "authorized_ip_ranges" {
  description = "The IP ranges that are allowed to access the Azure resources"
}