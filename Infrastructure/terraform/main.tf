terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = "~> 3.52"
  }
}

provider "azurerm" {
  features {}
}