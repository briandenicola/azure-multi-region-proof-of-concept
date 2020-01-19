#!/bin/bash

export numKeys=$1

ip=`kubectl get service traefik -o jsonpath={.status.loadBalancer.ingress[].ip}`
curl --header "Content-Type: application/json" --request POST --data "{\"NumberOfKeys\":${numKeys}}"  http://${ip}/api/keys
