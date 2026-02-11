#!/usr/bin/env bash

K8S_VERSION=$(kubectl version --client  2>/dev/null | grep -oP 'v\d+\.\d+' | head -1)

kubectl apply -f https://reweave.azurewebsites.net/k8s/${K8S_VERSION}/net.yaml