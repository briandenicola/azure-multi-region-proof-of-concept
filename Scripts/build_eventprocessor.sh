#!/bin/bash

docker login -u bjd145 bjd145.azurecr.io

func kubernetes install 
func kubernetes deploy --name eventprocessor --registry bjd145.azurecr.io/cqrs --min-replicas 1
