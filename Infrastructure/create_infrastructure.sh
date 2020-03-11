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

az_cli_ver=`az --version | grep -i azure-cli | awk '{print $2}'`
if dpkg --compare-versions ${az_cli_ver} le 2.0.78; then
  echo "This script requires az cli to be at least 2.0.78"
  exit 1
fi

helm_ver=`helm version | awk -F: '{print $2}' | awk -F, '{print $1}' | tr -d \" | tr -d v`
if dpkg --compare-versions ${helm_ver} le 2.9.9; then
  echo "This script requires helm to be at least 3.0.0"
  exit 1
fi

if [[ -z "${appName}" ]]; then
  appName=`cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1`
fi 

cosmosDBAccountName=db${appName}001
eventHubNameSpace=hub${appName}001
redisName=cache${appName}001
aks=k8s${appName}001
nodeRG=${RG}_nodes 
storageAccountName=${appName}sa001
acrAccountName=acr${appName}001
appInsightsName=ai${appName}001
logAnalyticsWorkspace=logs${appName}001

az account show  >> /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  az login
fi

#Get Subscription Id
az account set -s ${subscription}

#Add extensions
az extension add --name application-insights
az extension add --name log-analytics

#Create Resource Group
az group create -n $RG -l $location

#Create Cosmos
database=AesKeys
collection=Items

az cosmosdb create -g ${RG} -n ${cosmosDBAccountName} --kind GlobalDocumentDB 
az cosmosdb sql database create  -g ${RG} -a ${cosmosDBAccountName} -n ${database}
az cosmosdb sql container create -g ${RG} -a ${cosmosDBAccountName} -d ${database} -n ${collection} --partition-key-path '/keyId'

#Create Event Hub
hub=events
az eventhubs namespace create -g ${RG} -n ${eventHubNameSpace} -l ${location} --sku Standard --enable-auto-inflate --maximum-throughput-units 5 --enable-kafka
az eventhubs eventhub create -g ${RG} --namespace-name ${eventHubNameSpace} -n ${hub} --message-retention 7 --partition-count 1

#Create Redis Cache
az redis create  -g ${RG} -n ${redisName} -l ${location} --sku standard --vm-size c1 --minimum-tls-version 1.2   

#Create Azure Storage
az storage account create --name ${storageAccountName} --location $location --resource-group $RG --sku Standard_LRS

#Create ACR
az acr create -n ${acrAccountName} -g ${RG} -l ${location} --sku Standard
acrid=`az acr show -n ${acrAccountName} -g ${RG} --query 'id' -o tsv`

#Create AKS
az aks create -n ${aks} -g ${RG} -l ${location} --load-balancer-sku standard --node-count 3 --node-resource-group ${nodeRG} --ssh-key-value '~/.ssh/id_rsa.pub' 
az aks update -n ${aks} -g ${RG} --enable-acr --acr ${acrid}    

# Create Application Insights
az monitor app-insights component create --app ${appInsightsName} --location ${location} --kind web -g ${RG} --application-type web

# Create Log Analytics Workspace 
az monitor log-analytics workspace create -n ${logAnalyticsWorkspace} --location ${location} -g ${RG}

## Get Pod Credentials 
az aks get-credentials -n ${aks} -g ${RG} 

if [[ $? -eq 0 ]]; then
  ## Install Traefik Ingress 
  helm repo add stable https://kubernetes-charts.storage.googleapis.com/
  helm repo update
  helm install traefik stable/traefik --set rbac.enabled=true

  ## Install Keda
  helm repo add kedacore https://kedacore.github.io/charts
  helm repo update
  kubectl create namespace keda
  helm install keda kedacore/keda --namespace keda
fi 

# echo Application name
echo ------------------------------------
echo "Infrastructure built successfully. Application Name: ${appName}"
echo ------------------------------------