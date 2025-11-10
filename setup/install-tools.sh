#!/bin/bash
set -e

echo "Installing required tools on minikube..."

# Install ArgoCD
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install Argo Rollouts
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Note: Using minikube's built-in ingress controller (already enabled in cluster-setup.sh)
echo "Using minikube's built-in NGINX ingress controller..."

# Wait for deployments
echo "Waiting for components to be ready..."
kubectl wait --namespace argocd --for=condition=available --timeout=300s deployment/argocd-server
kubectl wait --namespace argo-rollouts --for=condition=available --timeout=300s deployment/argo-rollouts

# Wait for ingress controller (minikube addon)
echo "Waiting for ingress controller..."
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s || echo "Ingress controller might still be starting..."

# Create ArgoCD ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.saas-platform.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF

echo "✅ All tools installed successfully"

# Get ArgoCD admin password
echo ""
echo "🔑 ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "🌐 Access URLs (add to /etc/hosts first):"
echo "   ArgoCD UI: http://argocd.saas-platform.local"
echo "   Tenant 1:  http://tenant1.saas-platform.local"
echo "   Tenant 2:  http://tenant2.saas-platform.local"
echo ""
echo "🚀 Run the following to add entries to /etc/hosts:"
echo "   echo '$(minikube ip) argocd.saas-platform.local tenant1.saas-platform.local tenant2.saas-platform.local' | sudo tee -a /etc/hosts"
