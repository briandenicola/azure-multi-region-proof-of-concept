# Introduction
A very simple setup for Command Query Responsibility Separation (CQRS) in Azure that can be deployed to one or more Azure regions.
In other words, the world's most expensive random number generator....

![Architecture](./architecture.png)

# Setup

## Infrastructure Steps
* cd ./Infrastructure
* ./create_infrastructure.sh -r centralus -r ukwest
    * Autogenerates an Application Name 
    * Creates a Resource Group name ${appName}_global_rg and ${appName}_${region}_rg
* ./setup_diagnostics.sh -n ${appName} -r centralus _optional_
    * appName will be display at the end of the create_infrastructure.sh script 

## Application Deployment 
* cd ./Infrastructure
* ./deploy_application.sh -n ${appName} -r centralus -r ukwest -v 1.0

## Expose API Externally _optional_ 
* The create_infrastructure and deploy_application scripts create the foundations for this demo. The demo can be expanded to include additional Azure resources - Front Door, API Maanagment, Azure App Gateway.  

### Prerequisite
* A public domain that you can create DNS records
* DNS Records:
    * api.bjdcsa.cloud - CNAME to the Azure Front Door Name ()
    * api.us.bjdcsa.cloud - Public IP Address of Azure Gateway US Region.
        * This can be created after the App Gateway is configured
    * api.uk.bjdcsa.cloud - Public IP Address of Azure Gateway UK Region
        * This can be created after the App Gateway is configured
    * api-intenal.us.bjdcsa.cloud - Private IP Address of Azure APIM US Region. Typically 10.1.2.5 or 10.1.2.6
    * api-intenal.uk.bjdcsa.cloud - Private IP Address of Azure APIM UK Region. Typically 10.2.2.5 or 10.2.2.6
    * portal.bjdcsa.cloud - Private IP Address of Azure APIM US Region. Typically 10.1.2.5 or 10.1.2.6
    * developer.bjdcsa.cloud - Private IP Address of Azure APIM US Region. Typically 10.1.2.5 or 10.1.2.6

### SSL Cert Requirements 
* To expose the application externally, TLS certificates and a Domain name are required. I used Let's Encrypt and Azure DNS to host my domain name.
* We need to create 2 certificates. One for API Management and one for APP Gateway
* Steps:
    * curl https://get.acme.sh | sh
    * acme.sh --issue --dns dns_azure -d portal.bjdcsa.cloud -d management.bjdcsa.cloud -d developer.bjdcsa.cloud -d api-internal.us.bjdcsa.cloud -d api-internal.uk.bjdcsa.cloud -d management.scm.bjdcsa.cloud
    * acme.sh --issue --dns dns_azure -d api.bjdcsa.cloud -d api.us.bjdcsa.cloud -d api.uk.bjdcsa.cloud
    * acme.sh --toPkcs -d portal.bjdcsa.cloud
    * acme.sh --toPkcs -d api.bjdcsa.cloud
    * pwsh > [convert]::ToBase64String( (Get-Content -AsByteStream .\portal.bjdcsa.cloud.pfx) _This will be used in the Azure ARM Templates_
    * pwsh > [convert]::ToBase64String( (Get-Content -AsByteStream .\api.bjdcsa.cloud.pfx) _This will be used in the Azure ARM Templates_

### API Management 
* Update apim\azuredeploy.parameters.json 
    * apiManagementName: bjdapim001
    * secondaryLocation: ukwest
    * primaryVnetName/secondaryVnetName: vnet${appName}001 or vnet${appName}002 
    * primaryVnetResourceGroup/secondaryVnetResourceGroup: ${appName}_useast2_rg or ${appName}_ukwest_rg
    * customDomain: bjdcsa.cloud
    * customDomainCertificateData: Base64 output of portal.bjdcsa.cloud.pfx
    * customDomainCertificatePassword: password for pfx file
    * multiRegionDeployment: "true"
* cd .\apim
* New-AzResourceGroupDeployment -Name apim -ResourceGroupName ${appName}_global_rg -TemplateParameterFile .\azuredeploy.parameters.json -TemplateFile .\azuredeploy.json
* cd ..\product
* .\Deploy.ps1 -ResourceGroupName ${appName}_global_rg -ResourceLocation eastus2 -SecondaryRegion "UK West" -ApiManagementName bjdapim001 -primaryBackendUrl http://10.1.4.127 -SecondaryBackendUrl http://10.2.4.127
* MANUAL ALERT - You need to log into the Azure Portal > APIM and associate the AesKey APIs with the KeyService Products
    * TBD to automate this

### APP Gateway 
* Update gateway\azuredeploy.parameters.json
    * appGatewayName: bjdgw001
    * multiRegionDeployment: true
    * secondaryLocation: ukwest
    * primaryVnetName/secondaryVnetName: vnet${appName}001 or vnet${appName}002 
    * primaryVnetResourceGroup/secondaryVnetResourceGroup: ${appName}_useast2_rg or ${appName}_ukwest_rg
    * domainCertificateData: Base64 output of api.bjdcsa.cloud.pfx
    * domainCertificatePassword: password for pfx file
    * primaryBackendEndFQDN: api-internal.us.bjdcsa.cloud
    * secondaryBackendEndFQDN: api-internal.uk.bjdcsa.cloud
* cd .\gateway
* New-AzResourceGroupDeployment -Name appgw -ResourceGroupName ${appName}_global_rg -TemplateParameterFile .\azuredeploy.parameters.json -TemplateFile .\azuredeploy.json

### Front Door
* Update frontdoor\azuredeploy.parameters.json
    * frontDoorName: bjdfd001
    * frontDoorUrl: api.bjdcsa.cloud
    * primaryBackendEndFQDN: api.us.bjdcsa.cloud
    * secondaryBackendEndFQDN: api.uk.bjdcsa.cloud
* cd ..\frontdoor
* New-AzResourceGroupDeployment -Name frontdoor -ResourceGroupName ${appName}_global_rg -TemplateParameterFile .\azuredeploy.parameters.json -TemplateFile .\azuredeploy.json

## Test
* Test Local Deployment directly on AKS clusters 
    * ./Scripts/create_keys.sh 100 
* Test Individual Application Gateways
    * Obtain your APIM
    * h = New-APIMHeader -key $apiSubscriptionKey 
        * New-APIMHeader is a method in bjd.Azure.Functions
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjdcsa.cloud/k/10?api-version=2020-05-04 -Method Post -Headers $h
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjdcsa.cloud/k/10?api-version=2020-05-04 -Method Post -Headers $h
    * $keyId = copy a reply from the commands above
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjdcsa.cloud/k/${keyId}?api-version=2020-05-04 -Headers $h
    * Invoke-RestMethod -UseBasicParsing -Uri https://api.uk.bjdcsa.cloud/k/${keyId}?api-version=2020-05-04 -Headers $h
* Test Azure Front Door globally with Azure ACI
    * cd .\Infrastructure\ACI
    * New-AzResourceGroup -Name ${appName}_tests_rg -l useast2
    * New-AzResourceGroupDeployment -Name aci -ResourceGroupName ${appName}_tests_rgg -Verbose -TemplateFile .\azuredeploy.json -apimSubscriptionKey ${apiSubscriptionKey} -frontDoorUrl https://api.bjdcsa.cloud -keyGuid ${keyId}
    * az container logs --resource-group fqrmcwib_tests_rg --name utils-australiaeast-get
    * az container logs --resource-group fqrmcwib_tests_rg --name utils-australiaeast-post
    * az container logs --resource-group fqrmcwib_tests_rg --name utils-westeurope-get
    * az container logs --resource-group fqrmcwib_tests_rg --name utils-westeurope-post
    * az container logs --resource-group fqrmcwib_tests_rg --name utils-japaneast-get

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
- [ ] Add support for Redis Cache (preview)
- [x] Add support for Azure Private DNS Zones
- [ ] Update diagrams 
- [x] Update documention
- [ ] GitHub Actions pipeline 

# Issues
- [x] Docker build on Azure Functions has warnings. func kubernetes deploy does not
    * docker build -t bjd145/eventprocessor:1.1 . 
        * /root/.nuget/packages/microsoft.azure.webjobs.script.extensionsmetadatagenerator/1.1.2/build/Microsoft.Azure.WebJobs.Script.ExtensionsMetadataGenerator.targets(52,5): warning :     Could not evaluate 'Cosmos.CRTCompat.dll' for extension metadata. Exception message: Bad IL format. [/src/dotnet-function-app/eventing.csproj]
        * Downgrading to Microsoft.NET.Sdk.Functions Version "1.0.24" resolved the issue
