# Introduction
A very simple Multi-Region design for an application following Command Query Responsibility Separation (CQRS) principles in Azure.
In other words, the world's most expensive random number generator....

![Architecture](./.assets/architecture.png)

# Prerequisites
* A Posix compliant System. It could be one of the following:
    * [Github CodeSpaces](https://github.com/features/codespaces)
    * Azure Linux VM - Standard_B1s VM will work ($18/month)
    * Windows 11 with [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install)
* [dotnet 8](https://dotnet.microsoft.com/download) - The .NET SDK
* [Visual Studio Code](https://code.visualstudio.com/) or equivalent - A lightweight code editor
* [Docker](https://www.docker.com/products/docker-desktop) - The Docker Desktop to build/push containers
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - A tool for managing Azure resources
* [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) - The PowerShell Core for running scripts
* [git](https://git-scm.com/) - The source control tool
* [Taskfile](https://taskfile.dev/#/) - A task runner for the shell
* [Terraform](https://www.terraform.io/) - A tool for building Azure infrastructure and infrastructure as code
* If exposing application externally then a public domain that you can create DNS records

* [Required Certificates](./docs/letsencrypt.md)

> * **Note:** The documentation will use bjd.demo throughout as the root domain.  This can be replaced with your own domain
> * **Note:** The Github Codespaces environment has all the tools pre-installed and configured.  You can use the following link to open the project in Github Codespaces: [Open in Github Codespaces](https://codespaces.new/briandenicola/azure-multi-region-proof-of-concept?quickstart=1)

## Public DNS Records: 
* The following DNS records are required for the application to work correctly.  These are used for the application to be accessed externally.  The following records are required: 
    Name | Usage | DNS Record Type | IP Address
    ------ | ---- | ---- | ----
    api.bjd.demo | Azure Front Door  |  CNAME | Front Door URL>
    westus.api.bjd.demo | App Gateway | A | App Gateway IP Address in West US
    eastus.api.bjd.demo | App Gateway | A | App Gateway IP Address in East US

## Task
* The deployment of this application has been automated using [Taskfile](https://taskfile.dev/#/).  This was done instead of using a CI/CD pipeline to make it easier to understand the deployment process.  
* Of course, the application can be deployed manually
* The Taskfile is a simple way to run commands and scripts in a consistent manner.  
* The [Taskfile](../Taskfile.yaml) definition is located in the root of the repository
* The Task file declares the default values that can be updated to suit specific requirements: 

    Name | Usage | Location | Required | Default or Example Value
    ------ | ------ | ------ | ------ | ------
    TITLE | Value used in Azure Tags | taskfile.yaml | Yes | CQRS Multi-region Pattern in Azure
    DEFAULT_REGIONS | Default region to deploy to | taskfile.yaml | Yes | ["westus3"]
    DOMAIN_ROOT | Default root domain used for all URLs & certs | taskfile.yaml | Yes | bjd.demo
    EXTERNAL_DEPLOYMENT | Will this deployment deploy external components | taskfile.yaml | Yes | false
    DEPLOYMENT_TYPE | Will this deployment deploy to multiple regions | taskfile.yaml | Yes | single (`multiregion` or `single` are valid options)
    APIM_PFX_CERT_PATH | Path to the APIM PFX certificate | .env | External Only | ./certs/apim.pfx
    APIM_PFX_CERT_PASSWORD | Password for the APIM PFX certificate | .env | External Only | <password for the pfx file>
    APP_GW_PFX_CERT_PATH | Path to the App Gateway PFX certificate | .env | External Only | ./certs/appgw.pfx
    APP_GW_PFX_CERT_PASSWORD | Password for the App Gateway PFX certificate | .env | External Only | <password for the pfx file>
    FRONTDOOR_URL | The Custom URL for the Azure Front Door | .env | External Only | api.bjd.demo
    APP_GW_URLS | The URLs for the App Gateways | .env | External Only | ["westus.api.bjd.demo"] 
    APIM_URLS | The Urls for the APIM Gateways | .env | External Only | ["westus.apim.bjd.demo"]

* Running the `task` command without any options will run the default command. This will list all the available tasks.
    * `task init`               : Initialized Terraform modules
    * `task up`                 : Builds complete environment
    * `task down`               : Destroys all Azure resources and cleans up Terraform
    * `task apply`              : Applies the Terraform configuration for the core components
    * `task external`           : Applies ARM templates for external components
    * `task apim`               : Deploys Azure API Management
    * `task appgw`              : Deploys Azure Application Gateway
    * `task frontdoor`          : Deploys Azure Front Door
    * `task build`              : Builds containers and pushes to Azure Container Registry
    * `task deploy`             : Creates application components and deploy the application code

# Setup

## Infrastructure
> * **Note:** Before starting ensure that  ACA_INGRESS_PFX_CERT_PASSWORD and ACA_INGRESS_PFX_CERT_PATH are set in the .env file at the project root
## Application Build  
## Application Deployment 
## Manual Steps

# External Access
## Infrastructure
> * **Note:** Before starting ensure that the required external values are set in the .env file at the project root

## UI Deployment 
## Manual Steps

# Testing

# Backlog
- [x] Moved to Taskfile for deployments instead of script
- [x] Validate certificates naming standards
- [x] General rev updates of TF resources
- [x] General rev updates of ARM template resources
- [x] Update naming standards
- [x] Moved to Managed Redis instead of Azure Cache for Redis
- [] Code (and modules) updated to latest versions
- [] Event Processor Function Code updated to Managed Identities for Event Hubs, Functions Runtime/Storage and Redis
- [] Change Feed Processor Function Code updated to Managed Identities for Event Hubs, Functions Runtime/Storage 
- [] API updated to Managed Identities for Event Hubs, App Insights and Redis
- [] Gracefully handle connection issues on API startup - non-persistent mode
- [] Review new APIM v2 features and platform for additional updates
- [] Review AppGateway and Front Door configurations for additional updates
- [] Update documentation 
