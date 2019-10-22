#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -g|--resource-group)
      RG=$2
      shift 2
      ;;
    -l|--location)
      location=$2
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
      echo "Usage: ./create_infrastructure.sh -n {App Name} -g {Resource Group} -l {location} -s {Subscription Name}"
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

if [[ -z "${appName}" ]]; then
  appName=`cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1`
fi 

cosmosDBAccountName=db${appName}001
functionAppName=func${appName}001
eventHubNameSpace=hub${appName}001
keyVaultName=vault${appName}001
redisName=cache${appName}001
aks=k8s${appName}001
nodeRG=${RG}_nodes 
storageAccountName=${appName}sa001
acrAccountName=acr${appName}001

az account show  >> /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  az login
fi

#Get Subscription Id
az account set -s ${subscription}
subId=`az account show -o tsv --query id`

#Create Resource Group
az group create -n $RG -l $location

#Create KeyVault 
az keyvault create --name ${keyVaultName} --resource-group ${RG} --location ${location} 

#Create Cosmos
database=AesKeys
collection=Items

az cosmosdb create -g ${RG} -n ${cosmosDBAccountName} --kind GlobalDocumentDB 
az cosmosdb database create  -g ${RG} -n ${cosmosDBAccountName} -d ${database}
az cosmosdb collection create -g ${RG} -n ${cosmosDBAccountName} -d ${database} -c ${collection} --partition-key-path '/keyId'

## Set Cosmos Connection String in Key Vault
cosmosConnectionString=`az cosmosdb list-connection-strings -n ${cosmosDBAccountName} -g ${RG} --query 'connectionStrings[0].connectionString' -o tsv`
az keyvault secret set --vault-name ${keyVaultName} --name cosmosConnectionString --value ${cosmosConnectionString}

#Create Event Hub
hub=events
az eventhubs namespace create -g ${RG} -n ${eventHubNameSpace} -l ${location} --sku Standard --enable-auto-inflate --maximum-throughput-units 5 --enable-kafka
az eventhubs eventhub create -g ${RG} --namespace-name ${eventHubNameSpace} -n ${hub} --message-retention 7 --partition-count 1

## Set Event Hub Connection String in Key Vault
ehConnectionString=`az eventhubs namespace authorization-rule keys list -g ${RG} --namespace-name ${eventHubNameSpace} --name RootManageSharedAccessKey -o tsv --query primaryConnectionString`
az keyvault secret set --vault-name ${keyVaultName} --name ehConnectionString --value ${ehConnectionString}

#Create Redis Cache
az redis create  -g ${RG} -n ${redisName} -l ${location} --sku standard --vm-size c1 --minimum-tls-version 1.2   

## Set Redis Connection String in Key Vault
redisKey=`az redis list-keys  -g ${RG} -n ${redisName} -o tsv --query primaryKey`
redisConnectionString=${redisName}.redis.cache.windows.net:6380,password=${redisKey},ssl=True,abortConnect=False
az keyvault secret set --vault-name ${keyVaultName} --name redisConnectionString --value ${redisConnectionString}

#Create Azure Storage
az storage account create --name ${storageAccountName} --location $location --resource-group $RG --sku Standard_LRS
storageKey=`az storage account keys list -n ${storageAccountName} --query '[0].value' -o tsv`
storageConnectionString="DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageKey}"

#Create ACR
az acr create -n ${acrAccountName} -g ${RG} -l ${location} --sku Standard
acrid=`az acr show -n ${acrAccountName} -g ${RG} --query 'id' -o tsv`

#Create AKS
az aks create -n ${aks} -g ${RG} -l ${location} --load-balancer-sku standard --node-count 3 --node-resource-group ${nodeRG} --ssh-key-value '~/.ssh/id_rsa.pub' 
az aks update -n ${aks} -g ${RG} --enable-acr --acr ${acrid}    

## Pod Identity for AKS
vmss=`az vmss list -g ${nodeRG}`
vmssName=`echo ${vmss} | jq '.[0].name' | tr -d \"`
vmssIdentity=`az vmss identity assign -n ${vmssName} -g ${nodeRG}`
clientId=`echo ${vmssIdentity} | jq .systemAssignedIdentity | tr -d \"`
az keyvault set-policy -n ${keyVaultName} --secret-permissions get --object-id ${clientId}

## Get Pod Credentials 
az aks get-credentials -n ${aks} -g ${RG} 