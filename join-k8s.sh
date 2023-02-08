#!/bin/bash

# Load the br_netfilter module required for networking
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# To allow iptables to see bridged traffic, as required by Kubernetes, we need to set the values of certain fields to 1
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Apply the new settings without restarting
sudo sysctl --system

# Install curl.
sudo apt install curl -y

# Get the apt-key and then add the repository from which we will install containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update and then install the containerd package
sudo apt update -y 
sudo apt install -y containerd.io

# Set up the default configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Modify the containerd configuration file and ensure that the cgroupDriver is set to systemd
sudo tee /etc/containerd/config.toml <<EOF
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    BinaryName = ""
    CriuImagePath = ""
    CriuPath = ""
    CriuWorkPath = ""
    IoGid = 0
    IoUid = 0
    NoNewKeyring = false
    NoPivotRoot = false
    Root = ""
    ShimCgroup = ""
    SystemdCgroup = true
EOF

# Restart containerd to apply the changes
sudo systemctl restart containerd

# Check if containerd is running
if ps -ef | grep -q containerd; then
  echo "containerd is running"
else
  echo "containerd is not running"
  exit 1
fi

# Add the repository key and the repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the system and install the 3 Kubernetes modules
sudo apt update -y
sudo apt install -y kubelet=1.24.10-00 kubeadm=1.24.10-00 kubectl=1.24.10-00

# Disable swap on both machines to allow kubelet to work properly
sudo swapoff –a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab 

#Enable the kubelet service on system
sudo systemctl enable kubelet

# Join the cluster using the kubeadm join command
read -p "Enter the kubeadm join command from the master node: " join_command
$join_command

# Check whether all the default pods are running
kubectl get pods -A

fstab 

