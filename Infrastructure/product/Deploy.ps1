param (
	[Parameter(Mandatory=$true)]
    [string]    $ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]    $ResourceLocation,

    [Parameter(Mandatory=$true)]
    [string]    $ApiManagementName,

    [Parameter(Mandatory=$true)]
    [string]    $primaryBackendUrl,

    [Parameter(Mandatory=$false)]
    [string]    $SecondaryBackendUrl,

    [Parameter(Mandatory=$false)]
    [string]    $SecondaryRegion
)  

if([string]::IsNullOrEmpty($SecondaryBackendUrl)) {
    $SecondaryBackendUrl = $PrimaryBackendUrl
}

if([string]::IsNullOrEmpty($SecondaryRegion)) {
    $SecondaryRegion = "Central US"
}

$GlobalKeyPolicy = Get-Content -Raw -Path ".\policies\GlobalKeyPolicy.xml"
$GlobalKeyPolicy = $GlobalKeyPolicy.
    Replace('{{primaryBackendUrl}}', $primaryBackendUrl).
    Replace('{{secondaryBackendUrl}}', $SecondaryBackendUrl).
    Replace('{{secondaryRegion}}', $SecondaryRegion)

$CreateKeyPolicy = Get-Content -Raw -Path ".\policies\CreateKeyPolicy.xml"
$CreateKeyPolicy = $CreateKeyPolicy.
    Replace('{{primaryBackendUrl}}', $primaryBackendUrl).
    Replace('{{secondaryBackendUrl}}', $SecondaryBackendUrl).
    Replace('{{secondaryRegion}}', $SecondaryRegion)

$opts = @{
    Name                = ("Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName   = $ResourceGroupName
    TemplateFile        = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    apiManagementName   = $ApiManagementName
    primaryBackendUrl   = $PrimaryBackendUrl
    globalKeyPolicy     = $GlobalKeyPolicy
    createKeyPolicy     = $CreateKeyPolicy
}

New-AzResourcegroup -Name $ResourceGroupName -Location $ResourceLocation -Verbose
New-AzResourceGroupDeployment @opts -verbose   