# Multi-Tenant SaaS Platform on Kubernetes

This project demonstrates a production-ready multi-tenant SaaS platform using:
- **Kubernetes** for container orchestration
- **Helm** for application packaging and templating
- **ArgoCD** for GitOps continuous delivery
- **Argo Rollouts** for progressive delivery (canary/blue-green deployments)

## Architecture Overview

- **Namespace-per-Tenant**: Each tenant runs in isolated Kubernetes namespaces
- **Shared Database with Tenant Sharding**: Data is partitioned by tenant ID
- **Progressive Deployments**: Safe rollouts using canary strategies
- **Automated Onboarding**: GitOps-driven tenant provisioning

## Quick Start

### Prerequisites
- minikube installed and running
- kubectl configured for minikube
- Helm 3.x installed

### Setup Steps

1. **Configure minikube cluster:**
   ```bash
   ./setup/cluster-setup.sh
   ```

2. **Install platform tools:**
   ```bash
   ./setup/install-tools.sh
   ```

3. **Add DNS entries to /etc/hosts:**
   ```bash
   echo "$(minikube ip) argocd.saas-platform.local tenant1.saas-platform.local tenant2.saas-platform.local" | sudo tee -a /etc/hosts
   ```

4. **Deploy platform components:**
   ```bash
   kubectl apply -f setup/namespace-setup.yaml
   kubectl apply -f argocd/projects/
   kubectl apply -f argocd/applications/
   ```

5. **Build and load application image (for local development):**
   ```bash
   ./setup/build-image.sh
   ```

### Access the Applications

- **ArgoCD UI**: `http://argocd.saas-platform.local`
  - Username: `admin`
  - Password: (retrieve using the command shown during installation)
- **Tenant 1**: `http://tenant1.saas-platform.local`
- **Tenant 2**: `http://tenant2.saas-platform.local`

### Useful Commands

```bash
# Check minikube status
minikube status

# Get minikube IP
minikube ip

# Access minikube dashboard
minikube dashboard

# View application logs
kubectl logs -n tenant1 -l app.kubernetes.io/name=saas-app

# Check rollout status
kubectl argo rollouts get rollout saas-app -n tenant1

# Promote canary deployment
kubectl argo rollouts promote saas-app -n tenant1
```

## Minikube-Specific Notes

### Configuration Differences from Cloud Clusters
- **Image Pull Policy**: Set to `Never` for local images (change to `IfNotPresent` for registry images)
- **Ingress Controller**: Uses minikube's built-in NGINX addon instead of external controller
- **Load Balancer**: Requires `minikube tunnel` for LoadBalancer services
- **DNS**: Manual /etc/hosts entries needed (or use minikube tunnel with proper DNS setup)

### Resource Requirements
- **Memory**: 8GB recommended (4GB minimum)
- **CPUs**: 4 cores recommended (2 minimum)
- **Disk**: 20GB free space

### Troubleshooting

**If minikube is running slowly:**
```bash
minikube stop
minikube start --memory=8192 --cpus=4 --driver=docker
```

**If ingress is not working:**
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

**To reset everything:**
```bash
minikube delete
minikube start --memory=8192 --cpus=4 --driver=docker
```

**Load balancer services (use minikube tunnel):**
```bash
# In a separate terminal, keep this running
minikube tunnel
```

### Development Workflow

1. **Make code changes** in the `src/` directory
2. **Rebuild image**:
   ```bash
   ./setup/build-image.sh v1.0.1  # optional version tag
   ```
3. **Update image tag** in Helm values or trigger ArgoCD sync
4. **Watch deployment**:
   ```bash
   kubectl argo rollouts get rollout saas-app -n tenant1 --watch
   ```

## Features

- ✅ Multi-tenant isolation
- ✅ GitOps deployment
- ✅ Progressive delivery
- ✅ Monitoring and observability
- ✅ Automated scaling
- ✅ Security policies
