# Introduction
A very simple setup for Command Query Responsibility Separation (CQRS) in Azure. 

# Setup
## Note 
* Deploy requires the Azure Functions Core Tools to install KEDA onto the AKS cluster 

## Infrastructure Steps
* cd ./Infrastructure
* ./create_infrastructure.sh -g CQRS_RG -l centralus -s MY_SUBSCRIPTIONAME
* ./setup_diagnostics.sh -n ${appName} -g CQRS_RG -l centralus -s MY_SUBSCRIPTIONAME
    * appName will be generated during create_infrastructure.sh
    * This script is optional 

## Application Deployment 
* cd ./Infrastructure
* ./deploy_application.sh -n ${appName} -s MY_SUBSCRIPTIONAME

### EventProcessor Function Build 
* cd ./Source/eventprocessor
* docker build -t <acr>.azurecr.io/eventprocessor:1.0 .
* docker push -t <acr>.azurecr.io/eventprocessor:1.0

### API Build
* cd ./Source/api
* docker build -t <acr>.azurecr.io/api:1.0 .
* docker push -t <acr>.azurecr.io/api:1.0

## Test
* ./Scripts/create_keys.sh 100
* Check Cosmos db and Redis Cache to validate the keys have been written to both Cosmos and Redis
    * Redis Console Commands
        * LIST *
        * GET <keyid>
* You can also use curl to get a specific key - curl http://<service_ip>/api/keys/<keyid>

# To Do List 
- [x] Infrastructure 
- [x] Test Flexvol with local.settings.json for Functions in container
- [x] Sample Python Script to create events published to Event Hub
- [x] Azure Function to process event, storing in Cosmos and Redis Cache
- [x] Go Write API to generate events to Event Hub 
- [x] Go Read API to read from Redis 
- [x] Go Read API to read from Cosmos db using SQL API
- [x] Deployment artifacts to Kubernetes
- [x] Configure Scaling with Keda 
- [x] Add Application Insights - golang
- [x] Add Application Insights - Azure Funtions
- [x] Log Analytics automation 
- [x] Update deployments to Helm 3
- [ ] Convert Azure cli scripts to Terraform 

# Issues
- [x] Docker build on Azure Functions has warnings. func kubernetes deploy does not
    * docker build -t bjd145/eventprocessor:1.1 . 
        * /root/.nuget/packages/microsoft.azure.webjobs.script.extensionsmetadatagenerator/1.1.2/build/Microsoft.Azure.WebJobs.Script.ExtensionsMetadataGenerator.targets(52,5): warning :     Could not evaluate 'Cosmos.CRTCompat.dll' for extension metadata. Exception message: Bad IL format. [/src/dotnet-function-app/eventing.csproj]
        * Downgrading to Microsoft.NET.Sdk.Functions Version "1.0.24" resolved the issue
