#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -r|--region)
      regions+=($2)
      shift 2
      ;;
    -n|--name)
      appName=$2
      shift 2
      ;;
    --domain)
      domainName=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./create_infrastructure.sh -r {region}  --domain {domain name} [-n {Application Name} -r {secondary region}]
        --region(r)  - Primary Region 
        --domain     - The domain name for the application. Example: bjd.demo
        --name(n)    - A defined name for the Application. Will be auto-generated if not supplied (Optional)
        --region(r)  - Additional regions defined to deploy application
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

today=`date +"%y%m%d"`
uuid=`uuidgen | sed 's/-//g'`

if [[ -z "${appName}" ]]; then
  appName=`cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1`
fi 

if [[ -z "${regions[0]}" ]]; then
  echo "This script requires at least one region defined"
  exit 1
fi 

for region in ${regions[*]}; 
do 
    locations+=\"${region}\",; 
done
locations="[${locations::-1}]"

#Terraform Variables
tf_Variable_File=dynamic.tfvars 
tf_Plan_File="${appName}.plan.${today}-${uuid}" 

#Resource Names
cosmosDBAccountName=db${appName}001
acrAccountName=acr${appName}001
appInsightsName=ai${appName}001
logAnalyticsWorkspace=logs${appName}001
vnetName=vnet${appName}00
eventHubNameSpace=hub${appName}00
redisName=cache${appName}00
aks=k8s${appName}00
storageAccountName=sa${appName}00

public_ip=`curl -s http://checkip.amazonaws.com/`
ssh_pub_key=`cat ~/.ssh/id_rsa.pub`

cat <<EOF > ./terraform/${tf_Variable_File}
application_name = "${appName}"
locations = ${locations}
cosmosdb_name = "${cosmosDBAccountName}"
acr_account_name = "${acrAccountName}"
ai_account_name = "${appInsightsName}"
loganalytics_account_name = "${logAnalyticsWorkspace}"
vnet_name = "${vnetName}"
eventhub_namespace_name = "${eventHubNameSpace}"
redis_name = "${redisName}"
aks_name = "${aks}"
storage_name = "${storageAccountName}"
ssh_public_key = "${ssh_pub_key}"
api_server_authorized_ip_ranges = [ "${public_ip}/32" ]
custom_domain = "${domainName}"
EOF

cd ./terraform
terraform init 
terraform plan -out="${tf_Plan_File}" -var-file="${tf_Variable_File}"
terraform apply -auto-approve ${tf_Plan_File}

# echo Application name
if [[ $? -eq 0 ]]; then
  cd ..
  echo ------------------------------------
  echo "Infrastructure built successfully. Application Name: ${appName}"
  echo ------------------------------------
else
  cd ..
  echo ------------------------------------
  echo "Errors encountered while building infrastructure. Please review. Application Name: ${appName}"
  echo ------------------------------------
fi
