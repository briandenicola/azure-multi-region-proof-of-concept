param (
    [Parameter(Mandatory = $true)]
    [string]    $ApplicationName,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { [system.uri]::IsWellFormedUriString($_, [System.UriKind]::Absolute) })]
    [string]    $primaryBackendUrl
    
)  

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$ApiMgmtName       = "{0}-apim" -f $ApplicationName

# Read policy files
$GlobalKeyPolicy = Get-Content -Raw -Path ".\policies\GlobalKeyPolicy.xml"
$RateLimitPolicy = Get-Content -Raw -Path ".\policies\RateLimitPolicy.xml"
$MockPolicy      = Get-Content -Raw -Path ".\policies\MockPolicy.xml"
$CreateKeyPolicy = Get-Content -Raw -Path ".\policies\CreateKeyPolicy.xml"

$deploymentName = "Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss")
$templateFile = Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json"

# Build parameters JSON for the deployment
$opts = @{
    apiManagementName = @{ value = $ApiMgmtName }
    primaryBackendUrl = @{ value = $primaryBackendUrl }
    globalKeyPolicy = @{ value = $GlobalKeyPolicy }
    createKeyPolicy = @{ value = $CreateKeyPolicy }
    rateLimitPolicy = @{ value = $RateLimitPolicy }
    mockPolicy = @{ value = $MockPolicy }
}

# Convert WAF parameters to JSON
$parameterFile = @{}
$parameterFile.'$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
$parameterFile.contentVersion = "1.0.0.0"
$parameterFile.parameters = $opts
$parameterFile | ConvertTo-Json | Out-File -FilePath "params.json" -Encoding utf8

# Deploy using Azure CLI
Write-Host "Starting product deployment with Azure CLI..."
az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file $templateFile `
    --parameters "@params.json" `
    --verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host "Product deployment completed successfully!" -ForegroundColor Green
}
else {
    Write-Error "Product deployment failed. Exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}