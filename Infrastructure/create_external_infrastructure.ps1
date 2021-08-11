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

.PARAMETER AppName
Specifies the main directory to copy files from. Mandatory parameter

.PARAMETER Regions
Specifies the main directory to copy files to. Mandatory parameter

.PARAMETER SubscriptionName
Specifies an array of extensions of files to ignore in the sync process

.PARAMETER DeploymentType
Switch to including logging of files copied. Parameter Set = Logging

.PARAMETER ApiManagementPfxFilePath
Full Path to Log file. Parameter Set = Logging

.PARAMETER AppGatewayPfxFilePath
Full Path to Log file. Parameter Set = Logging

.PARAMETER PFXPassword
Full Path to Log file. Parameter Set = Logging

.PARAMETER AksIngressUrl
Full Path to Log file. Parameter Set = Logging

.PARAMETER ApiManagementUrls
Full Path to Log file. Parameter Set = Logging

.PARAMETER AppGatewayUrls
Full Path to Log file. Parameter Set = Logging

.PARAMETER FrontDoorUrl
Full Path to Log file. Parameter Set = Logging

#>
param (
    [Parameter(Mandatory = $true)]
    [string]          $AppName,

    [Parameter(Mandatory = $true)]
    [string[]]          $Regions,

    [Parameter(Mandatory = $true)]
    [string]          $SubscriptionName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multi")]
    [string]          $DeploymentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]          $ApiManagementPfxFilePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]          $AppGatewayPfxFilePath,
        
    [Parameter(Mandatory = $true)]
    [securestring]    $PFXPassword,

    [Parameter(Mandatory = $true)]
    [string]          $AksIngressUrl,

    [Parameter(Mandatory = $true)]
    [string[]]        $ApiManagementUrls,

    [Parameter(Mandatory = $true)]
    [string[]]        $AppGatewayUrls,

    [Parameter(Mandatory = $true)]
    [string]        $FrontDoorUrl
)  

function Start-UiBuild
{   
    dotnet build
    dotnet publish -c Release -o build
}

function Deploy-toAzStaticWebApp
{
    param(
        [string] $Name,
        [string] $ResourceGroup,
        [string] $LocalPath
    )

    function Get-AzStaticWebAppSecrets {
        param (
            [string] $Name,
            [string] $ResourceGroup
        )

        $management_uri = "https://management.azure.com"
        $api_version_query = "listsecrets?api-version=2020-06-01"
        $id = Get-AzStaticWebApp -Name $Name -ResourceGroupName $ResourceGroup | Select-Object -ExpandProperty Id
        $uri = "{0}{1}/{2}" -f $management_uri, $id, $api_version_query

        return (Invoke-AzRestMethod -Method POST -Uri $uri | Select-Object -ExpandProperty Properties | Select-Object -ExpandProperty apiKey)
    }

    $token = Get-AzStaticWebAppSecrets -Name $Name -ResourceGroup $ResourceGroup

    docker run --entrypoint "/bin/staticsites/StaticSitesClient" `
        --volume ${LocalPath}:/root/build `
        mcr.microsoft.com/appsvc/staticappsclient:stable `
        upload `
        --skipAppBuild true `
        --app /root/build/wwwroot `
        --apiToken $token
}

Set-Variable -Name APP_UI_NAME              -Value ("{0}ui01" -f $AppName)         -Option Constant
Set-Variable -Name APP_UI_RG                -Value ("{0}_global_rg" -f $AppName)   -Option Constant

Set-Variable -Name cwd                      -Value $PWD.Path
Set-Variable -Name root                     -Value (Get-Item $PWD.Path).Parent.FullName
Set-Variable -Name apim_directory           -Value (Join-Path -Path $root -ChildPath "Infrastructure/apim")
Set-Variable -Name apim_product_directory   -Value (Join-Path -Path $root -ChildPath "Infrastructure/product")
Set-Variable -Name appgw_directory          -Value (Join-Path -Path $root -ChildPath "Infrastructure/gateway")
Set-Variable -Name frontdoor_directory      -Value (Join-Path -Path $root -ChildPath "Infrastructure/frontdoor")
Set-Variable -Name ui_directory             -Value (Join-Path -Path $root -ChildPath "Source/ui")

Import-Module bjd.Common.Functions
Import-Module bjd.Azure.Functions

Connect-AzAccount
Select-AzSubscription -SubscriptionName $SubscriptionName

Set-Location -Path $apim_directory 
./Deploy.ps1 -ApplicationName $AppName -Regions $Regions -DeploymentType $DeploymentType -PFXPath $ApiManagementPfxFilePath  -PFXPassword $PFXPassword -ApimProxies $ApiManagementUrls

Set-Location -Path $apim_product_directory
./Deploy.ps1 -ApplicationName $AppName -primaryBackendUrl ("https://{0}" -f $AksIngressUrl) -Verbose

Set-Location -Path $appgw_directory
./Deploy.ps1 -ApplicationName $AppName -Regions $Regions -DeploymentType $DeploymentType  -PFXPath $AppGatewayPfxFilePath -PFXPassword $PFXPassword -BackendHostNames $ApiManagementUrls

Set-Location -Path $frontdoor_directory
./Deploy.ps1 -ApplicationName $AppName -FrontDoorUri $FrontDoorUrl -BackendHostNames $AppGatewayUrls -DeployWAFPolicies

Set-Location -Path $ui_directory
Start-UiBuild
New-AzStaticWebApp -Name $APP_UI_NAME -ResourceGroupName $APP_UI_RG -Location $Regions[0] -SkuName Free -AppLocation "/Source/ui" -AppArtifactLocation "wwwroot" 
Deploy-toAzStaticWebApp -Name $APP_UI_NAME -ResourceGroup $APP_UI_RG -LocalPath (Join-Path -Path $PWD.Path -ChildPath "build")

Set-Location -Path $cwd