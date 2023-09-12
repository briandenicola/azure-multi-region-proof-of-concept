#!/bin/bash

export keyid=$1

ip=`kubectl get service traefik -o jsonpath={.status.loadBalancer.ingress[].ip}`
hostname=`kubectl get ingresses cqrsapitls -o jsonpath={.spec.rules[0].host}`

#echo Making request to http://${ip}/api/keys/${keyid}
#kubectl run --rm -it --restart=Never --image bjd145/utils:2.2 --env="ip=${ip}" --env="keyid=${keyid}" getkeys -- /bin/bash -c 'curl --header "Content-Type: application/json" --request GET http://${ip}/api/keys/${keyid}' | jq

echo Making request to https://${hostname}/api/keys/${keyid}
kubectl run --rm -it --restart=Never --image bjd145/utils:3.16 --env="hostname=${hostname}" --env="keyid=${keyid}" getkeys --command -- /bin/bash -c 'curl --header "Content-Type: application/json" --request GET https://${hostname}/api/keys/${keyid}'
