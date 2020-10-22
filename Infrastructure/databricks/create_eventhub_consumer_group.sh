#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -g|--resource-group)
      RG=$2
      shift 2
      ;; 
    -n|--name)
      appName=$2
      shift 2
      ;;
    -r|--region)
      regions+=($2)
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./create_eventhub_consumer_group.sh -n {App Name} -r {region} [-r {secondary region}]"
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

count=1
hub=events
accessRule=spark
consumerGroup=databricks

for region in ${regions[@]}
do

    RG="${appName}_${region}_RG"

    eventHubNameSpace=hub${appName}00${count}
    az eventhubs eventhub consumer-group create -g ${RG} --namespace-name ${eventHubNameSpace} --eventhub-name ${hub} -n ${consumerGroup} >& /dev/null
    
    echo ${eventHubNameSpace} Primary ConnectionString
    az eventhubs eventhub authorization-rule show -g ${RG} --namespace-name ${eventHubNameSpace}  --eventhub-name ${hub} -n ${accessRule} --rights Listen
    az eventhubs eventhub authorization-rule keys list -g ${RG} --namespace-name ${eventHubNameSpace}   --eventhub-name ${hub} --name ${accessRule} -o tsv --query primaryConnectionString
    count=$((count+1))
done
  
