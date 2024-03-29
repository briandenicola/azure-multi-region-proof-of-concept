# Introduction
A very simple setup for Command Query Responsibility Separation (CQRS) in Azure that can be deployed to one or more Azure regions.
In other words, the world's most expensive random number generator....

![Architecture](./.assets/architecture.png)

# Setup

## Prerequisite
* PowerShell
* Azure Cli
* Azure Static Webapp cli
* Terraform
* A public domain that you can create DNS records
   * Will use bjd.demo for this documentation 
* Certificates
   * Follow this [link](./letsencrypt.md) for required certificates 

### Public DNS Records: 
_Only required if deploying application externally with APIM/AppGateway/FrontDoor_
* api.bjd.demo - CNAME to the Azure Front Door Name 
* api.us.bjd.demo - Public IP Address of Azure Gateway US Region. This needs to be be created after the App Gateway is configured. The ARM template will ouput the public IP address
* api.uk.bjd.demo - Public IP Address of Azure Gateway UK Region. This needs to be be created after the App Gateway is configured. The ARM template will ouput the public IP address
    
## Infrastructure Steps
```powershell
pwsh
cd ./scripts
$opts = @{
    regions             = '["westus3", "ukwest"]'
    SubscriptionName    = "my_subscription"
    DomainName          = "bjd.demo" 
    IngressPfxFilePath  = "~/certs/wildcard.bjd.demo.pfx"
    PFXPassword         = $PfxPASSWORD   
}
./create_core_infrastructure.ps1 @opts
```

## Application Build Deployment 
```powershell
pwsh
$AppName = "quetzal-8233" #This will be the output from the create_core_infrastructure.ps1 script
cd ./scripts
$opts = @{
    AppName             = $AppName
    Regions             = '["westus3", "ukwest"]'
    SubscriptionName    = "my_subscription"
    DomainName          = "bjda.demo"
}
./deploy_application.ps1 @opts
```

# Expose API Externally 
* The demo can be expanded to include additional Azure resources - Front Door, API Maanagment, Azure App Gateway - for external access.

## Automated Steps
```powershell
pwsh
cd ./scripts
$opts = @{
	AppName                   = $AppName
	Regions                   = @("westus3","ukwest")
	SubscriptionName          = "my_subscription"
	DeploymentType            = "multi"
	ApiManagementPfxFilePath  = "~/certs/apim.pfx"
	AppGatewayPfxFilePath     = "~/certs/gw.pfx"
	PfxPassword               = (ConvertTo-SecureString -String $PfxPASSWORD -AsPlainText -Force)
	DNSZone                   = "bjd.demo"
	IngressUrl                = "api.ingress.bjd.demo"
	ApimRootDomainName	  	  = "apim.bjd.demo"
	ApimGatewayUrls           = @("api.apim.us.bjd.demo","api.apim.uk.bjd.demo") 
	AppGatewayUrls            = @("api.us.bjd.demo","api.uk.bjd.demo")
	FrontDoorUrl              = "api.bjd.demo"
}
./create_ext_infrastructure.ps1 @opts
```

## Manual Steps
* You need to take the IP Addresses from the output of the App Gateway ARM template to create DNS records with your external DNS provider
* You need to assoicate the APIM Product Key Service with the Key Service and Key Service v2 APIs
* You need to then log into the Azure Portal > App Gateway (per region) and associate each App Gateway with their regional WAF policy
* You need to manually enable TLS on the custom Front Door Uri. Use the Front Door provided certificate 
* You can create a custom domain for the Static Web App UI and use the provided certificate but this is not required.

# Testing
## Test Container Apps 
```powershell
cd ./tests
./validate.ps1 -DomainName bjd.demo -RG quetzal-8233_westus3_rg
```

## Test Application Gateways Individually using PowerShell
* Obtain your APIM subscription key from the APIM Service 
```powershell
$h = New-APIMHeader -key $apiSubscriptionKey
Invoke-RestMethod -UseBasicParsing `
    -Uri https://api.us.bjd.demo/k/10?api-version=2020-05-04 ` 
    -Method Post `
    -Headers $h
Invoke-RestMethod -UseBasicParsing `
    -Uri https://api.uk.bjd.demo/k/10?api-version=2020-05-04 `
    -Method Post `
    -Headers $h

$keyId = "" #copy a reply from the commands above
Invoke-RestMethod -UseBasicParsing `
    -Uri https://api.us.bjd.demo/k/${keyId}?api-version=2020-05-04 `
    -Headers $h
Invoke-RestMethod -UseBasicParsing `
    -Uri https://api.uk.bjd.demo/k/${keyId}?api-version=2020-05-04 `
    -Headers $h
```



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
- [x] Multiple Region Deployment with Azure Front Door
- [x] Add support for Cosmos DB private endpoint
- [x] Add support for Storage private endpoint
- [x] Add support for Redis Cache private endpoint
- [x] Add support for Azure Container Repo private endpoint
- [x] Add support for Azure Event Hubs private endpoints
- [x] Add support for Azure Private DNS Zones
- [x] Update diagrams 
- [x] Update documention
- [x] Update for Terraforms to create main infrastructure components
- [x] GitHub Actions pipeline 
- [x] Simplify deployment
- [x] Move to Azure Container Apps
- [x] Move to dotnet8
