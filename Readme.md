# Introduction
A very simple setup for Command Query Responsibility Separation (CQRS) in Azure that can be deployed to one or more Azure regions.
In other words, the world's most expensive random number generator....

![Architecture](./architecture.png)

# Deployment 
![CQRS deploy to Azure](https://github.com/briandenicola/cqrs/workflows/CQRS%20deploy%20to%20Azure/badge.svg)

# Setup

## Prerequisite
* Azure PowerShell, Azure Cli, Terraform, Helm and Kubectl
* A public domain that you can create DNS records
    * Will use bjd.demo throughout the documentation 
    * The Public domain is used by Let's Encrypt to valiate domain ownership before granting tls certificates 
* Private Zone DNS Records: _Will be setup automatically_
    * api.ingress.bjd.demo - Private IP Address of ingress controll in all Region. 
* Private Zone DNS Records: _Need to be setup with Update-Dns.ps1 script_
    * api.apim.us.bjd.demo - Private IP Address of Azure APIM in the primary Region.
    * api.apim.uk.bjd.demo - Private IP Address of Azure APIM in the secondary Region. 
    * developer.bjd.demo - The APIM Developer portal. It resolves to the Private IP Address of Azure APIM in the primary Region.
    * management.bjd.demo - The APIM API endpoint. It resolves to the Private IP Address of Azure APIM in the primary Region.
* Public DNS Records: _Only required if deploying application externally with APIM/AppGateway/FrontDoor_
    * api.bjd.demo - CNAME to the Azure Front Door Name 
    * api.us.bjd.demo - Public IP Address of Azure Gateway US Region.
        * This needs to be be created after the App Gateway is configured. The ARM template will ouput the public IP address
    * api.uk.bjd.demo - Public IP Address of Azure Gateway UK Region
        * This needs to be be created after the App Gateway is configured. The ARM template will ouput the public IP address

## SSL Cert Requirements 
* I used Let's Encrypt and Azure DNS (which host my domain name) for domain validation
* Required Steps:
    * curl https://get.acme.sh | sh
    * acme.sh --issue --dns dns_azure -d api.ingress.bjd.demo
* Optional Steps: _Only required if deploying application externally with APIM/AppGateway/FrontDoor_
    * APIM Certificate: acme.sh --issue --dns dns_azure -d portal.bjd.demo -d management.bjd.demo -d developer.bjd.demo -d api.apim.us.bjd.demo -d api.apim.uk.bjd.demo -d management.scm.bjd.demo
    * AppGateway Certificate: acme.sh --issue --dns dns_azure -d api.bjd.demo -d api.us.bjd.demo -d api.uk.bjd.demo
    * acme.sh --toPkcs -d portal.bjd.demo
    * acme.sh --toPkcs -d api.bjd.demo
    * pwsh > [convert]::ToBase64String( (Get-Content -AsByteStream .\portal.bjd.demo.pfx) _This will be used in the Azure ARM Templates_
    * pwsh > [convert]::ToBase64String( (Get-Content -AsByteStream .\api.bjd.demo.pfx) _This will be used in the Azure ARM Templates_

## Infrastructure Steps
* cd ./Infrastructure
* ./create_infrastructure.sh -r centralus -r ukwest --domain bjd.demo
    * Generates a Terraform variable file with a random Application Name. 
    * Then calls Terraforms to plan then apply configuration
* ./setup_diagnostics.sh -n ${appName} -r centralus -r ukwest _optional_
    * appName will be display at the end of the create_infrastructure.sh script 

## Application Deployment 
* cd ./Infrastructure
* ./deploy_application.sh -n ${appName} -r centralus -r ukwest --domain bjd.demo --hostname api.ingress --cert {Path to PEM Cert file} --key {Path to PEM Key file}

## Expose API Externally _optional_ 
* The create_infrastructure and deploy_application scripts create the foundations for this demo. The demo can be expanded to include additional Azure resources - Front Door, API Maanagment, Azure App Gateway.  

### API Management 
* Update apim\azuredeploy.parameters.json 
    * apiManagementName: bjdapim001
    * secondaryLocation: ukwest
    * primaryVnetName/secondaryVnetName: vnet${appName}001 or vnet${appName}002 
    * primaryVnetResourceGroup/secondaryVnetResourceGroup: ${appName}_useast2_rg or ${appName}_ukwest_rg
    * customDomain: bjd.demo
    * customDomainCertificateData: Base64 output of portal.bjd.demo.pfx
    * customDomainCertificatePassword: password for pfx file
    * multiRegionDeployment: "true"
    * primaryBackendEndFQDN: api.apim.us.bjd.demo
    * secondaryBackendEndFQDN: api.apim.uk.bjd.demo
* cd .\apim
* New-AzResourceGroupDeployment -Name apim -ResourceGroupName ${appName}_global_rg -TemplateParameterFile .\azuredeploy.parameters.json -TemplateFile .\azuredeploy.json -Verbose
* .\Update-DNS.ps1 -AppName ${appName} -ApiMgmtName bjdapim001 -DomainName bjd.demo -Uris @("api.apim.us", "api.apim.uk")
* cd ..\product
* .\Deploy.ps1 -ResourceGroupName ${appName}_global_rg -ResourceLocation centralus -ApiManagementName bjdapim001 -primaryBackendUrl https://api.ingress.bjd.demo -Verbose
* MANUAL ALERT - You need to log into the Azure Portal > APIM and associate the AesKey APIs with the KeyService Products
    * TODO: Automate this steps in the ARM template

### APP Gateway 
* Update gateway\azuredeploy.parameters.json
    * appGatewayName: bjdgw001
    * multiRegionDeployment: true
    * secondaryLocation: ukwest
    * primaryVnetName/secondaryVnetName: vnet${appName}001 or vnet${appName}002 
    * primaryVnetResourceGroup/secondaryVnetResourceGroup: ${appName}_useast2_rg or ${appName}_ukwest_rg
    * domainCertificateData: Base64 output of api.bjd.demo.pfx
    * domainCertificatePassword: password for pfx file
    * primaryBackendEndFQDN: api-internal.us.bjd.demo
    * secondaryBackendEndFQDN: api-internal.uk.bjd.demo
* cd .\gateway
* New-AzResourceGroupDeployment -Name appgw -ResourceGroupName ${appName}_global_rg -TemplateParameterFile .\azuredeploy.parameters.json -TemplateFile .\azuredeploy.json

### Front Door
* Update frontdoor\azuredeploy.parameters.json
    * frontDoorName: bjdfd001
    * frontDoorUrl: api.bjd.demo
    * primaryBackendEndFQDN: api.us.bjd.demo
    * secondaryBackendEndFQDN: api.uk.bjd.demo
* cd ..\frontdoor
* New-AzResourceGroupDeployment -Name frontdoor -ResourceGroupName ${appName}_global_rg -TemplateParameterFile .\azuredeploy.parameters.json -TemplateFile .\azuredeploy.json
* _Optional: If you would like to lock down the AppGateways to only Azure Front Door_
* cd .\appgw-waf-policies
* New-AzResourceGroupDeployment -Name appgw -ResourceGroupName ${appName}_global_rg -TemplateFile .\azuredeploy.json -AzureFrontDoorID {Frond Door ID. Taken from output of Front Door ARM template}
* MANUAL ALERT - You need to then log into the Azure Portal > App Gateway (per region) and associate each App Gateway with their reginal WAF policy
    * TODO: Automate this steps in the ARM template

## Test
* Test Local Deployment directly on AKS clusters 
    * ./Scripts/create_keys.sh 100 
    * ./Scripts/get_keys.sh ${keyId}
        * Where ${keyId} is a GUID taken from the output of create_keys.sh
* Test Application Gateways Individually
    * Obtain your APIM
    * h = New-APIMHeader -key $apiSubscriptionKey 
        * New-APIMHeader is a method in bjd.Azure.Functions
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjd.demo/k/10?api-version=2020-05-04 -Method Post -Headers $h
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjd.demo/k/10?api-version=2020-05-04 -Method Post -Headers $h
    * $keyId = copy a reply from the commands above
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjd.demo/k/${keyId}?api-version=2020-05-04 -Headers $h
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjd.demo/k/${keyId}?api-version=2020-05-04 -Headers $h
* Test Azure Front Door globally with Azure ACI
    * cd .\Infrastructure\ACI
    * New-AzResourceGroup -Name ${appName}_tests_rg -l useast2
    * New-AzResourceGroupDeployment -Name aci -ResourceGroupName ${appName}_tests_rgg -Verbose -TemplateFile .\azuredeploy.json -apimSubscriptionKey ${apiSubscriptionKey} -frontDoorUrl https://api.bjd.demo -keyGuid ${keyId}
    * az container logs --resource-group ${appName}_tests_rg --name utils-australiaeast-get
    * az container logs --resource-group ${appName}_tests_rg --name utils-australiaeast-post
    * az container logs --resource-group ${appName}_tests_rg --name utils-westeurope-get
    * az container logs --resource-group ${appName}_tests_rg --name utils-westeurope-post
    * az container logs --resource-group ${appName}_tests_rg --name utils-japaneast-get

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
- [ ] Distributed Tracing support

# Issues
- [x] Docker build on Azure Functions has warnings. func kubernetes deploy does not
    * docker build -t bjd145/eventprocessor:1.1 . 
        * /root/.nuget/packages/microsoft.azure.webjobs.script.extensionsmetadatagenerator/1.1.2/build/Microsoft.Azure.WebJobs.Script.ExtensionsMetadataGenerator.targets(52,5): warning :     Could not evaluate 'Cosmos.CRTCompat.dll' for extension metadata. Exception message: Bad IL format. [/src/dotnet-function-app/eventing.csproj]
        * Downgrading to Microsoft.NET.Sdk.Functions Version "1.0.24" resolved the issue
