#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -g|--resource-group)
      RG=$2
      shift 2
      ;;
    -r|--region)
      regions+=($2)
      shift 2
      ;;
    -n|--name)
      appName=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./create_infrastructure.sh -n {App Name} -g {Resource Group} -r {region} [-r {secondary region}]"
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

if [[ -z "${regions[0]}" ]]; then
  echo "This script requires at least one region defined"
  exit 1
fi 
primary=${regions[0]}

if [[ -z "${RG}" ]]; then
  echo "This script requires a Resource Group name defined"
  exit 1
fi 

public_ip=`curl -s http://checkip.amazonaws.com/`

az account show  >> /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  az login
fi

#Add extensions
az extension add --name application-insights
az extension add --name log-analytics

#Create Resource Group
az group create -n $RG -l $primary

#Resource Names
cosmosDBAccountName=db${appName}001
acrAccountName=acr${appName}001
appInsightsName=ai${appName}001
logAnalyticsWorkspace=logs${appName}001

#Create Cosmos
database=AesKeys
collection=Items

cosmosdb_cmd="az cosmosdb create -g ${RG} -n ${cosmosDBAccountName} --kind GlobalDocumentDB --enable-multiple-write-locations"
failoverPriority=0
for region in ${regions[@]}
do
  cosmosdb_cmd+=" --locations regionName=${region} failoverPriority=${failoverPriority}"
  failoverPriority=$((failoverPriority+1))
done
$cosmosdb_cmd

az cosmosdb sql database create  -g ${RG} -a ${cosmosDBAccountName} -n ${database}
az cosmosdb sql container create -g ${RG} -a ${cosmosDBAccountName} -d ${database} -n ${collection} --partition-key-path '/keyId'

#Create ACR
az acr create -n ${acrAccountName} -g ${RG} -l ${primary} --sku Premium

# Create Application Insights
az monitor app-insights component create --app ${appInsightsName} --location ${primary} --kind web -g ${RG} --application-type web

# Create Log Analytics Workspace 
az monitor log-analytics workspace create -n ${logAnalyticsWorkspace} --location ${primary} -g ${RG}

count=1
for region in ${regions[@]}
do

  #Resource Names
  vnetName=vnet${appName}00${count}
  eventHubNameSpace=hub${appName}00${count}
  redisName=cache${appName}00${count}
  aks=k8s${appName}00${count}
  storageAccountName=${appName}sa00${count}
  nodeRG=${RG}_${region}_nodes 

  #ACR Update
  if [ $region != $primary ]; then 
    az acr replication create -r ${acrAccountName} -l ${region}
  fi

  #Create Event Hub
  hub=events
  az eventhubs namespace create -g ${RG} -n ${eventHubNameSpace} -l ${region} --sku Standard --enable-auto-inflate --maximum-throughput-units 5 --enable-kafka
  az eventhubs eventhub create -g ${RG} --namespace-name ${eventHubNameSpace} -n ${hub} --message-retention 7 --partition-count 15

  #Create Redis Cache
  az redis create  -g ${RG} -n ${redisName} -l ${region} --sku standard --vm-size c1 --minimum-tls-version 1.2   

  #Create Azure Storage
  az storage account create --name ${storageAccountName} --resource-group $RG --sku Standard_LRS -l ${region}

  #Create Virtual Network and Subnets
  vnetIPRange="10.${count}.0.0/16"
  appgwSubnet=AppGateway
  appgwSubnetRange="10.${count}.1.0/24"
  az network vnet create -g ${RG} -n ${vnetName} -l ${region} --address-prefix ${vnetIPRange} --subnet-name ${appgwSubnet} --subnet-prefix ${appgwSubnetRange} 

  apimSubnet=APIM
  apimSubnetRanage="10.${count}.2.0/24"
  az network vnet subnet create -g ${RG} --vnet-name ${vnetName} -n ${apimSubnet} --address-prefixes ${apimSubnetRanage}

  k8sSubnet=Kubernetes
  k8sSubnetRange="10.${count}.4.0/22"
  k8ssubnetid=`az network vnet subnet create -g ${RG} --vnet-name ${vnetName} -n ${k8sSubnet} --address-prefixes ${k8sSubnetRange} --query 'id' -o tsv`

  #Create AKS
  SERVICE_CIDR="10.19${count}.0.0/16"
  DNS_IP="10.19${count}.0.10"
  
  az aks create -n ${aks} -g ${RG} -l ${region} \
    --load-balancer-sku standard \
    --node-count 3 \
    --node-resource-group ${nodeRG} \
    --ssh-key-value '~/.ssh/id_rsa.pub' \
    --vnet-subnet-id ${k8ssubnetid} \
    --service-cidr $SERVICE_CIDR \
    --dns-service-ip $DNS_IP \
    --network-plugin azure \
    --enable-cluster-autoscaler \
    --max-count 10 \
    --min-count 3 \
    --enable-managed-identity \
    --uptime-sla \
    --max-pods 40 \
    --api-server-authorized-ip-ranges ${public_ip}/32 \
    --location ${region}
  
  CLIENT_ID=`az aks show -n ${aks} -g ${RG} --query 'identity.principalId' -o tsv`
  NODE_CLIENT_ID=`az aks show -n ${aks} -g ${RG} --query 'identityProfile.kubeletidentity.objectId' -o tsv`
  
  az role assignment create --assignee-object-id ${CLIENT_ID} --role "Network Contributor" -g ${RG}
  az role assignment create --assignee-object-id ${CLIENT_ID} --role "acrpull" -g ${RG}
  az role assignment create --assignee-object-id ${NODE_CLIENT_ID} --role "acrpull" -g ${RG}

  ## Get Pod Credentials 
  az aks get-credentials -n ${aks} -g ${RG} 

  if [[ $? -eq 0 ]]; then
    ## Install Traefik Ingress 
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/
    helm repo update
    helm upgrade -i traefik stable/traefik --set rbac.enabled=true --set service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true
 
    ## Install Keda
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    kubectl create namespace keda
    helm upgrade -i keda kedacore/keda --namespace keda
  fi

  count=$((count+1))
done 

# echo Application name
echo ------------------------------------
echo "Infrastructure built successfully. Application Name: ${appName}"
echo ------------------------------------
