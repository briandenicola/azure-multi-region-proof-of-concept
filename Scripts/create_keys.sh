#!/bin/bash

export numKeys=$1

ip=`kubectl get service traefik -o jsonpath={.status.loadBalancer.ingress[].ip}`
hostname=`kubectl get ingresses cqrsapitls -o jsonpath={.spec.rules[0].host}`

echo Making request to http://${ip}/api/keys
kubectl run --rm -it --restart=Never --image bjd145/utils:2.2 --env="ip=${ip}" --env="numKeys=${numKeys}" createkeys -- /bin/bash -c 'curl --header "Content-Type: application/json" --request POST --data "{\"NumberOfKeys\":${numKeys}}"  http://${ip}/api/keys'

echo Making request to https://${hostname}/api/keys
kubectl run --rm -it --restart=Never --image bjd145/utils:2.2 --env="hostname=${hostname}" --env="numKeys=${numKeys}" createkeys -- /bin/bash -c 'curl --header "Content-Type: application/json" --request POST --data "{\"NumberOfKeys\":${numKeys}}"  https://${hostname}/api/keys'
