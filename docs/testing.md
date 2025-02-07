Testing
=============
* Testing will connect into the `utils` container, in which a series of manual curl commands can be run to validate the deployment.

# Steps
```bash
➜  cqrs git:(main) ✗ task validate
task: [validate] pwsh ./validate.ps1 -DomainName bjdazure.tech -ResoureGroupName "pipefish-47182_canadacentral_apps_rg"
....
Running arbitrary commands with options is not supported by 'az containerapp exec'.
53
Copy and past the following curl commands to validate the CQRS application.
curl -s https://api.ingress.bjdazure.tech/healthz
curl -s --header "Content-Type: application/json" --data '{"NumberOfKeys":10}' https://api.ingress.bjdazure.tech/api/keys | jq

Pick one of the ids from the above command and then run the following command:
export keyid=<id from above
curl -s --header "Content-Type: application/json" https://api.ingress.bjdazure.tech/api/keys/${keyid} | jq
exit
....
INFO: Connecting to the container 'utils'...
...
root@utils--93xfo0m-55d8c7f479-vbflq:/code# curl -s --header "Content-Type: application/json" --data '{"NumberOfKeys":10}' https://api.ingress.bjdazure.tech/api/keys | jq
[
  {
    "keyId": "17ade7ac-3874-b2f9-9ac9-c0424daaa03e",
    "key": "CSmwP+AdvhQ1iSfBwyzGRx+vi5Rvn8g8V0eC29TpXbgexeHPOg8ODNoxuxuj1qfc0H1N2XWM+bR5RkxaGI0BxQ==",
    "fromCache": false,
    "readHost": "",
    "writeHost": "api--jz56iu9-58cd494ff4-gf2mz",
    "readRegion": "",
    "writeRegion": "canadacentral",
    "timeStamp": "Friday, 07-Feb-25 18:21:21 UTC"
  },
...
root@utils--93xfo0m-55d8c7f479-vbflq:/code# curl -s --header "Content-Type: application/json" https://api.ingress.bjdazure.tech/api/keys/af77ffed-c153-53ba-c00f-ed8badf78615 | jq
  {
    "keyId": "af77ffed-c153-53ba-c00f-ed8badf78615",
    "key": "wi3Avpbjy4XTIHan4D+7h0YmmNKK1p+piU6ZFtC27lgpmfcsaWy5S7Bq43QWPUaPpt2dhahBY48PRWkAgDKsKQ==",
    "fromCache": false,
    "readHost": "",
    "writeHost": "api--jz56iu9-58cd494ff4-gf2mz",
    "readRegion": "",
    "writeRegion": "canadacentral",
    "timeStamp": "Friday, 07-Feb-25 18:21:21 UTC"
  }
```

# Navigation
[⏪ Previous Section](../docs/code.md) ‖ [Return to Main Index 🏠](../README.md) ‖
<p align="right">(<a href="#lets-encrypt-tls-certificates">back to top</a>)</p>