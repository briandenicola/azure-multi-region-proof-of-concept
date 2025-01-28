#!/usr/bin/pwsh

[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,
  
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $ACRName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $CommitVersion,

    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $SourceRootPath
)

function Write-Log 
{
    param( [string] $Message )
    Write-Verbose -Message ("[{0}] - {1} ..." -f $(Get-Date), $Message)
}

Set-Variable -Name apps -Value @(
    @{Name = "api"; Path = "${SourceRootPath}/api";  ContainerName="${ACRName}.azurecr.io/cqrs/api:${CommitVersion}" },
    @{Name = "eventprocessor"; Path = "${SourceRootPath}/eventprocessor";  ContainerName="${ACRName}.azurecr.io/cqrs/eventprocessor:${CommitVersion}" },
    @{Name = "changefeedprocessor"; Path = "${SourceRootPath}/changefeedprocessor"; ContainerName="${ACRName}.azurecr.io/cqrs/changefeedprocessor:${CommitVersion}" }
)

sudo /etc/init.d/docker start
az acr login -n $ACRName

foreach( $app in $apps ) {
    $DockerFile = "{0}/dockerfile" -f $app.Path
    docker build --no-cache -t $app.ContainerName -f $DockerFile $app.Path
    docker push $app.ContainerName}

if($?){
    Write-Log "Application successfully built and pushed to ${APP_ACR_NAME}. . ."
}
else {
    Write-Log ("Errors encountered while deploying application. Please review. Application Name: {0}" -f $AppName )
} 

