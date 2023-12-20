function Build-Application 
{ 
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
        [string] $AppName,
    
        [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
        [string] $SubscriptionName,

        [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
        [string] $AcrName,

        [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
        [string] $Source,

        [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
        [string] $Version

    )

    Start-Docker

    #Build Source
    Build-DockerContainers -ContainerName "${AcrName}.azurecr.io/cqrs/api:${Version}" -DockerFile "${Source}/api/dockerfile" -SourcePath "${Source}/api"
    Build-DockerContainers -ContainerName "${AcrName}.azurecr.io/cqrs/eventprocessor:${Version}" -DockerFile "${Source}/eventprocessor/dockerfile" -SourcePath "${Source}/eventprocessor"
    Build-DockerContainers -ContainerName "${AcrName}.azurecr.io/cqrs/changefeedprocessor:${Version}" -DockerFile "${Source}/changefeedprocessor/dockerfile" -SourcePath "${Source}/changefeedprocessor"
}

function Write-Log 
{
    param( [string] $Message )
    Write-Verbose -Message ("[{0}] - {1} ..." -f $(Get-Date), $Message)
}

function ConvertFrom-Base64String
{
    param( 
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Text 
    )
    return [Text.Encoding]::ASCII.GetString([convert]::FromBase64String($Text))
}

function ConvertTo-Base64EncodedString 
{
    param( 
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Text 
    )
    begin {
        $encodedString = [string]::Empty
    }
    process {
        $encodedString = [convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($Text))
    }
    end {
        return $encodedString
    }
}

function Start-UiBuild
{   
    dotnet build
    dotnet publish -c Release -o build
}

function Add-AzureCliExtensions
{
    az extension add --name application-insights -y
    az extension add --name aks-preview -y
}

function Get-AzStaticWebAppSecret
{
    param(
        [string] $Name
    )

    return (az staticwebapp secrets list --name $Name -o tsv --query "properties.apiKey")
}

function Deploy-toAzStaticWebApp
{
    param(
        [string] $Name,
        [string] $ResourceGroup,
        [string] $LocalPath
    )

    $token = Get-AzStaticWebAppSecret -Name $Name
    swa deploy --env production --app-location $LocalPath --deployment-token $token

}

function Start-Docker
{
    Write-Log -Message "Starting Docker"
    if(Get-OSType -eq "Unix") {
        sudo /etc/init.d/docker start
    }
    else {
        Start-Service -Name docker
    }
}

function Connect-ToAzure 
{
    param(
        [string] $SubscriptionName
    )

    function Get-AzTokenExpiration {
        $e = (az account get-access-token --query "expiresOn" --output tsv)
        if($null -eq $e){
            return $null
        }        
        return (Get-Date -Date $e)
    }

    function Test-ExpireToken {
        param(
            [DateTime] $Expire
        )
        return (($exp - (Get-Date)).Ticks -lt 0 )
    }

    $exp = Get-AzTokenExpiration
    if( ($null -eq $exp) -or (Test-ExpireToken -Expire $exp)) {
        Write-Log -Message "Logging into Azure"
        az login
    }

    Write-Log -Message "Setting subscription context to ${SubscriptionName}"
    az account set -s $SubscriptionName
    
}

function Connect-ToAzureContainerRepo
{
    param(
        [string] $ACRName

    )

    Write-Log -Message "Logging into ${ACRName} Azure Container Repo"
    az acr login -n $ACRName
}

function Get-GitCommitVersion
{
    Write-Log -Message "Get Latest Git commit version id"
    return (git rev-parse HEAD).SubString(0,8)
}

function Build-DockerContainers
{
    param(
        [string] $ContainerName,
        [string] $DockerFile,
        [string] $SourcePath
    )

    Write-Log -Message "Building ${ContainerName}"
    docker build --no-cache -t $ContainerName -f $DockerFile $SourcePath

    Write-Log -Message "Pushing ${ContainerName}"
    docker push $ContainerName
}