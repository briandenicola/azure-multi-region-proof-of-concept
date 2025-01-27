# Let's Encrypt TLS Certificates

Name | Usage | Required | SAN Urls
------ | ---- | ---- | ----
api.internal.bjd.demo | Ingress for the Azure Container Apps | Yes 
*.apim.bjd.demo | APIM | No | *.scm.apim.bjd.demo, *.westus.apim.bjd.demo, *.eastus.apim.bjd.demo
api.bjd.demo | Azure Front Door and App Gateway | No |  api.westus.bjd.demo, api.eastus.bjd.demo


## Installation
```bash
curl https://get.acme.sh | sh
```
## Configuration
* Follow this [link](https://www.robokiwi.com/wiki/azure/dns/lets-encrypt/) to setup Let's Encrypt with Azure DNS

## Certificates Requests 
> * **Note:** Set ACA_INGRESS_PFX_CERT_PASSWORD in the  ~/.env file to the $PfxPASSWORD value
> * **Note:** Set ACA_INGRESS_PFX_CERT_PATH in the ~/.env file to the path where the pfx file is be stored

```bash
export PfxPASSWORD=<pick a strong password to secure the pfx file>
acme.sh --issue --dns dns_azure -d *.bjd.demo
acme.sh --toPkcs -d *.bjd.demo --password $PfxPASSWORD
```

## Optional Certificates 
 _Only required if deploying application externally with APIM/AppGateway/FrontDoor_

### APIM Certificate
```bash
acme.sh --issue --dns dns_azure -d *.apim.bjd.demo -d *.scm.apim.bjd.demo *.westus.apim.bjd.demo *.eastus.apim.bjd.demo
acme.sh --toPkcs -d *.apim.bjd.demo --password $PfxPASSWORD
```

### AppGateway Certificate
```bash
acme.sh --issue --dns dns_azure -d api.bjd.demo -d api.westus.bjd.demo -d api.eastus.bjd.demo
acme.sh --toPkcs -d api.bjd.demo --password $PfxPASSWORD
```
