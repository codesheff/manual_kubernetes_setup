#!/usr/bin/env bash
# https://docs.docker.com/engine/install/ubuntu/

# 
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# you may as well do an upgrade
sudo apt upgrade -y

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

#
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Configure containerd to use the systemd cgroup driver:

sudo containerd config default > /tmp/containerd.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /tmp/containerd.toml
sudo mv /tmp/containerd.toml /etc/containerd/config.toml
sudo systemctl restart containerd
