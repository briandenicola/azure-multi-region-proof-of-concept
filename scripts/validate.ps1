<#
.SYNOPSIS
This PowerShell Script will exec into a utils container to validate the CQRS application.

.DESCRIPTION
Version - 1.0.0
This PowerShell Script will exec into a utils container to validate the CQRS application.

.EXAMPLE
./validate.ps1 -DomainName bjd.demo -ResourceGroupName quetzal-8233_westus3_rg

.PARAMETER DomainName
The Domain Name that will be used by the Ingress Controller to terminate TLS. Mandatory parameter

#>
param(
  [Parameter(Mandatory=$true)]
  [String]            $DomainName,

  [Parameter(Mandatory = $true)]
  [String]            $ResoureGroupName
)

$utilsContainerName = "utils"

Write-Host "...."
Write-Host "Running arbitrary commands with options is not supported by `'az containerapp exec`'."
Write-Host "This script will exec into the ${utilsContainerName} and execute bash".Length
Write-Host "Copy and past the following curl commands to validate the CQRS application."
Write-Host "curl -s https://api-internal.${DomainName}/healthz" -ForegroundColor Green
Write-Host "curl -s --header `"Content-Type: application/json`" --data `'{`"NumberOfKeys`":10}`' https://api-internal.${DomainName}/api/keys | jq" -ForegroundColor Green
Write-Host ""
Write-Host "Pick one of the ids from the above command and then run the following command:"
Write-Host "export keyid=<id from above" -ForegroundColor Green
Write-Host "curl -s --header `"Content-Type: application/json`" https://api-internal.${DomainName}/api/keys/`${keyid} | jq" -ForegroundColor Green
Write-Host "exit" -ForegroundColor Green
Write-Host "...."

az containerapp exec --name ${utilsContainerName} --resource-group ${ResoureGroupName} --command bash

