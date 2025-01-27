# Introduction
A very simple Multi-Region design for an application following Command Query Responsibility Separation (CQRS) principles in Azure.
In other words, the world's most expensive random number generator....

![Architecture](./.assets/architecture.png)

# Prerequisite
* PowerShell
* Azure Cli
* Azure Static Webapp cli
* Terraform
* A public domain that you can create DNS records
   * Will use bjd.demo for this documentation 
* Certificates
   * Follow this [link](./letsencrypt.md) for required certificates 

## Public DNS Records: 

# Setup

## Infrastructure
## Application Build  
## Application Deployment 
## Manual Steps

# External Access
## Infrastructure
## UI Deployment 
## Manual Steps

# Testing

# Backlog
- [] Moved to Taskfile for deployments instead of script
- [] Coe updates to Managed Identities
- [] General rev updates of TF resources
- [] Move ARM templates to bicep or Terraform
- [] Better naming standards
- [] Moved to Managed Redis instead of Azure Cache for Redis
- [] Adopt new APIM v2 features and platform
- [] Review AppGateway and Front Door configurations
- [] Code Updates for code and all modules to C# 9.0, Go 1.24, and Node 14
- [] Gracefully handle issues on startup
- [] Update documentations 
