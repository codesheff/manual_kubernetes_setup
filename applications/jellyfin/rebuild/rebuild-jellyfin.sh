#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

echo "[1/4] Applying storage + Istio manifests"
kubectl apply -k applications/jellyfin/rebuild

echo "[2/4] Installing/upgrading Jellyfin Helm release (Istio ingress mode)"
helm upgrade --install jellyfin jellyfin/jellyfin \
  -f applications/jellyfin/values.yaml \
  -f applications/jellyfin/values-istio.yaml \
  --namespace jellyfin --create-namespace

echo "[3/4] Ensuring source IP preservation for LAN-only policy"
kubectl -n jellyfin patch svc jellyfin-gw-istio -p '{"spec":{"externalTrafficPolicy":"Local"}}'

echo "[4/4] Verifying key resources"
kubectl -n jellyfin get pvc
kubectl -n jellyfin get gateway jellyfin-gw
kubectl -n jellyfin get httproute jellyfin-route
kubectl -n jellyfin get certificate jellyfin-tls
kubectl -n jellyfin get svc jellyfin-gw-istio

echo
echo "Done. Point local DNS/hosts: jellyfin.itosbl.com -> <EXTERNAL-IP of jellyfin-gw-istio>."
echo "Test: curl --resolve jellyfin.itosbl.com:443:<EXTERNAL-IP> https://jellyfin.itosbl.com -vk"
