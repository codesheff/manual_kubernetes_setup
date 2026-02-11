#!/usr/bin/env bash

# Probably base it off this
# https://github.com/kodekloudhub/certified-kubernetes-administrator-course/blob/master/kubeadm-clusters/virtualbox/ubuntu/vagrant/node-setup.sh

# This is just notes instead of a full script

# install a container runtime like containerd or docker


# Apply the necessary sysctl params
# ( https://kubernetes.io/docs/setup/production-environment/container-runtimes/ )

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


#####################
# There's steps I've skipped here like disabling swap, setting up hostnames, etc.
# Edit fstab and remove or comment any swap lines, then run sudo swapoff -a and reboot. Verify with swapon --show (no output).
# I am actually running these at the moment when doing my set up
#################
## Install kubeadm, kubelet and kubectl


sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg


# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list


sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


# put your kubeadm-config.yaml file in place

sudo kubeadm init --config kubeadm-config.yaml


###
# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 192.168.1.118:6443 --token hakcsd.4wus66g5xr8g1kqw \
#         --discovery-token-ca-cert-hash sha256:edf92b2b96d4b4ae9c7ece459b2c1a13608aaf87c3fba3876e34255f0ee3ac80 