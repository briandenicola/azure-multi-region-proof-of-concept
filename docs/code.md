Core Build & Deployment
=============
* This application on dotnet8 and golang.
* The Golang code is an API that pushes events to Azure Event Hub.
* An EventProcessor written, in dotnet, processes the events and stores them in Cosmos DB.
* A ChangeFeedProcessor written, in dotnet, processes the events and stores them in Redis Cache
* The application is hosted on Azure Container Apps.
* Container App Event Triggers scale the Event Processor based on the number of events in the Event Hub.
* Deployment will create the necessary Container App and required configuration for it in Azure.

UI Build & Deployment
=============
* The UI is built using dotnet Blazor
* It is hosted uses Azure Static Web Apps.
* The deployment uses the Azure Static Web Apps cli to deploy the application to Azure.

## Container Apps
=============
Name | Resource Group | Usage 
------ | ---- | ----
api | Application Resource Group  | REST API that pushes events to Event Hub. Will be configured with a custom domain.
eventprocessor | Application Resource Group  | Process events from Event Hub and store in Cosmos DB
changefeedproccesor | Application Resource Group | Process events from Cosmos DB and store in Redis Cache
utils | Application Resource Group | Test and Validation

# Steps
Application Build
=============
```bash
➜  git:(main) ✗ task build
task: [build] pwsh ./build-containers.ps1 -AppName pipefish-47182 -ACRName pipefish47182acr -CommitVersion ca83ff77 -SourceRootPath "../src"
* Starting Docker: docker                                                                                                                            
Login Succeeded
[+] Building 6.7s (10/13)                                                                                                              docker:default
 => [internal] load build definition from dockerfile                                                                                             0.0s
 => => transferring dockerfile: 443B                                                                                                             0.0s
 => [internal] load metadata for docker.io/library/golang:1.23                                                                                   0.6s
 => [internal] load metadata for gcr.io/distroless/static-debian11:latest                                                                        0.3s
 => [auth] library/golang:pull token for registry-1.docker.io                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                                0.0s
 => => transferring context: 2B                                                                                                                  0.0s
 => [builder 1/5] FROM docker.io/library/golang:1.23@sha256:927112936d6b496ed95f55f362cc09da6e3e624ef868814c56d55bd7323e0959                     0.0s
 => CACHED [stage-1 1/2] FROM gcr.io/distroless/static-debian11:latest@sha256:1dbe426d60caed5d19597532a2d74c8056cd7b1674042b88f7328690b5ead8ed   0.0s
 => [internal] load build context                                                                                                                0.1s
 => => transferring context: 33.12kB                                                                                                             0.0s
 ....
The push refers to repository [pipefish47182acr.azurecr.io/cqrs/eventprocessor]
1a50a868f0eb: Pushed
1f450579dfdc: Pushed
887b55a87a30: Pushed
68dbb66ed33a: Pushed
06df23b1e0fd: Pushed
f07c146df8a6: Pushed
9f71735511ce: Pushed
0fbbfdee9cdd: Pushed
bc198994fabd: Pushed
b138fdfd1095: Pushed
f5fe472da253: Pushed
ca83ff77: digest: sha256:78bd456088457d84981134315979f64451656dcf2ed983ccf03bee0d6f1f8950 size: 2630
[+] Building 34.9s (8/10)                                                       
...
 => => writing image sha256:5adc137be0a00e67ab627af452d49bb1dcff19ad3c6fe8e748b9e42b6a265e81                                                     0.0s
 => => naming to pipefish47182acr.azurecr.io/cqrs/changefeedprocessor:ca83ff77                                                                   0.0s
The push refers to repository [pipefish47182acr.azurecr.io/cqrs/changefeedprocessor]
271f8e07804b: Pushed
1f450579dfdc: Mounted from cqrs/eventprocessor
887b55a87a30: Mounted from cqrs/eventprocessor
68dbb66ed33a: Mounted from cqrs/eventprocessor
06df23b1e0fd: Mounted from cqrs/eventprocessor
f07c146df8a6: Mounted from cqrs/eventprocessor
9f71735511ce: Mounted from cqrs/eventprocessor
0fbbfdee9cdd: Mounted from cqrs/eventprocessor
bc198994fabd: Mounted from cqrs/eventprocessor
b138fdfd1095: Mounted from cqrs/eventprocessor
f5fe472da253: Mounted from cqrs/eventprocessor
ca83ff77: digest: sha256:810ce3905218f137eeb9fbdef9ee1d7eb911b929ef6a944d1fc85c59193e36f0 size: 2631
```

Application Deployment 
=============
```bash
➜  cqrs git:(main) ✗ task deploy
task: [appinit] terraform -chdir=./app init

Initializing the backend...
Initializing modules...
- container_apps in apps
- jumpbox in jumpbox

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 4.0"...
- Finding azure/azapi versions matching "~> 2.0"...
- Finding latest version of hashicorp/http...
- Installing hashicorp/azurerm v4.18.0...
- Installed hashicorp/azurerm v4.18.0 (signed by HashiCorp)
- Installing azure/azapi v2.2.0...
...
module.container_apps["canadacentral"].data.azurerm_eventhub_namespace.cqrs: Read complete after 2s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_apps_rg/providers/Microsoft.EventHub/namespaces/pipefish-47182-canadacentral-eventhubs]
module.container_apps["canadacentral"].data.azurerm_cosmosdb_account.cqrs: Read complete after 2s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_global_rg/providers/Microsoft.DocumentDB/databaseAccounts/pipefish-47182-cosmosdb]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.container_apps["canadacentral"].azurerm_container_app.api will be created
  + resource "azurerm_container_app" "api" {
      + container_app_environment_id  = "/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_infra_rg/providers/Microsoft.App/managedEnvironments/pipefish-47182-canadacentral-env"
      + custom_domain_verification_id = (sensitive value)
      + id                            = (known after apply)
      + latest_revision_fqdn          = (known after apply)
      + latest_revision_name          = (known after apply)
      + location                      = (known after apply)
      + name                          = "api"
      + outbound_ip_addresses         = (known after apply)
      + resource_group_name           = "pipefish-47182_canadacentral_apps_rg"
      + revision_mode                 = "Multiple"
      + workload_profile_name         = "default"
...
module.container_apps["canadacentral"].azurerm_container_app.changefeedprocessor: Still creating... [20s elapsed]
module.container_apps["canadacentral"].azurerm_container_app.eventprocessor: Still creating... [20s elapsed]
module.container_apps["canadacentral"].azurerm_container_app.eventprocessor: Creation complete after 27s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_apps_rg/providers/Microsoft.App/containerApps/eventprocessor]
module.container_apps["canadacentral"].azurerm_container_app.changefeedprocessor: Creation complete after 29s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_apps_rg/providers/Microsoft.App/containerApps/changefeedprocessor]
module.container_apps["canadacentral"].azurerm_container_app.api: Still creating... [30s elapsed]
module.container_apps["canadacentral"].azurerm_container_app.api: Creation complete after 31s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_apps_rg/providers/Microsoft.App/containerApps/api]
module.container_apps["canadacentral"].azurerm_container_app_custom_domain.api: Creating...
module.container_apps["canadacentral"].azurerm_container_app_custom_domain.api: Still creating... [10s elapsed]
module.container_apps["canadacentral"].azurerm_container_app_custom_domain.api: Still creating... [20s elapsed]
module.container_apps["canadacentral"].azurerm_container_app_custom_domain.api: Creation complete after 21s [id=/subscriptions/69dafa76-bad9-48a7-a96a-e1f25830a5b0/resourceGroups/pipefish-47182_canadacentral_apps_rg/providers/Microsoft.App/containerApps/api/customDomainName/api.ingress.bjdazure.tech]

Apply complete! Resources: 4 added, 1 changed, 0 destroyed.      
```

# UI Build and Deployment 
```bash
➜  cqrs git:(main) ✗ task ui
....
```

# Navigation
[Previous Section ⏪](../docs/infrastructure.md) ‖ [Return to Main Index 🏠](../Readme.md) ‖ [Next Section ⏩](../docs/testing.md) 
<p align="right">(<a href="#build">back to top</a>)</p>