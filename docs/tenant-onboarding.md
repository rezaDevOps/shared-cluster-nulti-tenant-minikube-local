# Tenant Onboarding Guide

## Overview

Adding new tenants to the SaaS platform involves creating tenant-specific configurations and deploying them through the GitOps pipeline.

## Steps to Add a New Tenant

### 1. Create Tenant Values File
```bash
# Create values-tenant3.yaml
cat > helm-charts/saas-app/values-tenant3.yaml << EOF
tenant:
  id: "3"
  name: "Tech Innovations Ltd"
  subdomain: "tenant3"

postgresql:
  auth:
    database: tenant3_db
    username: tenant3_user

ingress:
  hosts:
    - host: tenant3.saas-platform.local
      paths:
        - path: /
          pathType: Prefix
EOF
```

### 2. Create ArgoCD Application
```bash
# Create tenant3-app.yaml
cat > argocd/applications/tenant3-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: tenant3-app
  namespace: argocd
spec:
  project: saas-platform
  source:
    repoURL: https://github.com/your-org/saas-platform
    targetRevision: HEAD
    path: helm-charts/saas-app
    helm:
      valueFiles:
      - values.yaml
      - values-tenant3.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: tenant3
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### 3. Deploy
```bash
# Apply the new application
kubectl apply -f argocd/applications/tenant3-app.yaml

# Add DNS entry
echo "$(minikube ip) tenant3.saas-platform.local" | sudo tee -a /etc/hosts
```

## Verification
```bash
# Check deployment status
kubectl get pods -n tenant3

# Test the new tenant
curl http://tenant3.saas-platform.local/health
```
