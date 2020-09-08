variable "application_name" {
  description = "Unique Name for this deployment "
  type        = string 
  default     = "gawwaslc"
}

variable "locations" {  
  description = "Azure regions to deploy this application"
  type        = list(string)  
  default     = ["eastus2", "ukwest"]
}

variable "cosmosdb_name" {
  description = "Cosmosdb"
  type        = string
  default     = "dbgawwaslc001"
}

variable "cosmosdb_database_name" {
  description = "Cosmosdb"
  type        = string
  default     = "AesKeys"
}

variable "cosmosdb_collections_name" {
  description = "Cosmosdb"
  type        = string
  default     = "Items"
}

variable "acr_account_name" {
  description = "Azure Container Repository"
  type        = string
  default     = "acrgawwaslc001"
}

variable "ai_account_name" {
  description = "Application Insights"
  type        = string
  default     = "aigawwaslc001"
}

variable "loganalytics_account_name" {
  description = "Log Analytics"
  type        = string
  default     = "logsgawwaslc001"
}