param (
    [Parameter(Mandatory = $true)]
    [string]            $ApplicationName,

    [Parameter(Mandatory = $true)]
    [string[]]          $Regions,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multi")]
    [string]            $DeploymentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]            $PFXPath,
    
    [Parameter(Mandatory = $true)]
    [securestring]      $PFXPassword,

    [Parameter(Mandatory = $true)]
    [string[]]          $ApimProxies
)  

function Get-UriComponents
{
    param(
        [string] $Uri
    )
    $uriStr = [string]::Concat( [system.Uri]::UriSchemeHttp, [system.uri]::SchemeDelimiter, $uri)
    $c = ([System.Uri]::new($uriStr)).Host.Split(".")

    return (New-Object psobject -Property @{
        DomainName = [string]::join(".",$c[-2..-1])
        HostName = [string]::join(".", $c[0..($c.Length-3)])
    })
}

function Get-AzureRegion 
{
    param(
        [string] $location
    )
    return ($location -replace " ", "").ToLower()
}

Import-Module -Name bjd.Azure.Functions

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$ApiMgmtName       = "{0}-apim" -f $ApplicationName
$ManagementUris    = @("management", "portal", "developer", "management.scm")
$ManagementDomain  = (Get-UriComponents -Uri $ApimProxies[0])
$pfxEncoded        = Convert-CertificatetoBase64 -CertPath $PFXPath

$opts = @{
    Name                            = ("ApiManagement-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName               = $ResourceGroupName
    TemplateFile                    = (Join-Path -Path $PWD.Path -ChildPath ("azuredeploy.{0}-region.json" -f $DeploymentType))
    apiManagementName               = $ApiMgmtName
    customDomain                    = $ManagementDomain.DomainName
    customDomainCertificateData     = $pfxEncoded
    customDomainCertificatePassword = $PFXPassword
    primaryProxyFQDN                = $ApimProxies[0]
    multiRegionDeployment           = $false
    primaryVnetName                 = ("{0}-{1}-vnet" -f $ApplicationName, $Regions[0])
    primaryVnetResourceGroup        = ("{0}_{1}_rg" -f $ApplicationName, $Regions[0])
}

if ($DeploymentType -eq "multi") {
    if ($ApimProxies.Length -eq 1 ) {
        throw "Need to provide two Backend Host Names if using multiple regions..."
        exit -1
    }
    $opts.secondaryLocation  = $Regions[1]
    $opts.secondaryProxyFQDN = $ApimProxies[1]
    $opts.secondaryVnetName  =  ("{0}-{1}-vnet" -f $ApplicationName, $Regions[1])
    $opts.secondaryVnetResourceGroup = ("{0}_{1}_rg" -f $ApplicationName, $Regions[1])
    $opts.multiRegionDeployment = $true
}
New-AzResourceGroupDeployment @opts -verbose

if ($?) {
    $apim = Get-AzApiManagement -ResourceGroupName $ResourceGroupName -n $ApiMgmtName

    $primaryRegion = Get-AzureRegion $apim.Location
    $primaryResourceGroup = "{0}_{1}_rg" -f $ApplicationName, $primaryRegion

    foreach ( $uri in $ApimProxies ) {
        $h = Get-UriComponents -Uri $uri
        $ip = New-AzPrivateDnsRecordConfig -IPv4Address $apim.PrivateIPAddresses[0]
        New-AzPrivateDnsRecordSet -Name $h.HostName -RecordType A -ZoneName $h.DomainName  -ResourceGroupName $primaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip
    }

    foreach ( $managementUri in $ManagementUris ) {
        $ip = New-AzPrivateDnsRecordConfig -IPv4Address $apim.PrivateIPAddresses[0]
        New-AzPrivateDnsRecordSet -Name $managementUri -RecordType A -ZoneName $ManagementDomain.DomainName -ResourceGroupName $primaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip
    }

    foreach ($region in $apim.AdditionalRegions) {
        $secondaryResourceGroup = "{0}_{1}_rg" -f $ApplicationName, (Get-AzureRegion -location $region.Location)        
        foreach ( $uri in $ApimProxies ) {
            $h = Get-UriComponents -Uri $uri
            $ip = New-AzPrivateDnsRecordConfig -IPv4Address $region.PrivateIPAddresses[0]
            New-AzPrivateDnsRecordSet -Name $h.HostName -RecordType A -ZoneName $h.DomainName -ResourceGroupName $secondaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip            
        }
    }
}