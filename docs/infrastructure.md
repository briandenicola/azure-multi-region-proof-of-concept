Infrastructure
============
* The infrastructure is deployed to Azure using Terraform.  
* The build process is kicked off using the command: `task up` command which kick start terraform.  
* Terraform will generate a random name that is used as the foundation for all the resources created in Azure.  The random name is generated using the `random_pet` and `random_integer` resources in Terraform.  This value should be saved as it is used throughout the deployment. The example name `pipefish-47182` is used in the rest of the documents
* The infrastructure deploy can take up to 30 minutes to complete.
* The infrastructure is deployed to a single or multiple Azure region (defaults to single region `canadacentral`). can be changed by updating the `DEFAULT_REGION` variable in the `Taskfile.yaml` file.
* Before starting, ensure that the values ACA_INGRESS_PFX_CERT_PASSWORD and ACA_INGRESS_PFX_CERT_PATH are set in the .env file at the project root

# Core Infrastructure
## Core Resource Groups
Name | Usage
------ | ----
Global Resource Group ("${app_name}_global_rg") | Components that are shared across all regions
Application Resource Group ("\${app_name}_\${region}_apps_rg") | Application specific components
Regional Infrastructure Resource Group ("\${app_name}_\${region}_infra_rg")| Networking specific components per region
<p align="right">(<a href="#Infrastructure">back to top</a>)</p>

## Core Infrastructure Components
Name | Resource Group | Usage 
------ | ---- | ----
\${app_name}-logs | Global Resource Group | Log Analytics workspace for monitoring
\${app_name}acr | Global Resource Group | Azure Container Registry for container images
\${app_name}-cosmosdb | Global Resource Group | Cosmos DB for document storage
\${app_name}-ai | Global Resource Group | Application Insights for monitoring
\${app_name}\${region}kv | Application Resource Group | Key Vault for secrets
\${app_name}\${region}sa | Application Resource Group | Storage Account for Azure Functions 
\${app_name}-\${region}-eventhub | Application Resource Group | Event Hub for messaging
\${app_name}-\${region}-redis | Regional Infrastructure Resource Group | Redis Cache for caching
\${app_name}-\${region}-bastion | Regional Infrastructure Resource Group | Bastion Host for secure access
\${app_name}-\${region}-env | Regional Infrastructure Resource Group | Container Apps Environment 
\${app_name}-\${region}-vnet | Regional Infrastructure Resource Group | Virtual Network for networking
Private DNS Zone | Regional Infrastructure Resource Group | Private DNS Zone for internal DNS resolution
Private Endpoints | Regional Infrastructure Resource Group | Private Endpoints for secure access

<p align="right">(<a href="#Infrastructure">back to top</a>)</p>

## Core Infrastructure Steps
```bash
➜  git:(main) ✗ task up
task: [init] terraform -chdir=./infrastructure/core workspace new canadacentral || true
Created and switched to workspace "canadacentral"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
task: [init] terraform -chdir=./infrastructure/core workspace select canadacentral
task: [init] terraform -chdir=./infrastructure/core init

Initializing the backend...
Initializing modules...
- global_resources in global
- regional_resources in regional

Initializing provider plugins...
- Finding azure/azapi versions matching "~> 2.0"...
- Finding latest version of hashicorp/random...
- Finding latest version of hashicorp/http...
- Finding hashicorp/azurerm versions matching "~> 4.0"...
- Installing azure/azapi v2.2.0...
...
Plan: 72 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + ACR_NAME            = (known after apply)
  + APP_NAME            = (known after apply)
  + AZURE_STATIC_WEBAPP = ""
random_pet.this: Creating...
random_pet.this: Creation complete after 0s [id=doberman]
random_id.this: Creating...
random_id.this: Creation complete after 0s [id=HB4]
module.global_resources.azurerm_resource_group.cqrs_global: Creating...
module.global_resources.azurerm_resource_group.cqrs_global: Creation complete after 10s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_global_rg]
module.global_resources.azurerm_log_analytics_workspace.cqrs: Creating...
module.global_resources.azurerm_container_registry.cqrs: Creating...
module.global_resources.azurerm_cosmosdb_account.cqrs: Creating...
module.global_resources.azurerm_log_analytics_workspace.cqrs: Still creating... [10s elapsed]
module.global_resources.azurerm_container_registry.cqrs: Still creating... [10s elapsed]
...
azurerm_redis_enterprise_database.cqrs: Still creating... [2m30s elapsed]
azurerm_redis_enterprise_database.cqrs: Still creating... [2m40s elapsed]
azurerm_redis_enterprise_database.cqrs: Creation complete after 2m49s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_infra_rg/providers/Microsoft.Cache/redisEnterprise/pipefish-47182-canadacentral-cache/databases/default]

Apply complete! Resources: 72 added, 0 changed, 0 destroyed.

Outputs:

ACR_NAME = "pipefish47182acr"
APP_NAME = "pipefish-47182"
AZURE_STATIC_WEBAPP = "pipefish-47182-ui"
```
<p align="right">(<a href="#Infrastructure">back to top</a>)</p>

# External Access Infrastructure
## External Resource Groups
Name | Usage
------ | ----
Application Gateway Resource Group ("${app_name}_appgw_rg") | Resource Group for the Application Gateways
Static Web App Resource Group ("${app_name}_ui_rg") | Resource Group for UI components

<p align="right">(<a href="#Infrastructure">back to top</a>)</p>

## External Access Components
Name | Resource Group | Usage 
------ | ---- | ----
\${app_name}-ui | Static Web App Resource Group | Static Web Apps for the UI
\${app_name}-apim | Global Resource Group | Azure API Management (Developer SKU)
\${app_name}-gateway | Application Gateway Resource Group | Application Gateway for the API
\${app_name}-frontdoor | Global Resource Group | Azure Front Door for routing

## External Infrastructure Steps
> * **Note:** Before starting, ensure that the required external values are set in the .env file at the project root
```bash
➜  git:(main) ✗ task external #Calls task apim; task appgw; task frontdoor
➜  cqrs git:(main) ✗ task external
task: [apim] pwsh ./Deploy.ps1 -verbose -ApplicationName pipefish-47182 -Regions '["canadacentral"]' -DeploymentType single -PFXPath /home/brian/working/wildcard.apim.bjdazure.tech.pfx -PFXPassword .... -ApimGatewayUrls '["canadacentral.apim.bjdazure.tech"]' -ApimRootDomainName "apim.bjdazure.tech" -DNSZone bjdazure.tech
...
VERBOSE: 12:23:41 - Template is valid.
VERBOSE: 12:23:46 - Create template deployment 'ApiManagement-Deployment-pipefish-47182_global_rg-20250207122337'
VERBOSE: 12:23:46 - Checking deployment status in 5 seconds
VERBOSE: 12:23:51 - Checking deployment status in 5 seconds
VERBOSE: 12:23:57 - Resource Microsoft.ApiManagement/service 'pipefish-47182-apim' provisioning status is running
VERBOSE: 12:23:57 - Checking deployment status in 17 seconds
VERBOSE: 12:24:15 - Checking deployment status in 21 seconds
VERBOSE: 12:24:36 - Checking deployment status in 20 seconds
...
VERBOSE: Record set 'management.scm.apim' was created in Private DNS zone 'bjdazure.tech'.The record set is empty. Use Add-AzPrivateDnsRecordConfig to add A records to it and Set-AzDnsRecordSet to save your changes.
VERBOSE: After you create A records in this record set you will be able to query them in DNS using the FQDN 'management.scm.apim.bjdazure.tech.'

Id                : /subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_infra_rg/providers/Microsoft.Network/privateDnsZones/bjdazure.tech/A/management.scm.apim
Name              : management.scm.apim
ZoneName          : bjdazure.tech
ResourceGroupName : pipefish-47182_canadacentral_infra_rg
Ttl               : 3600
Etag              : 56296d26-2ced-4294-9309-da4eab0d1f14
RecordType        : A
Records           : {10.155.4.5}
Metadata          :
IsAutoRegistered  : False

task: [product] pwsh ./Deploy.ps1 -verbose -ApplicationName pipefish-47182 -primaryBackendUrl "https://api.ingress.bjdazure.tech"
....
task: [appgateway] pwsh ./Deploy.ps1 -verbose -ApplicationName pipefish-47182 -Regions '["canadacentral"]' -DeploymentType single -PFXPath /home/brian/working/api.bjdazure.tech/api.bjdazure.tech.pfx -PFXPassword ... -AppGatewayUrls '["canadacentral.api.bjdazure.tech"]' -BackendHostNames '["canadacentral.apim.bjdazure.tech"]'
VERBOSE: Populating RepositorySourceLocation property for module Az.Accounts.
VERBOSE: Populating RepositorySourceLocation property for module Az.Accounts.
....
VERBOSE: 12:56:02 - Resource Microsoft.Network/applicationGateways 'pipefish-47182-gw-canadacentral' provisioning status is succeeded
VERBOSE: Please create a 'A' DNS Recording point 'canadacentral.api.bjdazure.tech' to '4.205.88.168'
task: [frontdoor] pwsh ./Deploy.ps1 -verbose -ApplicationName pipefish-47182 -Regions '["canadacentral"]' -DeploymentType single -FrontDoorUri api.bjdazure.tech -BackendHostNames '["canadacentral.api.bjdazure.tech"]' -DeployWAFPolicies $true
Ensure that a CNAME DNS record exists that maps api.bjdazure.tech to afd-pipefish-47182.z01.azurefd.net...:
....
DeploymentName          : WAF-Deployment-pipefish-47182_appgw_rg-20250207010406
ResourceGroupName       : pipefish-47182_appgw_rg
ProvisioningState       : Succeeded
Timestamp               : 02/07/2025 19:04:16
Mode                    : Incremental
TemplateLink            :
Parameters              :
                          Name                     Type                       Value
                          =======================  =========================  ==========
                          azureFrontDoorID         String                     "4694b6a9-f090-459b-8ac9-0e0ebf39170f"
                          appGatewayName           String                     "pipefish-47182-gw"
                          location                 String                     "canadacentral"
                          secondaryLocation        String                     "ukwest"
                          multiRegionDeployment    String                     "false"

Outputs                 :
DeploymentDebugLogLevel :
```

## Required External Manual Steps
* Create DNS A records for each Application Gateway as outputted by the deploy `appgateway` task
* Create DNS CNAME record for the Azure Front Door as outputted by the deploy `frontdoor` task
<p align="right">(<a href="#Infrastructure">back to top</a>)</p>

# Navigation
[⏪ Previous Section](../docs/letsencrypt.md) ‖ [Return to Main Index 🏠](../README.md) ‖ [Next Section ⏩](../docs/code.md) 
<p align="right">(<a href="#Infrastructure">back to top</a>)</p>