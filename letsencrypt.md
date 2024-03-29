# Let's Encrypt TLS Certificates
## Installation
```bash
curl https://get.acme.sh | sh
```
## Configuration
* Follow this [link](https://www.robokiwi.com/wiki/azure/dns/lets-encrypt/) to setup Let's Encrypt with Azure DNS
  
## Required Certificates 
```bash
export PfxPASSWORD=<pick a strong password to secure the pfx file>
acme.sh --issue --dns dns_azure -d *.bjd.demo
acme.sh --toPkcs -d *.bjd.demo --password $PfxPASSWORD
```

## Optional Certificates 
 _Only required if deploying application externally with APIM/AppGateway/FrontDoor_

### APIM Certificate
```bash
acme.sh --issue --dns dns_azure -d *.apim.bjd.demo 
acme.sh --toPkcs -d *.apim.bjd.demo --password $PfxPASSWORD
```

### AppGateway Certificate
```bash
acme.sh --issue --dns dns_azure -d api.bjd.demo -d api.us.bjd.demo -d api.uk.bjd.demo
acme.sh --toPkcs -d api.bjd.demo --password $PfxPASSWORD
```
