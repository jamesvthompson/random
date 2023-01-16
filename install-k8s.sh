#!/bin/bash

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Install Kubernetes
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=1.24.9-00 kubeadm=1.24.9-00 kubectl=1.24.9-00
sudo systemctl start kubelet
sudo systemctl enable kubelet

# Configure kubeadm
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --token-ttl=180h --cgroup-driver=systemd

# Configure Flannel networking
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Copy kubeadm config to non-sudo user's .kube directory
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Add command line options
install_nginx=false
install_prometheus=false

while getopts ":np" opt; do
  case $opt in
    n)
      install_nginx=true
      ;;
    p)
      install_prometheus=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Create namespace for nginx ingress
if $install_nginx; then
    kubectl create namespace nginx-ingress
    # Install nginx via Helm
    helm install nginx stable/nginx-ingress --namespace nginx-ingress --set controller.kind=DaemonSet --set controller.daemonset.useHostPort=true
fi

# Install Prometheus via Helm
if $install_prometheus; then
    helm install prometheus stable/prometheus
fi
