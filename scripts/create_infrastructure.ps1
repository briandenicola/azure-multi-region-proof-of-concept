param(
  [Parameter(Mandatory=$true)]
  [string] $SubscriptionName,

  [Parameter(Mandatory=$true)]
  [string[]] $Regions,

  [Parameter(Mandatory=$true)]
  [string[]] $DomainName
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
#terraform plan -out="${tf_plan}" -var="locations=${Regions}" -var "custom_domain=${DomainName}" 
terraform plan -out="${tf_plan}" -var "custom_domain=${DomainName}" 
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