variable "location" {
  description = "The location for this application deployment"
}

variable "primary_location" {
  description = "The primary location for this application deployment"
}

variable "app_name" {
  description = "The root name for this application deployment"
}

variable "custom_domain" {
  description = "The custom domain for this application deployment"
}

variable "certificate_file_path" {
  description = "The pfx certificate file name for this application deployment"
}

variable "certificate_password" {
  description = "The pfx certificate password for this application deployment"
}

variable "authorized_ip_ranges" {
    description = "The IP ranges that are allowed to access the Azure resources"
}