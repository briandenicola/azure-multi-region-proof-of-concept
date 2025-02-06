#!/bin/bash

# this runs at Codespace creation - not part of pre-build

echo "$(date)    post-create start" >> ~/status

#Install jq
sudo apt update
sudo apt install -y jq

#Install envsubst
curl -Lso envsubst https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-Linux-x86_64
sudo install envsubst /usr/local/bin
rm -rf ./envsubst

#Install Task
sudo sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

#Install Trivy
VERSION=`curl --silent "https://api.github.com/repos/aquasecurity/trivy/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/'`
curl -sSL "https://github.com/aquasecurity/trivy/releases/download/v${VERSION}/trivy_${VERSION}_Linux-64bit.tar.gz" -o /tmp/trivy.tar.gz
mkdir /tmp/trivy
tar -zxf /tmp/trivy.tar.gz -C /tmp/trivy
sudo mv /tmp/trivy/trivy /usr/local/bin
rm -f /tmp/trivy.tar.gz
rm -rf /tmp/trivy

echo "$(date)    post-create complete" >> ~/status
