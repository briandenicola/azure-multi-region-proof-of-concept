#!/bin/bash

export numKeys=$1

ip=`kubectl get service traefik -o jsonpath={.status.loadBalancer.ingress[].ip}`

echo Making request to http://${ip}/api/keys
kubectl run --rm -it --restart=Never --image bjd145/utils:latest --env="ip=${ip}" --env="numKeys=${numKeys}" createkeys -- /bin/bash -c 'curl --header "Content-Type: application/json" --request POST --data "{\"NumberOfKeys\":${numKeys}}"  http://${ip}/api/keys'
