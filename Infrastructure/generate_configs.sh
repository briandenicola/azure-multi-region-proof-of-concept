#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -g|--resource-group)
      RG=$2
      shift 2
      ;;
    -s|--subscription)
      subscription=$2
      shift 2
      ;;
    -n|--name)
      appName=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./generate_configmap.sh -n {App Name} -g {Resource Group} -s {Subscription Name}"
      exit 0
      ;;
    --) 
      shift
      break
      ;;
    -*|--*=) 
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

#Add extensions
az extension add --name application-insights

cosmosDBAccountName=db${appName}001
eventHubNameSpace=hub${appName}001
redisName=cache${appName}001
storageAccountName=${appName}sa001
appInsightsName=ai${appName}001

az account show  >> /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  az login
fi

#Get Subscription Id
az account set -s ${subscription}
subId=`az account show -o tsv --query id`

## Get Cosmos Connection String
cosmosConnectionString=`az cosmosdb list-connection-strings -n ${cosmosDBAccountName} -g ${RG} --query 'connectionStrings[0].connectionString' -o tsv`
cosmosEncoded=`echo -n ${cosmosConnectionString} | base64 -w 0`

## Get Event Hub Connection String 
ehConnectionString=`az eventhubs namespace authorization-rule keys list -g ${RG} --namespace-name ${eventHubNameSpace} --name RootManageSharedAccessKey -o tsv --query primaryConnectionString`
eventHubEncoded=`echo -n ${ehConnectionString} | base64 -w 0`

## Get Redis Connection String
redisKey=`az redis list-keys  -g ${RG} -n ${redisName} -o tsv --query primaryKey`
redisConnectionString=${redisName}.redis.cache.windows.net:6380,password=${redisKey},ssl=True,abortConnect=False
redisEncoded=`echo -n ${redisConnectionString} | base64 -w 0`

## Get Azure Storage Connection String
storageKey=`az storage account keys list -n ${storageAccountName} --query '[0].value' -o tsv`
storageConnectionString="DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageKey}"
storageEncoded=`echo -n ${storageConnectionString} | base64 -w 0`

## Get Application Insight Key
instrumentationKey=`az monitor app-insights component  show --app ${appInsightsName} -g ${RG} --query instrumentationKey -o tsv`
instrumentationKeyEncoded=`echo -n ${instrumentationKey} | base64 -w 0`

#Set localSettings Secret for Azure Functions 
read -d '' configMap << EOF
apiVersion: v1
kind: Secret
metadata:
  name: cqrssecrets
  namespace: default
data:
  AzureWebJobsStorage: ${storageEncoded}            
  FUNCTIONS_WORKER_RUNTIME: ZG90bmV0                
  EVENTHUB_CONNECTIONSTRING: ${eventHubEncoded}     
  COSMOSDB_CONNECTIONSTRING: ${cosmosEncoded}       
  REDISCACHE_CONNECTIONSTRING: ${redisEncoded} 
  APPINSIGHTS_KEY: ${instrumentationKeyEncoded}    
EOF
echo Generating Kubernetes ConfigMap YAML - configmap.yaml
echo -e "${configMap}" > ./configmap.yaml
echo ------------------------------------

#Set localSettings Secret for Azure Functions 
read -d '' localSettings << EOF
{ 
  \"IsEncrypted\": false, 
  \"Values\": { 
        \"AzureWebJobsStorage\": \"${storageConnectionString}\",        
        \"FUNCTIONS_WORKER_RUNTIME\": \"dotnet\",                       
        \"EVENTHUB_CONNECTIONSTRING\": \"${ehConnectionString}\",       
        \"COSMOSDB_CONNECTIONSTRING\": \"${cosmosConnectionString}\",   
        \"REDISCACHE_CONNECTIONSTRING\": \"${redisConnectionString}\"
        \"APPINSIGHTS_KEY\": \"${instrumentationKey}\"
    } 
} 
EOF
echo Generating Azure Functions Settings File - local.settings.json
echo -e "${localSettings}" > ./local.settings.json
