variable locations {
  description = "The location for this application deployment"
  type        = list(string)
  default     = ["eastus2","westus3"]
}

variable "app_name" {
  description = "The root name for this application deployment"
}

variable commit_version {
  description = "The commit version for this application deployment"
}

variable custom_domain {
  description = "The custom domain for this application deployment"
}