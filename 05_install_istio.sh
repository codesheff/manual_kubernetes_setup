#!/usr/bin/env bash
set -euo pipefail
# Install Istio on the cluster using istioctl.
# This script assumes you have already set up kubectl access to the cluster.
# Download and install istioctl if you haven't already.
# You can download it from https://istio.io/latest/docs/setup/getting-started/#download

# If you're running a one node cluster, you may need to remove a taint that prevents pods from running on the control plane node:
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-

curl -L https://istio.io/downloadIstio | sh -

# Make sure istioctl is in your PATH.
cd istio-*  
export PATH=$PWD/bin:$PATH

# 
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/experimental-install.yaml


# Install Istio with the ambient profile.   
istioctl install --set profile=ambient -y
