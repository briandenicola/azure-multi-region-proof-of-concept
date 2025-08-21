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

$AllRegions = @($Regions | ConvertFrom-Json)
$AllBackendHostNames = @($BackendHostNames | ConvertFrom-Json)

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$FrontDoorName = "afd-{0}" -f $ApplicationName 

Read-Host -Prompt ("Ensure that a CNAME DNS record exists that maps {0} to {1}.z01.azurefd.net..." -f $FrontDoorUri, $FrontDoorName)

$deploymentName = "FrontDoor-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss")
$templateFile = Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json"

# Build parameters JSON for Front Door deployment
$opts = @{
    frontDoorName         = @{ value = $FrontDoorName }
    frontDoorUrl          = @{ value = $FrontDoorUri }
    primaryBackendEndFQDN = @{ value = $AllBackendHostNames[0] }
}

if ($DeploymentType -eq "multiregion") {
    $opts.secondaryBackendEndFQDN = @{ value = $AllBackendHostNames[1] }
}

# Convert parameters to JSON
$parameterFile = @{}
$parameterFile.'$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
$parameterFile.contentVersion = "1.0.0.0"
$parameterFile.parameters = $opts
$parameterFile | ConvertTo-Json | Out-File -FilePath "params.json" -Encoding utf8

# Deploy Front Door using Azure CLI
Write-Host "Starting Front Door deployment with Azure CLI..."
$frontDoorResultJson = az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file $templateFile `
    --parameters "@params.json" `
    --output json `
    --verbose

if ($LASTEXITCODE -ne 0) {
    Write-Error "Front Door deployment failed. Exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Front Door deployment completed successfully!" -ForegroundColor Green

# Deploy WAF Policies if requested
if ($DeployWAFPolicies) {
    Write-Host "Starting WAF Policies deployment..."
    
    # Parse Front Door deployment result to get outputs
    $frontDoorResult = $frontDoorResultJson | ConvertFrom-Json
    $frontDoorId = $frontDoorResult.properties.outputs.FrontDoorID.value


    for ($i = 0; $i -lt $AllRegions.Length; $i++) {
        $region = $AllRegions[$i]
        $DeploymentName = "AppGateway-WAF-Deployment-{0}-{1}" -f $region, $(Get-Date).ToString("yyyyMMddhhmmss")
        $TemplateFile = Join-Path -Path $PWD.Path -ChildPath ".\appgw-waf-policies\azuredeploy.json"
        $ParameterFilePath = Join-Path -Path $PWD.Path -ChildPath ".\appgw-waf-policies\params-$region.json"
        $AppGatewayName = "{0}-{1}-gw" -f $ApplicationName, $region
        $AppGatewayRGName = "{0}_{1}_infra_rg" -f $ApplicationName, $region

        # Build parameters JSON for WAF deployment
        $wafDeploymentParams = @{
            AzureFrontDoorID = @{ value = $frontDoorId }
            AppGatewayName   = @{ value = $AppGatewayName }
        }

        # Convert WAF parameters to JSON
        $parameterFile = @{}
        $parameterFile.'$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
        $parameterFile.contentVersion = "1.0.0.0"
        $parameterFile.parameters = $wafDeploymentParams
        $parameterFile | ConvertTo-Json | Out-File -FilePath $ParameterFilePath -Encoding utf8
    
        # Deploy WAF policies using Azure CLI
        az deployment group create `
            --name $DeploymentName `
            --resource-group $AppGatewayRGName `
            --template-file $TemplateFile `
            --parameters "@$ParameterFilePath" `
            --verbose

        if ($LASTEXITCODE -eq 0) {
            Write-Host "WAF Policies deployment completed successfully!" -ForegroundColor Green
        }
        else {
            Write-Error "WAF Policies deployment failed. Exit code: $LASTEXITCODE"
            exit $LASTEXITCODE
        }
    }
}
else {
    Write-Host "WAF Policies deployment skipped (DeployWAFPolicies not specified)" -ForegroundColor Yellow
}