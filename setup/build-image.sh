#!/bin/bash
set -e

echo "Building application image for minikube..."

# Set minikube docker environment
eval $(minikube docker-env)

# Build the application image
echo "Building saas-app:latest..."
docker build -t saas-app:latest ./src/

# Also tag with version if provided
if [ ! -z "$1" ]; then
    echo "Tagging as saas-app:$1..."
    docker tag saas-app:latest saas-app:$1
fi

echo "✅ Image built successfully!"
echo "🔄 To deploy, update the image tag in your values file or sync ArgoCD"

# List the images to verify
echo "📦 Available saas-app images:"
docker images | grep saas-app
