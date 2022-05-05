terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = "~> 3.3"
  }
}

provider "azurerm" {
  features {}
}