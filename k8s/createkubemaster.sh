#!/bin/bash

# Create configuration file for containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Load modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Set system configurations for Kubernetes networking
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply new settings
sudo sysctl --system

# Install containerd
sudo apt-get update && sudo apt-get install -y containerd

# Create default configuration file for containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Restart containerd to ensure new configuration file usage
sudo systemctl restart containerd

# Verify that containerd is running
# sudo systemctl status containerd

# Disable swap
sudo swapoff -a

# Install dependency packages
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

# Download and add GPG key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Add Kubernetes to repository list
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Update package listings
sudo apt-get update

# Install Kubernetes packages
sudo apt-get install -y kubelet=1.24.0-00 kubeadm=1.24.0-00 kubectl=1.24.0-00

# Turn off automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

#initialize the Kubernetes cluster on the control plane node using kubeadm
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.24.0

#--------------------------------------------------------------- Master only ---------------------------------------------------------------
#Set kubectl access
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#install Calico Networking:
#sudo kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
#khong install duoc vi loi nen chuyen sang Weave net
sudo kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

#--------------------------------------------------------------- Master only ---------------------------------------------------------------

#--------------------------------------------------------------- Node only ---------------------------------------------------------------

#create file to run
echo "#!/bin/bash" >> joinmaster.sh

# create token
kubeadm token create --print-join-command >> joinmaster.sh

#--------------------------------------------------------------- Node only ---------------------------------------------------------------
