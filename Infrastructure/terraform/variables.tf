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

variable "vnet_name" {
  description = "Virtual Network Name"
  type        = string
  default     = "vnetgawwaslc00"
}

variable "eventhub_namespace_name" {
  description = "Event Hub Namespace"
  type        = string
  default     = "hubgawwaslc00"
}

variable "redis_name" {
  description = "Redis Cache"
  type        = string
  default     = "cachegawwaslc00"
}

variable "aks_name" {
  description = "AKS Cluster"
  type        = string
  default     = "k8sgawwaslc00"
}

variable "storage_name" {
  description = "Storage Account"
  type        = string
  default     = "sagawwaslc00"
}

variable "ssh_public_key" {
  description = "SSH Public Key"
  type        = string
  default	  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGUfWYw+OI3udPmdcIklEeLapnR/9boHLNOpHwglZ+fxv959rjmXyq+ZB55xfHQqjYgvUARLbYmvnBgIpDDI95fo2tepHjspvw4nmM1OwRCt+DwY7Y7Rmq/5LRIj6RvJe0V2TsS8xE0VI907zLoatqQ6cO9kedlbr9KY4ZrRXYHOZWapHqcliyI29lZIPGdmAFjmtdkngmu4sgss9V+2gwWghp+bnMXyyn96oBxeQjCNDiP/90yucjYgoDPHslkLXc7jgdfnb+oxa0iG9bHutzgTdQ7ZkCZOnd++ZJISIvKhIIJAfqaQNVY1B7cXzFDcTJbZxpptZvKbaUaWhRS1uJ briandenicola@harpocrates.denicolafamily.com"
}

variable "api_server_authorized_ip_ranges" {
  description = "IP Range for K8S API Access"
  type        = list(string) 
}

variable "custom_domain" {
  description = "Domain Name for application"
  type        = string
}
