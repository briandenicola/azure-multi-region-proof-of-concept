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
$PFXEncodedPassword = ConvertTo-SecureString -String $PFXPassword -AsPlainText -Force

$opts = @{
    Name                            = ("ApiManagement-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName               = $ResourceGroupName
    TemplateFile                    = (Join-Path -Path $PWD.Path -ChildPath ("azuredeploy.{0}-region.json" -f $DeploymentType))
    apiManagementName               = $ApiMgmtName
    customDomain                    = $ApimRootDomainName
    customDomainCertificateData     = $pfxEncoded
    customDomainCertificatePassword = $PFXEncodedPassword
    primaryProxyFQDN                = $AllApimGatewayUrls[0]
    multiRegionDeployment           = $false
    primaryVnetName                 = ("{0}-{1}-vnet"     -f $ApplicationName, $AllRegions[0])
    primaryVnetResourceGroup        = ("{0}_{1}_infra_rg" -f $ApplicationName, $AllRegions[0])
}

if ($DeploymentType -eq "multiregion")
{
    if ($ApimProxies.Length -eq 1 ) 
    {
        throw "Need to provide two Backend Host Names if using multiple regions..."
        exit -1
    }
    $opts.secondaryLocation  = $Regions[1]
    $opts.secondaryProxyFQDN = $AllApimGatewayUrls[1]
    $opts.secondaryVnetName  =  ("{0}-{1}-vnet" -f $ApplicationName, $AllRegions[1])
    $opts.secondaryVnetResourceGroup = ("{0}_{1}_infra_rg" -f $ApplicationName, $AllRegions[1])
    $opts.multiRegionDeployment = $true
}

New-AzResourceGroupDeployment @opts -verbose

if ($?) 
{

    $apim                   = Get-AzApiManagement -ResourceGroupName $ResourceGroupName -n $ApiMgmtName
    $primaryRegion          = Get-AzureRegion $apim.Location
    $primaryResourceGroup   = "{0}_{1}_infra_rg" -f $ApplicationName, $primaryRegion

    foreach ( $uri in $ApimGatewayUrls ) 
    {
        $h = Get-HostName -Uri $uri -RootDomain $DNSZone
        $ip = New-AzPrivateDnsRecordConfig -IPv4Address $apim.PrivateIPAddresses[0]
        New-AzPrivateDnsRecordSet -Name $h -RecordType A -ZoneName $DNSZone  -ResourceGroupName $primaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip
    }

    foreach ( $uri in $ManagementUris ) 
    {
        $h = Get-HostName -Uri ("{0}.{1}" -f $uri, $ApimRootDomainName) -RootDomain $DNSZone
        $ip = New-AzPrivateDnsRecordConfig -IPv4Address $apim.PrivateIPAddresses[0]
        New-AzPrivateDnsRecordSet -Name $h -RecordType A -ZoneName $DNSZone -ResourceGroupName $primaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip
    }

    foreach ($region in $apim.AdditionalRegions) 
    {
        $secondaryResourceGroup = "{0}_{1}_infra_rg" -f $ApplicationName, (Get-AzureRegion -location $region.Location)        
        foreach ( $uri in $AllApimGatewayUrls ) 
        {
            $h = Get-HostName -Uri $uri -RootDomain $DNSZone
            $ip = New-AzPrivateDnsRecordConfig -IPv4Address $region.PrivateIPAddresses[0]
            New-AzPrivateDnsRecordSet -Name $h -RecordType A -ZoneName $DNSZone -ResourceGroupName $secondaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip            
        }
    }
}