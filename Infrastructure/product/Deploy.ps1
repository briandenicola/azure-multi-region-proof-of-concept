param (
	[Parameter(Mandatory=$true)]
    [string]           $ApplicationName,

    [Parameter(Mandatory=$true)]
    [ValidateScript({[system.uri]::IsWellFormedUriString($_,[System.UriKind]::Absolute)})]
    [string]    $primaryBackendUrl
    
)  

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$ApiMgmtName = "apim-{0}" -f $ApplicationName

$GlobalKeyPolicy = Get-Content -Raw -Path ".\policies\GlobalKeyPolicy.xml"
$RateLimitPolicy = Get-Content -Raw -Path ".\policies\RateLimitPolicy.xml"
$MockPolicy = Get-Content -Raw -Path ".\policies\MockPolicy.xml"

$CreateKeyPolicy = Get-Content -Raw -Path ".\policies\CreateKeyPolicy.xml"
$CreateKeyPolicy = $CreateKeyPolicy.
    Replace('{{primaryBackendUrl}}', $primaryBackendUrl)
    
$opts = @{
    Name                = ("Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName   = $ResourceGroupName
    TemplateFile        = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    apiManagementName   = $ApiMgmtName
    primaryBackendUrl   = $PrimaryBackendUrl
    globalKeyPolicy     = $GlobalKeyPolicy
    createKeyPolicy     = $CreateKeyPolicy
    rateLimitPolicy     = $RateLimitPolicy
    mockPolicy          = $MockPolicy
}
New-AzResourceGroupDeployment @opts -verbose   