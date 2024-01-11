<#
.SYNOPSIS
This PowerShell Script will stand up core infrastructure for the CQRS appplication.

.DESCRIPTION
Version - 1.0.0
This PowerShell Script will stand upis PowerShell Script will stand up the infrastructure for the CQRS appplication..

.EXAMPLE
.\create_core_infrastructure.ps1 -Regions '["eastus2","ukwest"]' -DomainName bjd.demo -SubscriptionName my_subscription -IngressPfxFilePath ~/certs/apim.pfx -PFXPassword xyz

.EXAMPLE
.\create_core_infrastructure.ps1 -Regions '["eastus2"]' -DomainName bjd.demo -SubscriptionName my_subscription -IngressPfxFilePath ~/certs/apim.pfx -PFXPassword xyz

.PARAMETER Regions
Specifies the Regions used 

.PARAMETER SubscriptionName
The Subscription Name to deploy the Azure Resources. Mandatory parameter

.PARAMETER DomainName
The Domain Name that will be used by the Ingress Controller to terminate TLS. Mandatory parameter

.PARAMETER IngressPfxFilePath
The Path to the certificate that will be used by the Ingress Controller to terminate TLS. Mandatory parameter

.PARAMETER PFXPassword
The PFX Password. Mandatory parameter
#>
param(
  [Parameter(Mandatory=$true)]
  [String]            $SubscriptionName,

  [Parameter(Mandatory=$true)]
  [String]            $Regions,

  [Parameter(Mandatory=$true)]
  [String]            $DomainName,

  [Parameter(Mandatory = $true)]
  [ValidateScript( { Test-Path $_ })]
  [String]            $IngressPfxFilePath,

  [Parameter(Mandatory = $true)]
  [String]            $PFXPassword
)

$today = (Get-Date).ToString("yyyyMMdd")
$tf_plan = "cqrs.plan.{0}" -f $today

$current = $PWD.Path
$infra = Join-Path -Path ((Get-Item $PWD.Path).Parent).FullName -ChildPath "infrastructure/core"
Set-Location -Path $infra

az account set -s $SubscriptionName

terraform workspace new cqrs-infrastructure
terraform workspace select cqrs-infrastructure
terraform init
terraform plan -out="${tf_plan}" -var="locations=${Regions}" -var custom_domain=${DomainName} -var="certificate_file_path=${IngressPfxFilePath}" -var="certificate_password=${PFXPassword}"
terraform apply -auto-approve ${tf_plan}

$AppName = $(terraform output -raw APP_NAME)

if($?){
  Write-Host "------------------------------------"
  Write-Host "Infrastructure built successfully. Environment Name: ${AppName}"
  Write-Host "------------------------------------"
}
else {
  Write-Host "------------------------------------"
  Write-Host ("Errors encountered while building infrastructure. Please review terraform logs. Environment Name: ${AppName}" )
  Write-Host "------------------------------------"
}

Set-Location -Path $current