#!/bin/bash

# this runs at Codespace creation - not part of pre-build

echo "$(date)    post-create start" >> ~/status

# Install buildpacks
(curl -sSL "https://github.com/buildpacks/pack/releases/download/v0.27.0/pack-v0.27.0-linux.tgz" | sudo tar -C /usr/local/bin/ --no-same-owner -xzv pack)

# Install dotnet
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
sudo apt-get update -qq
sudo apt-get install -y -qq dotnet-sdk-6.0 powershell

# Install envsubst 
curl -Lso envsubst https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-Linux-x86_64
sudo install envsubst /usr/local/bin
rm -rf ./envsubst

# Install Playwright
npm install -g playwright@latest
npx playwright install-deps

# Update Kubelogin and kubectl
sudo az aks install-cli

# Add aks preview extensions
az extension add --name aks-preview

# update the base docker images
docker pull bjd145/utils:3.8

echo "$(date)    post-create complete" >> ~/status
