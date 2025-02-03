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
    [String]          $PFXPassword,

    [Parameter(Mandatory = $true)]
    [String]                $BackendHostNames

)  

$AllRegions           = @($Regions | ConvertFrom-Json)
$AllBackendHostNames  = @($BackendHostNames | ConvertFrom-Json)

$pfxEncoded         = [convert]::ToBase64String( (Get-Content -AsByteStream -Path $PFXPath) )
$ResourceGroupName  = "{0}_appgw_rg" -f $ApplicationName
$AppGatewayName     = "{0}-gw"       -f $ApplicationName
$PFXEncodedPassword = ConvertTo-SecureString -String $PFXPassword -AsPlainText -Force
$opts = @{
    Name                            = ("AppGateway-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName               = $ResourceGroupName
    TemplateFile                    = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    appGatewayName                  = $AppGatewayName
    domainCertificateData           = $pfxEncoded
    domainCertificatePassword       = $PFXEncodedPassword
    primaryBackendEndFQDN           = $AllBackendHostNames[0]
    multiRegionDeployment           = $false
    primaryVnetName                 = ("{0}-{1}-vnet" -f $ApplicationName, $AllRegions[0])
    primaryVnetResourceGroup        = ("{0}_{1}_infra_rg" -f $ApplicationName, $AllRegions[0])
}

if ($DeploymentType -eq "multiregion") {
    if ($BackendHostNames.Length -eq 1 ) {
        throw "Need to provide two Backend Host Names if using multiple regions..."
        exit -1
    }
    $opts.secondaryBackendEndFQDN = $AllBackendHostNames[1]
    $opts.secondaryLocation  = $Regions[1]
    $opts.secondaryVnetName  = ("{0}-{1}-vnet" -f $ApplicationName, $AllRegions[1])
    $opts.secondaryVnetResourceGroup = ("{0}_{1}_infra_rg" -f $ApplicationName, $AllRegions[1])
    $opts.multiRegionDeployment = $true
}
New-AzResourceGroupDeployment @opts -verbose