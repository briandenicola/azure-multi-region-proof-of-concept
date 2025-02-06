param (
    [Parameter(Mandatory = $true)]
    [string]    $ApplicationName,

    [Parameter(Mandatory = $true)]
    [string]    $FrontDoorUri,

    [Parameter(Mandatory = $true)]
    [string]    $BackendHostNames,

    [Parameter(Mandatory = $false)]
    [switch]    $DeployWAFPolicies,

    [Parameter(Mandatory = $true)]
    [string]    $Regions,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multiregion")]
    [string]    $DeploymentType
)  

$AllRegions           = @($Regions | ConvertFrom-Json)
$AllBackendHostNames  = @($BackendHostNames | ConvertFrom-Json)

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$AppGwRGName       = "{0}_appgw_rg" -f $ApplicationName
$FrontDoorName     = "afd-{0}" -f $ApplicationName 

Read-Host -Prompt ("Ensure that a CNAME DNS record exists that maps {0} to {1}.z01.azurefd.net..." -f $FrontDoorUri, $FrontDoorName)

$opts = @{
    Name                  = ("FrontDoor-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName     = $ResourceGroupName
    TemplateFile          = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    frontDoorName         = $FrontDoorName
    frontDoorUrl          = $FrontDoorUri
    primaryBackendEndFQDN = $AllBackendHostNames[0]
}

if ($DeploymentType -eq "multiregion") {
    $opts.secondaryBackendEndFQDN = $AllBackendHostNames[1]
}
$result = New-AzResourceGroupDeployment @opts -verbose

if ($DeployWAFPolicies) {
    
    $frontdoorId        = $result.Outputs["front Door ID"].Value
    $AppGatewayName     = "{0}-gw" -f $ApplicationName

    $opts = @{
        Name              = ("WAF-Deployment-{0}-{1}" -f $AppGwRGName, $(Get-Date).ToString("yyyyMMddhhmmss"))
        ResourceGroupName = $AppGwRGName
        TemplateFile      = (Join-Path -Path $PWD.Path -ChildPath ".\appgw-waf-policies\azuredeploy.json")
        AzureFrontDoorID  = $frontDoorId
        AppGatewayName    = $AppGatewayName
    }

    if ($DeploymentType -eq "multiregion") {
        $opts.secondaryLocation     = $AllRegions[1]
        $opts.multiRegionDeployment = $true
    }

    New-AzResourceGroupDeployment @opts -verbose   
}