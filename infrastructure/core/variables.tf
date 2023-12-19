variable locations {
  description = "The location for this application deployment"
  type        = list(string)
  default     = ["southcentralus", "eastus2"]
}

variable custom_domain {
  description = "The custom domain for this application deployment"
}
