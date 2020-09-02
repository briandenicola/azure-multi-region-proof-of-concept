#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -k|--key)
      key=$2
      shift 2
      ;;
    -c|--cert)
      cert=$2
      shift 2
      ;;
    --domain)
      domainName=$2
      shift 2
      ;;
    --domain)
      domainName=$2
      shift 2
      ;;
    --ingress)
      ingressUri=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./create_infrastructure.sh --domain {domain name} -k {TLS key file} -c {TLS certificate file}
        --ingress    - The Uri of the ingress controller. Will be joined with --domain flag to form fully qualified domain name  Example: api.ingress. 
        --domain     - The domain name for the application. Example: bjd.demo
        --key(k)   - The path to the certificate private key
        --cert(c)  - The path to hte certificate
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

kubectl create secret tls traefik-api-cert --key=${key} --cert=${cert}

cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: cqrsapitls
  annotations:
        kubernetes.io/ingress.class: traefik
        traefik.frontend.rule.type: PathPrefixStrip
spec:
  rules:
  - host: ${ingressUri}.${domainName}
    http:
      paths:
      - backend:
          serviceName: cqrsapisvc
          servicePort: 8081
        path: /
  tls:
  - secretName: traefik-api-cert
EOF