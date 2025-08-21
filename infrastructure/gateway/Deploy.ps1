param (
    [Parameter(Mandatory = $true)]
    [String]                $ApplicationName,

    [Parameter(Mandatory = $true)]
    [String]                $Regions,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multiregion")]
    [String]                $DeploymentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [String]                $PFXPath,
    
    [Parameter(Mandatory = $true)]
    [String]                $PFXPassword,

    [Parameter(Mandatory = $true)]
    [String]                $BackendHostNames,

    [Parameter(Mandatory = $true)]
    [String]                $AppGatewayUrls
)  

$AllRegions           = @($Regions | ConvertFrom-Json)
$AllBackendHostNames  = @($BackendHostNames | ConvertFrom-Json)
$AllAppGatewayUrls    = @($AppGatewayUrls | ConvertFrom-Json)
$pfxEncoded           = [convert]::ToBase64String( (Get-Content -AsByteStream -Path $PFXPath) )

for($i = 0; $i -lt $AllRegions.Length; $i++) {
    $region               = $AllRegions[$i]
    $ResourceGroupName    = "{0}_{1}_infra_rg" -f $ApplicationName, $region
    $DeploymentName       = "AppGateway-Deployment-{0}-{1}" -f $region, $(Get-Date).ToString("yyyyMMddhhmmss")
    $TemplateFilePath     = Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json"
    $ParameterFilePath    = Join-Path -Path $PWD.Path -ChildPath "params-$region.json"
    $AppGatewayName       = "{0}-{1}-gw" -f $ApplicationName, $region

    $vnetName            = "{0}-{1}-vnet"     -f $ApplicationName, $region
    $vnetResourceGroup   = "{0}_{1}_vnet_rg" -f $ApplicationName, $region

    # Build parameters JSON for the deployment
    $opts = @{
        appGatewayName              = @{ value = $AppGatewayName }
        domainCertificateData       = @{ value = $pfxEncoded }
        domainCertificatePassword   = @{ value = $PFXPassword }
        backendEndFQDN              = @{ value = $AllBackendHostNames[$i] }
        vnetName                    = @{ value = $vnetName }
        vnetResourceGroup           = @{ value = $vnetResourceGroup }
    }

    # Convert WAF parameters to JSON
    $parameterFile = @{}
    $parameterFile.'$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    $parameterFile.contentVersion = "1.0.0.0"
    $parameterFile.parameters = $opts
    $parameterFile | ConvertTo-Json | Out-File -FilePath $ParameterFilePath -Encoding utf8

    # Deploy using Azure CLI
    Write-Host "Starting App Gateway deployment with Azure CLI..."
    $deploymentResultJson = az deployment group create `
        --name $DeploymentName `
        --resource-group $ResourceGroupName `
        --template-file $TemplateFilePath `
        --parameters "@$ParameterFilePath" `
        --verbose

    if ($LASTEXITCODE -eq 0) {
        $deploymentResult = $deploymentResultJson | ConvertFrom-Json
        $outputs = $deploymentResult.properties.outputs

        if ($outputs.PublicIPAddress) {
            $PublicIP = $outputs.PublicIPAddress.value
            Write-Host "Please create an 'A' DNS record pointing '$($AllAppGatewayUrls[$i])' to '$PublicIP'" -ForegroundColor Yellow
        }
    }
}
