<#
.SYNOPSIS
This PowerShell Script will stand up Azure API Management, Azure App Gateway, and Azure Front Door servies to extend the CQRS appplication externally.

.DESCRIPTION
Version - 0.5.1
This PowerShell Script will stand up Azure API Management, Azure App Gateway, and Azure Front Door servies to extend the CQRS appplication externally.

.EXAMPLE
.\create_external_infrastructure.ps1 -AppName example123 -Regions @("eastus2","ukwest") -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -DeploymentType multi -ApiManagementPfxFilePath ~/certs/apim.pfx -AppGatewayPfxFilePath ~/certs/gw.pfx -PFXPassword xyz -AksIngressUrl api.ingress.bjd.demo -ApiManagementUrls @("api.apim.us.bjd.demo","api.apim.uk.bjd.demo") -AppGatewayUrls @("api.us.bjd.demo","api.uk.bjd.demo") -FrontDoorUrl api.bjd.demo

.EXAMPLE
.\create_external_infrastructure.ps1 -AppName example123 -Regions @("eastus2") -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -DeploymentType single -ApiManagementPfxFilePath ~/certs/apim.pfx -AppGatewayPfxFilePath ~/certs/gw.pfx -PFXPassword xyz -AksIngressUrl api.ingress.bjd.demo -ApiManagementUrls @("api.apim.us.bjd.demo") -AppGatewayUrls @("api.us.bjd.demo") -FrontDoorUrl api.bjd.demo

.PARAMETER AppNmame
Specifies the Application Name as outputtee by the create_core_infrastructure.ps1 script

.PARAMETER Regions
Specifies the Regions used 

.PARAMETER SubscriptionName
The Subscription Name to deploy the Azure Resources. Mandatory parameter

.PARAMETER DeploymentType
The type of deployment. Mandatory parameter - Single region or Multiple regions

.PARAMETER ApiManagementPfxFilePath
The Path to the certificate that will be used by the API Management to terminate TLS. Mandatory parameter

.PARAMETER AppGatewayPfxFilePath
The Path to the certificate that will be used by the App Gateway to terminate TLS externally. Mandatory parameter

.PARAMETER PFXPassword
The PFX Password. Mandatory parameter

.PARAMETER IngressUrl
The URL of the Container Apps endpoint. Mandatory parameter

.PARAMETER ApiManagementUrls
An array of URLs for the API Management service. Mandatory parameter

.PARAMETER AppGatewayUrls
An array of URLs for the App Gateway service. Mandatory parameter

.PARAMETER FrontDoorUrl
The URL of the Front Door endpoint. Mandatory parameter
#>
param (
    [Parameter(Mandatory = $true)]
    [string]            $AppName,

    [Parameter(Mandatory = $true)]
    [string[]]          $Regions,

    [Parameter(Mandatory = $true)]
    [string]            $SubscriptionName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multi")]
    [string]            $DeploymentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]            $ApiManagementPfxFilePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]            $AppGatewayPfxFilePath,
        
    [Parameter(Mandatory = $true)]
    [securestring]      $PFXPassword,

    [Parameter(Mandatory = $true)]
    [string]            $IngressUrl,

    [Parameter(Mandatory = $true)]
    [string[]]          $ApiManagementUrls,

    [Parameter(Mandatory = $true)]
    [string[]]          $AppGatewayUrls,

    [Parameter(Mandatory = $true)]
    [string]            $FrontDoorUrl
)  

. ./modules/functions.ps1
. ./modules/naming.ps1 -AppName $AppName

Connect-ToAzure -SubscriptionName $SubscriptionName

Set-Location -Path $apim_directory 
./Deploy.ps1 -ApplicationName $AppName -Regions $Regions -DeploymentType $DeploymentType -PFXPath $ApiManagementPfxFilePath  -PFXPassword $PFXPassword -ApimProxies $ApiManagementUrls

Set-Location -Path $apim_product_directory
./Deploy.ps1 -ApplicationName $AppName -primaryBackendUrl ("https://{0}" -f $IngressUrl) -Verbose

Set-Location -Path $appgw_directory
./Deploy.ps1 -ApplicationName $AppName -Regions $Regions -DeploymentType $DeploymentType  -PFXPath $AppGatewayPfxFilePath -PFXPassword $PFXPassword -BackendHostNames $ApiManagementUrls

Set-Location -Path $frontdoor_directory
./Deploy.ps1 -ApplicationName $AppName -FrontDoorUri $FrontDoorUrl -BackendHostNames $AppGatewayUrls -DeployWAFPolicies -DeploymentType $DeploymentType -Regions $Regions

Set-Location -Path $ui_directory
Start-UiBuild
New-AzStaticWebApp -Name $APP_UI_NAME -ResourceGroupName $APP_UI_RG -Location $Regions[0] -SkuName Free -AppLocation "/src/ui" -AppArtifactLocation "wwwroot" 
Deploy-toAzStaticWebApp -Name $APP_UI_NAME -LocalPath $local_path

Set-Location -Path $cwd