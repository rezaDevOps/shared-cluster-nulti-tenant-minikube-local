# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a multi-tenant SaaS platform running on Kubernetes using a **namespace-per-tenant isolation model**. The platform uses GitOps (ArgoCD) for continuous delivery and Argo Rollouts for progressive deployments with canary strategies.

## Architecture

### Multi-Tenant Isolation Model
- **Namespace-per-Tenant**: Each tenant runs in a dedicated Kubernetes namespace (e.g., `tenant1`, `tenant2`)
- **Database per Tenant**: Each tenant has its own PostgreSQL instance deployed within their namespace
- **Network Policies**: Restrict inter-tenant communication for security isolation
- **Resource Quotas**: Prevent resource exhaustion across tenants
- **Subdomain Routing**: Ingress routes traffic based on subdomain (e.g., `tenant1.saas-platform.local`)

### Key Components
1. **Application**: Node.js/Express app in [src/](src/) that is tenant-aware via environment variables (`TENANT_ID`, `TENANT_NAME`)
2. **Helm Charts**: In [helm-charts/saas-app/](helm-charts/saas-app/) - templates for deploying tenant applications with tenant-specific overrides (`values-tenant1.yaml`, `values-tenant2.yaml`)
3. **ArgoCD Applications**: GitOps manifests in [argocd/](argocd/) that sync Helm charts to tenant namespaces
4. **Argo Rollouts**: Progressive delivery with canary deployments configured in Helm charts

### Tenant Context
The application determines tenant context via environment variables injected by Helm:
- `TENANT_ID`: Unique tenant identifier
- `TENANT_NAME`: Human-readable tenant name
- Middleware in [src/app.js:19-25](src/app.js#L19-L25) attaches tenant context to each request

## Common Development Commands

### Initial Setup
```bash
# 1. Configure minikube cluster (creates cluster with proper resources)
./setup/cluster-setup.sh

# 2. Install ArgoCD, Argo Rollouts, and other platform tools
./setup/install-tools.sh

# 3. Add DNS entries for local development
echo "$(minikube ip) argocd.saas-platform.local tenant1.saas-platform.local tenant2.saas-platform.local" | sudo tee -a /etc/hosts

# 4. Deploy namespaces, network policies, and resource quotas
kubectl apply -f setup/namespace-setup.yaml

# 5. Deploy ArgoCD projects and applications
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applications/

# 6. Build and load the application image into minikube
./setup/build-image.sh
```

### Application Development Workflow

#### Building the Application
```bash
# Build image and load into minikube's Docker environment
./setup/build-image.sh

# Build with a specific version tag
./setup/build-image.sh v1.0.1

# The script sets minikube docker-env and builds locally
# Images are tagged as saas-app:latest (and saas-app:VERSION if provided)
```

#### Running Locally (Outside Kubernetes)
```bash
cd src/

# Install dependencies
npm install

# Run in development mode with auto-reload
npm run dev

# Run in production mode
npm start
```

#### Testing the Deployed Application
```bash
# Check health endpoints
curl http://tenant1.saas-platform.local/health
curl http://tenant2.saas-platform.local/health

# Test root endpoint (shows tenant info)
curl http://tenant1.saas-platform.local/

# View application logs
kubectl logs -n tenant1 -l app.kubernetes.io/name=saas-app
kubectl logs -n tenant2 -l app.kubernetes.io/name=saas-app
```

### Deployment & Rollout Management

#### Monitoring Deployments
```bash
# Watch canary rollout progress for a tenant
kubectl argo rollouts get rollout saas-app -n tenant1 --watch

# Check rollout status
kubectl argo rollouts status saas-app -n tenant1

# List all rollouts across tenants
kubectl argo rollouts list -A
```

#### Managing Canary Deployments
```bash
# Promote canary to stable (advance through canary steps)
kubectl argo rollouts promote saas-app -n tenant1

# Abort rollout and rollback to stable version
kubectl argo rollouts abort saas-app -n tenant1

# Restart rollout
kubectl argo rollouts restart saas-app -n tenant1
```

#### ArgoCD Operations
```bash
# Access ArgoCD UI
open http://argocd.saas-platform.local

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Sync application manually
kubectl -n argocd argocd app sync tenant1-app

# Check application status
kubectl -n argocd argocd app get tenant1-app
```

### Kubernetes Operations

#### Viewing Resources
```bash
# List all pods across tenant namespaces
kubectl get pods -A | grep tenant

# Describe a specific tenant's resources
kubectl get all -n tenant1

# Check resource quotas
kubectl get resourcequota -n tenant1
kubectl describe resourcequota -n tenant1
```

#### Debugging
```bash
# Get pod logs for a tenant
kubectl logs -n tenant1 -l app.kubernetes.io/name=saas-app --tail=100 -f

# Exec into a pod
kubectl exec -it -n tenant1 <pod-name> -- /bin/sh

# Check network policies
kubectl get networkpolicies -n tenant1
kubectl describe networkpolicy -n tenant1

# View events
kubectl get events -n tenant1 --sort-by='.lastTimestamp'
```

#### Minikube Management
```bash
# Check minikube status
minikube status

# Get minikube IP (needed for /etc/hosts)
minikube ip

# Access Kubernetes dashboard
minikube dashboard

# Enable ingress addon (if not already enabled)
minikube addons enable ingress

# For LoadBalancer services, run tunnel in separate terminal
minikube tunnel
```

## Adding a New Tenant

1. Create tenant-specific Helm values file: `helm-charts/saas-app/values-tenantN.yaml`
2. Create ArgoCD application manifest: `argocd/applications/tenantN-app.yaml`
3. Update DNS: Add `tenantN.saas-platform.local` to `/etc/hosts`
4. Apply the ArgoCD application: `kubectl apply -f argocd/applications/tenantN-app.yaml`
5. ArgoCD will automatically create the namespace and deploy the application

## Key Configuration Files

- **Helm Values**: [helm-charts/saas-app/values.yaml](helm-charts/saas-app/values.yaml) - Default configuration
- **Tenant Overrides**: `helm-charts/saas-app/values-tenant*.yaml` - Tenant-specific settings
- **Rollout Strategy**: Defined in [helm-charts/saas-app/values.yaml:67-79](helm-charts/saas-app/values.yaml#L67-L79) (canary with 20%/50%/80% steps)
- **ArgoCD Project**: [argocd/projects/saas-project.yaml](argocd/projects/saas-project.yaml) - Defines allowed resources and repos
- **Application Entry Point**: [src/app.js](src/app.js) - Express server with tenant middleware

## Important Notes

### Minikube-Specific Configuration
- **Image Pull Policy**: Set to `Never` in values.yaml for local images (change to `IfNotPresent` for registry images)
- **Image Building**: Always use `./setup/build-image.sh` which sets minikube docker-env before building
- **DNS**: Requires manual `/etc/hosts` entries since minikube doesn't provide external DNS
- **Resource Requirements**: Minikube needs 8GB RAM / 4 CPUs recommended

### Canary Deployment Behavior
The rollout strategy uses a 3-step canary:
- 20% traffic → 30s pause
- 50% traffic → 30s pause
- 80% traffic → 30s pause
- 100% traffic (automatic)

Rollouts require manual promotion via `kubectl argo rollouts promote` or will auto-promote after pause durations.

### ArgoCD Repository URL
The ArgoCD application manifests reference `https://github.com/your-org/saas-platform` - this should be updated to your actual Git repository URL if using GitOps sync from a remote repo. For local development, ArgoCD can sync from the local Helm charts.
