#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -n|--name)
      appName=$2
      shift 2
      ;;
    -g|--resource-group)
      RG=$2
      shift 2
      ;;
    -r|--region)
      regions+=($2)
      shift 2
      ;;
    -v|--version)
      version=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./deploy_application.sh -n {App Name} -g {Resource Group} -r {region} -v {Version. Default=1.0}  [-r {secondary region}]"
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

acrAccountName=acr${appName}001
cosmosDBAccountName=db${appName}001
appInsightsName=ai${appName}001
eventHub=events

az account show  >> /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  az login
fi

if [[ -z "${version}" ]]; then
  version="1.0"
fi 

if [[ -z "${regions[0]}" ]]; then
  echo "This script requires at least one region defined"
  exit 1
fi 
primary=${regions[0]}

#Set Subscription and login into ACR
az acr login -n ${acrAccountName}

cd ..
cwd=`pwd`

cd Source/api
docker build -t ${acrAccountName}.azurecr.io/cqrs/api:${version} .
docker push ${acrAccountName}.azurecr.io/cqrs/api:${version}
cd ${cwd}

cd Source/eventprocessor
docker build -t ${acrAccountName}.azurecr.io/cqrs/eventprocessor:${version} .
docker push ${acrAccountName}.azurecr.io/cqrs/eventprocessor:${version} 
cd ${cwd}

## Get Application Insight Key
instrumentationKey=`az monitor app-insights component  show --app ${appInsightsName} -g ${RG} --query instrumentationKey -o tsv`
instrumentationKeyEncoded=`echo -n ${instrumentationKey} | base64 -w 0`

cd Deployment

count=1
for region in ${regions[@]}
do

  eventHubNameSpace=hub${appName}00${count}
  redisName=cache${appName}00${count}
  aks=k8s${appName}00${count}
  storageAccountName=${appName}sa00${count}
  searchServiceName=srch${appName}00${count}

  ## Get Azure Storage Connection String
  storageKey=`az storage account keys list -n ${storageAccountName} --query '[0].value' -o tsv`
  storageConnectionString="DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageKey}"
  storageEncoded=`echo -n "${storageConnectionString};EndpointSuffix=core.windows.net" | base64 -w 0`

  ##Search Service
  searchNameEncoded=`echo -n ${searchServiceName} | base64 -w 0`
  indexEncoded=`echo -n default | base64 -w 0`
  adminKey=`az search admin-key show --service-name ${searchServiceName} -g ${RG} --query 'primaryKey' -o tsv`
  adminKeyEncoded=`echo -n ${adminKey} | base64 -w 0`

  ## Get Event Hub Connection String 
  ehConnectionString=`az eventhubs namespace authorization-rule keys list -g ${RG} --namespace-name ${eventHubNameSpace} --name RootManageSharedAccessKey -o tsv --query primaryConnectionString`
  eventHubEncoded=`echo -n "${ehConnectionString};EntityPath=${eventHub}" | base64 -w 0`

  ## Switch K8S Context 
  kubectl config use-context ${aks}

  #Install App
  helm upgrade --install \
    --set acr_name=${acrAccountName} \
    --set AzureWebJobsStorage=${storageEncoded} \
    --set EVENTHUB_CONNECTIONSTRING=${eventHubEncoded} \
    --set APPINSIGHTS_INSTRUMENTATIONKEY=${instrumentationKeyEncoded} \
    --set api_version=${version} \
    --set eventprocessor_version=${version} \
    --set SEARCH_SERVICENAME=${searchNameEncoded} \
    --set SEARCH_ADMINKEY=${adminKeyEncoded} \
    --set SEARCH_INDEXNAME=${indexEncoded} \
    cqrs .

    count=$((count+1))
done






