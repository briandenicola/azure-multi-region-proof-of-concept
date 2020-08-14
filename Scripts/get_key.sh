#!/bin/bash

export keyid=$1

ip=`kubectl get service traefik -o jsonpath={.status.loadBalancer.ingress[].ip}`

echo Making request to http://${ip}/api/keys/${keyid}
kubectl run --rm -it --restart=Never --image bjd145/utils:latest --env="ip=${ip}" --env="keyid=${keyid}" getkeys -- /bin/bash -c 'curl --header "Content-Type: application/json" --request GET http://${ip}/api/keys/${keyid}'