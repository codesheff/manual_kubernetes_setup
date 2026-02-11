#!/usr/bin/env bash

# install helm and add the jellyfin repo, then update the repo list

sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
helm repo add jellyfin https://jellyfin.github.io/jellyfin-helm
helm repo update


# install jellyfin using helm, with the default values. This will create a LoadBalancer service, which we will change to NodePort later.
helm install jellyfin jellyfin/jellyfin --namespace jellyfin --create-namespace

# Needed to make sure there is a storageclass available for the PVC to bind to. We will use the default storageclass, which is provided by the cluster and uses local storage on the nodes.
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/sig-storage-local-static-provisioner/main/deploy/kubernetes/sig-storage-local-static-provisioner.yaml

# Here's how to reapply the helm chart with our custom values, which will use the local storage for the PVs and set the service type to NodePort. This will allow us to access the service from outside the cluster using the node's IP and the assigned NodePort.
helm upgrade jellyfin jellyfin/jellyfin -f ./applications/jellyfin/values.yaml 