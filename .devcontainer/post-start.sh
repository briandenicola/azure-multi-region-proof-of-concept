#!/bin/bash

# this runs each time the container starts

echo "$(date)    post-start start" >> ~/status

#az login
#make cluster

az extension update --name aks-preview

echo "$(date)    post-start complete" >> ~/status
