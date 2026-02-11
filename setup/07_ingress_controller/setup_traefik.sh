#!/usr/bin/env bash
set -euo pipefail

# Install Traefik ingress controller using Helm.

helm repo add traefik https://traefik.github.io/charts
helm repo update

# Create namespace if it doesn't exist.
kubectl get namespace traefik &>/dev/null || kubectl create namespace traefik

# Install or upgrade Traefik.
helm upgrade --install traefik traefik/traefik \
	--namespace traefik \
	--set ingressClass.enabled=true \
	--set ingressClass.isDefaultClass=true \
	--set providers.kubernetesIngress.enabled=true

# Show service details (NodePort/LoadBalancer depends on your cluster).
kubectl -n traefik get svc traefik
