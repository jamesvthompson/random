#!/bin/bash

# Install Helm 3
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Add NVIDIA and Ingress Nginx repositories and update them together
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NVIDIA GPU Operator chart
helm install --wait --generate-name \
     -n gpu-operator --create-namespace \
     nvidia/gpu-operator \
     --set driver.enabled=false

# Upgrade or install Ingress Nginx chart
helm upgrade -i nginx-ingress ingress-nginx/ingress-nginx \
    --namespace nginx-ingress --create-namespace \
    --set controller.kind=DaemonSet \
    --set controller.daemonset.useHostPort=true
