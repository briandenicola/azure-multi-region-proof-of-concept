param (
    [Parameter(Mandatory = $true)]
    [string]           $ApplicationName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multi")]
    [string]          $DeploymentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]          $PFXPath,
    
    [Parameter(Mandatory = $true)]
    [securestring]    $PFXPassword,

    [Parameter(Mandatory = $true)]
    [string] $DomainName,

    [Parameter(Mandatory = $true)]
    [string[]] $BackendHostNames

)  

Import-Module -Name bjd.Azure.Functions
$pfxEncoded = Convert-CertificatetoBase64 -CertPath $PFXPath

$TemplateFile = "azuredeploy.{0}-region.json" -f $DeploymentType
$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$AppGatewayName = "appgw-{0}" -f $ApplicationName

$opts = @{
    Name                      = ("AppGateway-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName         = $ResourceGroupName
    TemplateFile              = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    TemplateParameterFile     = (Join-Path -Path $PWD.Path -ChildPath $TemplateFile)
    appGatewayName            = $AppGatewayName
    domainCertificateData     = $pfxEncoded
    domainCertificatePassword = $PFXPassword
    primaryBackendEndFQDN     = $BackendHostNames[0] + "." + $DomainName
}

if ($DeploymentType -eq "multi") {
    if ($BackendHostNames.Length -eq 1 ) {
        throw "Need to provide two Backend Host Names if using multiple regions..."
        exit -1
    }
    $opts.Add("secondaryBackendEndFQDN", ($BackendHostNames[1] + "." + $DomainName))
}
New-AzResourceGroupDeployment @opts -verbose