param (
    [Parameter(Mandatory = $true)]
    [string]    $ApplicationName,

    [Parameter(Mandatory = $true)]
    [string]    $FrontDoorUri,

    [Parameter(Mandatory = $true)]
    [string[]]  $BackendHostNames,

    [Parameter(Mandatory = $false)]
    [switch]    $DeployWAFPolicies,

    [Parameter(Mandatory = $true)]
    [string[]]  $Regions,

    [Parameter(Mandatory = $true)]
    [ValidateSet("single", "multi")]
    [string]    $DeploymentType
)  

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$FrontDoorName = "afd-{0}" -f $ApplicationName 

Read-Host -Prompt ("Ensure that a CNAME DNS record exists that maps {0} to {1}.z01.azurefd.net..." -f $FrontDoorUri, $FrontDoorName)

$opts = @{
    Name                  = ("FrontDoor-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName     = $ResourceGroupName
    TemplateFile          = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    frontDoorName         = $FrontDoorName
    frontDoorUrl          = $FrontDoorUri
    primaryBackendEndFQDN = $BackendHostNames[0]
}

if ($BackendHostNames.Length -eq 1 ) {
    throw "Need to provide two Backend Host Names if using multiple regions..."
    exit -1
}
$opts.secondaryBackendEndFQDN = $BackendHostNames[1]

$result = New-AzResourceGroupDeployment @opts -verbose

if ($DeployWAFPolicies) {
    #$frontDoorId = Read-Host -Prompt "Enter the Front Door ID that was output above"
    $frontdoorId = $result.Outputs["front Door ID"].Value

    $opts = @{
        Name              = ("WAF-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
        ResourceGroupName = $ResourceGroupName
        TemplateFile      = (Join-Path -Path $PWD.Path -ChildPath ".\appgw-waf-policies\azuredeploy.json")
        AzureFrontDoorID  = $frontDoorId
    }

    if ($DeploymentType -eq "multi") {
        $opts.secondaryLocation  = $Regions[1]
    }

    New-AzResourceGroupDeployment @opts -verbose   
}