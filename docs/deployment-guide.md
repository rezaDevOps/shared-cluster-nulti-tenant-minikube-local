# Deployment Guide

## Prerequisites

- minikube installed and running
- kubectl configured
- Helm 3.x installed
- Docker available

## Initial Setup

### 1. Prepare Cluster
```bash
# Configure minikube cluster
./setup/cluster-setup.sh

# Install platform tools
./setup/install-tools.sh
```

### 2. Configure DNS
```bash
# Add entries to /etc/hosts
echo "$(minikube ip) argocd.saas-platform.local tenant1.saas-platform.local tenant2.saas-platform.local" | sudo tee -a /etc/hosts
```

### 3. Deploy Platform
```bash
# Create namespaces and policies
kubectl apply -f setup/namespace-setup.yaml

# Deploy ArgoCD project and applications
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applications/
```

### 4. Build Application
```bash
# Build and tag the application image
./setup/build-image.sh
```

## Verification

### Check ArgoCD
```bash
# Access ArgoCD UI
open http://argocd.saas-platform.local

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Test Applications
```bash
# Test tenant1
curl http://tenant1.saas-platform.local/health

# Test tenant2
curl http://tenant2.saas-platform.local/health
```

## Troubleshooting

### Common Issues
1. **Ingress not working**: Check minikube addons
2. **DNS resolution**: Verify /etc/hosts entries
3. **Images not found**: Run build-image.sh script
4. **ArgoCD sync issues**: Check repository URLs
