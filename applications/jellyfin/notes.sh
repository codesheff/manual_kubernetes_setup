#!/usr/bin/env bash



# install helm and add the jellyfin repo, then update the repo list

sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
helm repo add jellyfin https://jellyfin.github.io/jellyfin-helm
helm repo update

# https://jellyfin.org/docs/general/installation/advanced/kubernetes/

# install jellyfin using helm, with the default values. This will create a LoadBalancer service, which we will change to NodePort later.
# helm install jellyfin jellyfin/jellyfin --namespace jellyfin --create-namespace
helm install jellyfin jellyfin/jellyfin -f values.yaml --namespace jellyfin --create-namespace
# (To uninstall, it's :  helm uninstall jellyfin -n jellyfin )

# Needed to make sure there is a storageclass available for the PVC to bind to. We will use the default storageclass, which is provided by the cluster and uses local storage on the nodes.
# Do I need this?
# kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/sig-storage-local-static-provisioner/v2.7.1/deploy/kubernetes/sig-storage-local-static-provisioner.yaml

# Here's how to reapply the helm chart with our custom values, which will use the local storage for the PVs and set the service type to NodePort. This will allow us to access the service from outside the cluster using the node's IP and the assigned NodePort.
# helm upgrade jellyfin jellyfin/jellyfin -f ./applications/jellyfin/values.yaml --namespace jellyfin


# Next step is to get nfs shares made available as pv and pvc, and then update the helm chart to use those for the media storage. This will allow us to store our media files on the nfs share and have them available to the jellyfin pods.

# Then setup ingress