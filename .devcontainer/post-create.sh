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

echo "$(date)    post-create complete" >> ~/status