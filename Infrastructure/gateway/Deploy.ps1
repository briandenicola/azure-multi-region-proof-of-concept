param (
    [Parameter(Mandatory = $true)]
    [string]           $ApplicationName,

    [Parameter(Mandatory = $true)]
    [string[]]          $Regions,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multi")]
    [string]          $DeploymentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]          $PFXPath,
    
    [Parameter(Mandatory = $true)]
    [securestring]    $PFXPassword,

    [Parameter(Mandatory = $true)]
    [string[]] $BackendHostNames

)  

Import-Module -Name bjd.Azure.Functions
$pfxEncoded = Convert-CertificatetoBase64 -CertPath $PFXPath

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$AppGatewayName = "appgw-{0}" -f $ApplicationName

$opts = @{
    Name                            = ("AppGateway-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName               = $ResourceGroupName
    TemplateFile                    = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    appGatewayName                  = $AppGatewayName
    domainCertificateData           = $pfxEncoded
    domainCertificatePassword       = $PFXPassword
    primaryBackendEndFQDN           = $BackendHostNames[0]
    multiRegionDeployment           = $false
    primaryVnetName                 = ("vnet{0}001" -f $ApplicationName)
    primaryVnetResourceGroup        = ("{0}_{1}_rg" -f $ApplicationName, $Regions[0])
}

if ($DeploymentType -eq "multi") {
    if ($BackendHostNames.Length -eq 1 ) {
        throw "Need to provide two Backend Host Names if using multiple regions..."
        exit -1
    }
    $opts.secondaryBackendEndFQDN = $BackendHostNames[1]
    $opts.secondaryLocation  = $Regions[1]
    $opts.secondaryVnetName  = ("vnet{0}002" -f $ApplicationName)
    $opts.secondaryVnetResourceGroup = ("{0}_{1}_rg" -f $ApplicationName, $Regions[1])
    $opts.multiRegionDeployment = $true
}
New-AzResourceGroupDeployment @opts -verbose