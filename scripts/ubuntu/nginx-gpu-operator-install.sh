#!/bin/bash

# Install Helm 3
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
   && chmod 700 get_helm.sh \
   && ./get_helm.sh

# Add and update NVIDIA Helm repository
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
   && helm repo update

# Install NVIDIA GPU Operator chart
helm install --wait --generate-name \
     -n gpu-operator --create-namespace \
     nvidia/gpu-operator \
     --set driver.enabled=false

# Add and update Ingress Nginx Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx \
   && helm repo update

# Upgrade or install Ingress Nginx chart
helm upgrade -i nginx-ingress ingress-nginx/ingress-nginx \
    --namespace nginx-ingress --create-namespace \
    --set controller.kind=DaemonSet \
    --set controller.daemonset.useHostPort=true
