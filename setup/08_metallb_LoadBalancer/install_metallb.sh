#!/usr/bin/env bash
set -euo pipefail

# Install MetalLB (native manifests) and configure an L2 address pool.
# Update IP_POOL to a free range on your LAN that is not managed by DHCP.
# I've done that by altering settings on router

IP_POOL="192.168.1.240-192.168.1.250"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

kubectl -n metallb-system wait --for=condition=available deployment/controller --timeout=120s

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - ${IP_POOL}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2adv
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
EOF

kubectl -n metallb-system get all


echo "remember , if you're using a one node cluster, you may need to remove a taint that prevents load balancer pods from running on the control plane node:"
echo "actually , maybe that's a label"
#echo "remember , if you're using a one node cluster, you need to add the following annotation to your service manifest to use the LoadBalancer type:"
# echo "annotations:"
# echo "  metallb.universe.tf/allow-shared-ip: \"true\""