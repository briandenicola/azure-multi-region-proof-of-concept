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
    -h|--help)
      echo "Usage: ./setup_diag_settings.sh -n {App Name} -r centralus -r ukwest"
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

#Define Global Resource Group
rgGlobal="${appName}_Global_RG"

cosmosDBAccountName=db${appName}001
logAnalyticsWorkspace=logs${appName}001

diagSettingsName=diag

# Get Resource IDs
workspace_id=`az monitor log-analytics workspace show -n ${logAnalyticsWorkspace} -g ${rgGlobal} -o tsv --query id`
cosmos_id=`az cosmosdb show -n ${cosmosDBAccountName} -g ${rgGlobal} -o tsv --query id`
# Setup Cosmos Diagnostic Settings
cosmos_metrics='[
  {"categories": "requests", "enabled": true}
]'
cosmos_logs='[
  { "category": "DataPlaneRequests", "enabled": true},
  { "category": "QueryRuntimeStatistics", "enabled": true},
  { "category": "PartitionKeyStatistics", "enabled": true},
  { "category": "PartitionKeyRUConsumption", "enabled": true},
  { "category": "ControlPlaneRequests", "enabled": true}
]'

az monitor diagnostic-settings create -n ${diagSettingsName} \
 --resource ${cosmos_id}  \
 --workspace ${workspace_id} \
 --logs "${cosmos_logs}" \
 --metrics "${cosmos_metrics}"

count=1
for region in ${regions[@]}
do
  RG="${appName}_${region}_RG"

  eventHubNameSpace=hub${appName}00${count}
  redisName=cache${appName}00${count}
  aks=k8s${appName}00${count}
  
  redis_id=`az redis show -n ${redisName} -g ${RG} -o tsv --query id`
  eventHub_id=`az eventhubs namespace show -n ${eventHubNameSpace} -g ${RG} -o tsv --query id`

  # Setup Redis Diagnostic Settings
  redis_metrics='[
    {"categories": "AllMetrics", "enabled": true}
  ]'
  az monitor diagnostic-settings create -n ${diagSettingsName} \
    --resource ${redis_id} \
    --workspace ${workspace_id} \
    --metrics "${redis_metrics}"

  # Setup Event Hub Diagnostic Settings
  hub_metrics='[
    {"categories": "AllMetrics", "enabled": true}
  ]'
  hub_logs='[
    { "category": "ArchiveLogs", "enabled": true},
    { "category": "OperationalLogs", "enabled": true},
    { "category": "AutoScaleLogs", "enabled": true},
    { "category": "CustomerManagedKeyUserLogs", "enabled": true}
  ]'
  az monitor diagnostic-settings create -n ${diagSettingsName} \
    --resource ${eventHub_id} \
    --workspace ${workspace_id} \
    --log "${hub_logs}" \
    --metrics "${hub_metrics}"

  # Setup Azure Monitor with AKS
  az aks enable-addons -a monitoring -n ${aks} -g ${RG} --workspace-resource-id ${workspace_id}
  count=$((count+1))
done