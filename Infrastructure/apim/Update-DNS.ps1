param(
    [Parameter(Mandatory=$true)]
    [string] $AppName,
    [Parameter(Mandatory=$true)]
    [string] $ApiMgmtName,
    [Parameter(Mandatory=$true)]
    [string] $DomainName,
    [Parameter(Mandatory=$true)]
    [string[]] $Uris
)

function Get-AzureRegion{
    param(
        [string] $location
    )
    return ($location -replace " ","").ToLower()
}

$mandatoryUri = @("management", "portal", "developer", "management.scm")

$globalResourceGroup = "{0}_global_rg" -f $AppName

$apim = Get-AzApiManagement -ResourceGroupName $globalResourceGroup -n $ApiMgmtName

$primaryRegion = Get-AzureRegion $apim.Location
$primaryResourceGroup = "{0}_{1}_rg" -f $AppName, $primaryRegion
foreach( $uri in ($mandatoryUri + $uris)) {
    $ip = New-AzPrivateDnsRecordConfig -IPv4Address $apim.PrivateIPAddresses[0]
    New-AzPrivateDnsRecordSet -Name $uri -RecordType A -ZoneName $DomainName  -ResourceGroupName $primaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip
}

foreach($region in $apim.AdditionalRegions) {
    $secondaryResourceGroup = "{0}_{1}_rg" -f $AppName, (Get-AzureRegion -location $region.Location)
    foreach( $uri in $Uris) {
        $ip = New-AzPrivateDnsRecordConfig -IPv4Address $region.PrivateIPAddresses[0]
        New-AzPrivateDnsRecordSet -Name $uri -RecordType A -ZoneName $DomainName  -ResourceGroupName $secondaryResourceGroup -Ttl 3600 -PrivateDnsRecords $ip            
    }
}
