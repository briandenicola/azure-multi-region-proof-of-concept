variable "locations" {
  description = "The location for this application deployment"
  type       = list(string)
  default     = ["southcentralus"]
}

variable custom_domain {
  description = "The custom domain for this application deployment"
}