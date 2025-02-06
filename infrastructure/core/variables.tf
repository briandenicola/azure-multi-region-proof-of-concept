variable locations {
  description = "The location for this application deployment"
  type        = list(string)
}

variable "tags" {
  description = "The tags for this application deployment"
  type        = string
}

variable "deploying_externally" {
  description = "Will this deployment be exposed externally?"
  type        = bool
  default     = false
}

variable custom_domain {
  description = "The custom domain for this Container Apps Environment"
}

variable "certificate_file_path" {
  description = "The pfx certificate file name for the Container Apps Environment cert"
}

variable "certificate_password" {
  description = "The pfx certificate password for the Container Apps Environment cert"
}