variable "locations" {
  description = "The location for this application deployment"
}

variable "app_name" {
  description = "The root name for this application deployment"
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

variable "authorized_ip_ranges" {
    description = "The IP ranges that are allowed to access the Azure resources"
}