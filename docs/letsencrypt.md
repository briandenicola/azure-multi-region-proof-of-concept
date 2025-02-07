# Let's Encrypt TLS Certificates

Name | Usage | Required | SAN Urls
------ | ---- | ---- | ----
api.internal.bjd.demo | Ingress for the Azure Container Apps | Yes 
*.apim.bjd.demo | APIM | No | *.scm.apim.bjd.demo, westus.apim.bjd.demo, eastus.apim.bjd.demo
api.bjd.demo | Azure Front Door and App Gateway | No |  westus.api.bjd.demo, eastus.api.bjd.demo

## ACME Script Installation

```bash
curl https://get.acme.sh | sh
```

### Notes
> * Follow [this blog](https://www.robokiwi.com/wiki/azure/dns/lets-encrypt/) to setup Let's Encrypt with Azure DNS

## Container Apps Ingress Certificate Request
```bash
export PfxPASSWORD=<pick a strong password to secure the pfx file>
acme.sh --issue --dns dns_azure -d api.bjd.demo
acme.sh --toPkcs -d api.ingres.bjd.demo --password $PfxPASSWORD
```
### Notes
> * Set ACA_INGRESS_PFX_CERT_PASSWORD in the  ~/.env file to the $PfxPASSWORD value
> * Set ACA_INGRESS_PFX_CERT_PATH in the ~/.env file to the path where the pfx file is be stored
<p align="right">(<a href="#lets-encrypt-tls-certificates">back to top</a>)</p>

## Optional Certificates 
 _Only required if deploying application externally with APIM/AppGateway/FrontDoor_

### APIM Certificate Certificate Request
```bash
acme.sh --issue --dns dns_azure -d \*.apim.bjd.demo -d \*.scm.apim.bjd.demo -d \*.apim.westus.bjd.demo -d \*.apim.eastus.bjd.demo
acme.sh --toPkcs -d \*.apim.bjd.demo --password $PfxPASSWORD
```
### Notes
> * Set APIM_PFX_CERT_PATH in the  ~/.env file to the $PfxPASSWORD value
> * Set APIM_PFX_CERT_PASSWORD in the ~/.env file to the path where the pfx file is be stored
<p align="right">(<a href="#lets-encrypt-tls-certificates">back to top</a>)</p>

### AppGateway Certificate Request
```bash
acme.sh --issue --dns dns_azure -d api.bjd.demo -d westus.api.bjd.demo -d eastus.api.bjd.demo
acme.sh --toPkcs -d api.bjd.demo --password $PfxPASSWORD
```
### Notes
> * Set APP_GW_PFX_CERT_PATH in the  ~/.env file to the $PfxPASSWORD value
> * Set APP_GW_PFX_CERT_PASSWORD in the ~/.env file to the path where the pfx file is be stored

# Navigation
[⏪ Previous Section](../README.md) ‖ [Return to Main Index 🏠](../README.md) ‖ [Next Section ⏩](../docs/infrastructure.md) 
<p align="right">(<a href="#lets-encrypt-tls-certificates">back to top</a>)</p>