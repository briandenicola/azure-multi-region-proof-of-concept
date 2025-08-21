param (
    [Parameter(Mandatory = $true)]
    [String]            $ApplicationName,

    [Parameter(Mandatory = $true)]
    [String]            $Regions,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multiregion")]
    [String]            $DeploymentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [String]            $PFXPath,
    
    [Parameter(Mandatory = $true)]
    [String]      $PFXPassword,

    [Parameter(Mandatory = $true)]
    [String]            $ApimGatewayUrls,

    [Parameter(Mandatory = $true)]
    [String]            $ApimRootDomainName,

    [Parameter(Mandatory = $true)]
    [String]            $DNSZone
)  

function Get-HostName
{
    param(
        [string] $Uri,
        [string] $RootDomain
    )

    if( $Uri -imatch "(.*).$RootDomain" ) {
        $HostName = $matches[1]
    } else {
        throw "Invalid URI: $Uri"
    }

    return $HostName
    
}

function Get-AzureRegion 
{
    param(
        [string] $location
    )
    return ($location -replace " ", "").ToLower()
}

$AllRegions            = @($Regions | ConvertFrom-Json)
$AllApimGatewayUrls    = @($ApimGatewayUrls | ConvertFrom-Json)

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$ApiMgmtName       = "{0}-apim" -f $ApplicationName
$ManagementUris    = @("management", "portal", "developer", "management.scm")
$pfxEncoded        = [convert]::ToBase64String( (Get-Content -AsByteStream -Path $PFXPath) ) 

$deploymentName = "ApiManagement-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss")
$templateFile = Join-Path -Path $PWD.Path -ChildPath ("azuredeploy.{0}-region.json" -f $DeploymentType)
$primaryVnetName = "{0}-{1}-vnet" -f $ApplicationName, $AllRegions[0]
$primaryVnetResourceGroup = "{0}_{1}_vnet_rg" -f $ApplicationName, $AllRegions[0]

# Build parameters JSON for the deployment
$opts = @{
    apiManagementName = @{ value = $ApiMgmtName }
    customDomain = @{ value = $ApimRootDomainName }
    customDomainCertificateData = @{ value = $pfxEncoded }
    customDomainCertificatePassword = @{ value = $PFXPassword }
    primaryProxyFQDN = @{ value = $AllApimGatewayUrls[0] }
    multiRegionDeployment = @{ value = "false" }
    primaryVnetName = @{ value = $primaryVnetName }
    primaryVnetResourceGroup = @{ value = $primaryVnetResourceGroup }
}

if ($DeploymentType -eq "multiregion")
{
    if ($AllApimGatewayUrls.Length -eq 1 ) 
    {
        throw "Need to provide two Backend Host Names if using multiple regions..."
        exit -1
    }
    $opts.secondaryLocation = @{ value = $AllRegions[1] }
    $opts.secondaryProxyFQDN = @{ value = $AllApimGatewayUrls[1] }
    $opts.secondaryVnetName = @{ value = ("{0}-{1}-vnet" -f $ApplicationName, $AllRegions[1]) }
    $opts.secondaryVnetResourceGroup = @{ value = ("{0}_{1}_vnet_rg" -f $ApplicationName, $AllRegions[1]) }
    $opts.multiRegionDeployment = @{ value = "true" }
}

# Convert parameters to JSON
$parameterFile = @{}
$parameterFile.'$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
$parameterFile.contentVersion = "1.0.0.0"
$parameterFile.parameters = $opts
$parameterFile | ConvertTo-Json | Out-File -FilePath "params.json" -Encoding utf8

# Deploy using Azure CLI
Write-Host "Starting APIM deployment with Azure CLI..."
az deployment group create `
    --name "$deploymentName" `
    --resource-group $ResourceGroupName `
    --template-file $templateFile `
    --parameters "@params.json" `
    --verbose

if ($LASTEXITCODE -eq 0) 
{
    Write-Host "Deployment successful. Setting up DNS records..."

    # Get APIM details using Azure CLI
    $apimJson = az apim show --name $ApiMgmtName --resource-group $ResourceGroupName --output json
    $apim = $apimJson | ConvertFrom-Json
    
    $primaryRegion = Get-AzureRegion $apim.location
    $primaryResourceGroup = "{0}_{1}_dns_zones_rg" -f $ApplicationName, $primaryRegion
    $primaryPrivateIP = $apim.privateIPAddresses[0]

    # Create DNS records for gateway URLs
    foreach ( $uri in $AllApimGatewayUrls ) 
    {
        $h = Get-HostName -Uri $uri -RootDomain $DNSZone
        Write-Host "Creating DNS record for $h -> $primaryPrivateIP"
        
        az network private-dns record-set a add-record `
            --record-set-name $h `
            --zone-name $DNSZone `
            --resource-group $primaryResourceGroup `
            --ipv4-address $primaryPrivateIP 
    }

    # Create DNS records for management URIs
    foreach ( $uri in $ManagementUris ) 
    {
        $fullUri = "{0}.{1}" -f $uri, $ApimRootDomainName
        $h = Get-HostName -Uri $fullUri -RootDomain $DNSZone
        Write-Host "Creating DNS record for $h -> $primaryPrivateIP"
        
        az network private-dns record-set a add-record `
            --record-set-name $h `
            --zone-name $DNSZone `
            --resource-group $primaryResourceGroup `
            --ipv4-address $primaryPrivateIP 
    }

    # Handle additional regions for multi-region deployment
    if ($apim.additionalLocations -and $apim.additionalLocations.Count -gt 0) 
    {
        foreach ($region in $apim.additionalLocations) 
        {
            $secondaryResourceGroup = "{0}_{1}_dns_zones_rg" -f $ApplicationName, (Get-AzureRegion -location $region.location)
            $secondaryPrivateIP = $region.privateIPAddresses[0]
            
            foreach ( $uri in $AllApimGatewayUrls ) 
            {
                $h = Get-HostName -Uri $uri -RootDomain $DNSZone
                Write-Host "Creating DNS record for $h -> $secondaryPrivateIP in secondary region"
                
                az network private-dns record-set a add-record `
                    --record-set-name $h `
                    --zone-name $DNSZone `
                    --resource-group $secondaryResourceGroup `
                    --ipv4-address $secondaryPrivateIP 
            }
        }
    }
    
    Write-Host "DNS setup completed successfully!"
}
else 
{
    Write-Error "Deployment failed. Exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}