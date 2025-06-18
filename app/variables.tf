variable locations {
  description = "The location for this application deployment"
  type        = list(string)
  default     = ["eastus2","westus3"]
}

variable "app_name" {
  description = "The root name for this application deployment"
}

variable "tags" {
  description = "The tags for this application deployment"
  type        = string
}

variable commit_version {
  description = "The commit version for this application deployment"
}

variable custom_domain {
  description = "The custom domain for this application deployment"
}

variable "use_cache" {
  description = "Whether to use Redis cache"
  default     = true
}

variable "use_jumpbox" {
  description = "Whether to deploy a jumpbox VM in each location"
  default     = true
}