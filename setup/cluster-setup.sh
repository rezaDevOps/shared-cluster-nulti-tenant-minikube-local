#!/bin/bash
set -e

echo "Configuring existing minikube cluster for SaaS platform..."

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "Starting minikube..."
    minikube start --memory=8192 --cpus=4 --driver=docker
fi

# Enable required addons
echo "Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable ingress-dns
minikube addons enable metrics-server

# Set kubectl context to minikube
kubectl config use-context minikube

# Verify cluster is ready
kubectl cluster-info

echo "✅ Minikube cluster configured successfully"
echo "🌐 Minikube IP: $(minikube ip)"
echo "📝 Add the following to your /etc/hosts file:"
echo "$(minikube ip) tenant1.saas-platform.local"
echo "$(minikube ip) tenant2.saas-platform.local"
echo "$(minikube ip) argocd.saas-platform.local"
