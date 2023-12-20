<#
.SYNOPSIS
This PowerShell Script will build and deploy the CQRS appplication.

.DESCRIPTION
Version - 1.0.0
This PowerShell Script will build and deploy the CQRS appplication.

.EXAMPLE
.\deploy_application.ps1 -AppName cheetah-37209 -Regions '["eastus2","ukwest"]' -DomainName bjd.demo

.EXAMPLE
.\deploy_application.ps1 -AppName cheetah-37209 -Regions '["eastus2"]' -DomainName bjd.demo -BuildOnly

.PARAMETER AppNmame
Specifies the Application Name as outputtee by the create_core_infrastructure.ps1 script

.PARAMETER Regions
Specifies the Regions used 

.PARAMETER DomainName
The Domain Name that will be used by the Ingress Controller to terminate TLS. Mandatory parameter

.PARAMETER SkipBuild
Skips the build process

.PARAMETER BuildOnly
Only builds the application and does not deploy
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $SubscriptionName,

    [Parameter(Mandatory=$true)]
    [String] $Regions,

    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $DomainName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [switch] $SkipBuild,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [switch] $BuildOnly
)

. ./modules/functions.ps1
. ./modules/naming.ps1 -AppName $AppName

Connect-ToAzure -SubscriptionName $SubscriptionName
Connect-ToAzureContainerRepo -ACRName $APP_ACR_NAME
Add-AzureCliExtensions

#Build and Push All Containers from Source 
$commit_version = Get-GitCommitVersion
if(-not $SkipBuild) {
    Build-Application -AppName $AppName -AcrName $APP_ACR_NAME -SubscriptionName $SubscriptionName -Source $APP_SOURCE_DIR -Version $commit_version
}

if($BuildOnly) { exit(0) }

#Deploy Application
$today = (Get-Date).ToString("yyyyMMdd")
$tf_plan = "cqrs.plan.{0}" -f $today

$app = Join-Path -Path ((Get-Item $PWD.Path).Parent).FullName -ChildPath "app"
Set-Location -Path $app

az account set -s $SubscriptionName

terraform workspace new cqrs-app
terraform workspace select cqrs-app
terraform init
terraform plan -out="${tf_plan}" -var="locations=${Regions}" -var="app_name=${AppName}" -var="custom_domain=${DomainName}" -var="commit_version=${commit_version}"
terraform apply -auto-approve ${tf_plan}

if($?){
    Write-Log ("{0} {1} @ {2}" -f $msg,$APP_API_URI, (Get-APIGatewayIP))
    Write-Log "Application successfully deployed. . ."
}
else {
    Write-Log ("Errors encountered while deploying application. Please review. Application Name: {0}" -f $AppName )
} 

Set-Location -Path $cwd