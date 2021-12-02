#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -n|--name)
      appName=$2
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
    --domain)
      domainName=$2
      shift 2
      ;;
    --hostname)
      ingressUri=$2
      shift 2
      ;;
    -k|--key)
      key=$2
      shift 2
      ;;
    -c|--cert)
      cert=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./deploy_application.sh -n {App Name} -r {region} --hostname {uri} --domain {domain name} -k {TLS Key} -c {TLS Certificate} [-r {secondary region}] 
        --name(n)    - The name of the application. Should be taken from the output of ./create_infrastructure.sh script
        --region(r)  - Primary Region 
        --hostname   - The hostname of the ingress controller. Will be joined with --domain flag to form fully qualified domain name  Example: api.ingress 
        --domain     - The domain name for the application. Example: bjd.demo
        --region(r)  - Additional regions defined to deploy application
        --key(k)     - The path to the certificate private key file in PEM format
        --cert(c)    - The path to the certificate file in PEM format
      "
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

/etc/init.d/docker status >> /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo Docker is not running. Must start it as root.
  sudo /etc/init.d/docker start
fi

acrAccountName=acr${appName}001
cosmosDBAccountName=db${appName}001
appInsightsName=ai${appName}001
eventHub=events

version=`git rev-parse HEAD | fold -w 8 | head -n1`

az account show  >> /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  az login
fi

if [[ -z "${regions[0]}" ]]; then
  echo "This script requires at least one region defined"
  exit 1
fi 
primary=${regions[0]}

#Set Global RG Name
rgGlobal="${appName}_Global_RG"

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

cd Source/changefeedprocessor
docker build -t ${acrAccountName}.azurecr.io/cqrs/changefeedprocessor:${version} .
docker push ${acrAccountName}.azurecr.io/cqrs/changefeedprocessor:${version} 
cd ${cwd}

## Get Cosmos Connection String
#cosmosConnectionString=`az cosmosdb list-connection-strings -n ${cosmosDBAccountName} -g ${rgGlobal} --query 'connectionStrings[0].connectionString' -o tsv`
cosmosConnectionString=`az cosmosdb keys list --type connection-strings -n ${cosmosDBAccountName} -g ${rgGlobal} --query 'connectionStrings[0].connectionString' -o tsv`
cosmosEncoded=`echo -n ${cosmosConnectionString} | base64 -w 0`

## Get Application Insight Key
instrumentationKey=`az monitor app-insights component  show --app ${appInsightsName} -g ${rgGlobal} --query instrumentationKey -o tsv`
instrumentationKeyEncoded=`echo -n ${instrumentationKey} | base64 -w 0`

tlsCertData=`cat ${cert} | base64 -w 0`
tlsSecretData=`cat ${key} | base64 -w 0`

cd Deployment

count=1
for region in ${regions[@]}
do

  RG="${appName}_${region}_RG"

  eventHubNameSpace=hub${appName}00${count}
  redisName=cache${appName}00${count}
  aks=k8s${appName}00${count}
  storageAccountName=sa${appName}00${count}

  ## Get Redis Connection String
  redisKey=`az redis list-keys  -g ${RG} -n ${redisName} -o tsv --query primaryKey`
  redisConnectionString=${redisName}.redis.cache.windows.net:6380,password=${redisKey},ssl=True,abortConnect=False
  redisEncoded=`echo -n ${redisConnectionString} | base64 -w 0`

  ## Get Azure Storage Connection String
  storageKey=`az storage account keys list -n ${storageAccountName} --query '[0].value' -o tsv`
  storageConnectionString="DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageKey}"
  storageEncoded=`echo -n "${storageConnectionString};EndpointSuffix=core.windows.net" | base64 -w 0`

  ## Get Event Hub Connection String 
  ehConnectionString=`az eventhubs namespace authorization-rule keys list -g ${RG} --namespace-name ${eventHubNameSpace} --name RootManageSharedAccessKey -o tsv --query primaryConnectionString`
  eventHubEncoded=`echo -n "${ehConnectionString};EntityPath=${eventHub}" | base64 -w 0`

  ## Switch K8S Context 
  az aks get-credentials -n ${aks} -g ${RG} 

  if [[ $? -eq 0 ]]; then
    ## Install Traefik Ingress 
    helm repo add traefik https://helm.traefik.io/traefik    
    helm upgrade -i traefik traefik/traefik -f  ../Infrastructure/traefik/values.yaml --wait
         
    ## Install Keda
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    kubectl create namespace keda
    helm upgrade -i keda kedacore/keda --namespace keda --version 2.0.0

    ## Install Kured 
    helm repo add kured https://weaveworks.github.io/kured
    helm repo update
    helm upgrade -i kured kured/kured -n kured --create-namespace

    #Region encoding
    regionEncoded=`echo -n ${region} | base64 -w 0`
    
    #Install App
    helm upgrade --install \
      --set acr_name=${acrAccountName} \
      --set AzureWebJobsStorage=${storageEncoded} \
      --set EVENTHUB_CONNECTIONSTRING=${eventHubEncoded} \
      --set COSMOSDB_CONNECTIONSTRING=${cosmosEncoded} \
      --set REDISCACHE_CONNECTIONSTRING=${redisEncoded} \
      --set APPINSIGHTS_INSTRUMENTATIONKEY=${instrumentationKeyEncoded} \
      --set LEASE_COLLECTION_PREFIX=${regionEncoded} \
      --set api_version=${version} \
      --set eventprocessor_version=${version} \
      --set changefeedprocessor_version=${version} \
      --set uri=${ingressUri}.${domainName} \
      --set tlsCertificate=${tlsCertData} \
      --set tlsSecret=${tlsSecretData} \
      cqrs .

    #Create DNS records for Ingress
    ip=`kubectl get service traefik -o jsonpath={.status.loadBalancer.ingress[].ip}`
    az network private-dns record-set a add-record --record-set-name ${ingressUri} --zone-name ${domainName}  -g ${RG} -a ${ip}
  fi

  count=$((count+1))
done






