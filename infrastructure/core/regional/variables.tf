variable "location" {
  description = "The location for this application deployment"
}
variable "primary_location" {
  description = "The primary location for this application deployment"
}

variable "app_name" {
  description = "The root name for this application deployment"
}

variable "tags" {
  description = "The tags for this application deployment"
  type        = string
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

variable "app_insights_connection_string" {
  description = "The Application Insights connection string from the global resources"
}

variable "log_analytics_workspace_id" {
  description = "The Log Analytics Workspace ID from the global resources"
}

variable "cosmosdb_account_id" {
  description = "The CosmosDB Account ID from the global resources"
}