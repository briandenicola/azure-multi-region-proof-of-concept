param (
	[Parameter(Mandatory=$true)]
    [string]    $ApplicationName,

    [Parameter(Mandatory=$true)]
    [ValidateSet("single","multi")]
    [string]    $DeploymentType,

    [Parameter(Mandatory=$true)]
    [string]    $DomainName,

    [Parameter(Mandatory=$true)]
    [string[]]  $BackendHostNames,

    [Parameter(Mandatory=$false)]
    [switch]    $DeployWAFPolicies
)  

$ResourceGroupName = "{0}_global_rg" -f $ApplicationName
$FrontDoorName = "fd-{0}" -f $ApplicationName 

$opts = @{
    Name                    = ("FrontDoor-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
    ResourceGroupName       = $ResourceGroupName
    TemplateFile            = (Join-Path -Path $PWD.Path -ChildPath "azuredeploy.json")
    frontDoorName           = $FrontDoorName
    frontDoorUrl            = ("api.{0}" -f $DomainName)
    primaryBackendEndFQDN   = ($BackendHostNames[0] + "." + $DomainName)
}

if($DeploymentType -eq "multi") {
    if($BackendHostNames.Length -eq 1 ) {
        throw "Need to provide two Backend Host Names if using multiple regions..."
        exit -1
    }
    $opts.Add("secondaryBackendEndFQDN", ($BackendHostNames[1] + "." + $DomainName))
}

New-AzResourceGroupDeployment @opts -verbose

if($DeployWAFPolicies) {
    $frontDoorId = Read-Host -Prompt "Enter the Front Door ID that was output above"

    $opts = @{
        Name                = ("WAF-Deployment-{0}-{1}" -f $ResourceGroupName, $(Get-Date).ToString("yyyyMMddhhmmss"))
        ResourceGroupName   = $ResourceGroupName
        TemplateFile        = (Join-Path -Path $PWD.Path -ChildPath ".\appgw-waf-policies\azuredeploy.json")
        AzureFrontDoorID    = $frontDoorId
    }

    New-AzResourceGroupDeployment @opts -verbose   
}