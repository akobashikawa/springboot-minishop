#!/bin/bash

echo "🏗️ Building mini-shop microservices..."

# Build all images
services=("orders-service" "products-service" "notifications-service")

for service in "${services[@]}"; do
    echo "Building $service..."
    cd $service
    docker build -t mini-shop/$service:latest .
    cd ..
done

echo "📦 Built images:"
docker images | grep mini-shop

# Check if we're using K3s
if command -v k3s &> /dev/null; then
    echo "🚀 Importing images to K3s containerd..."
    for service in "${services[@]}"; do
        echo "Importing mini-shop/$service:latest..."
        docker save mini-shop/$service:latest | sudo k3s ctr images import -
    done
    
    # Verify images in K3s
    echo "✅ Images in K3s:"
    sudo k3s ctr images ls | grep mini-shop
else
    echo "ℹ️ Not using K3s, skipping image import"
fi

echo "🔄 Applying Kubernetes manifests..."
kubectl apply -f config-k8s/mini-shop-k8s.yaml

echo "⏳ Waiting for deployments..."
kubectl rollout restart deployment orders-service -n mini-shop
kubectl rollout restart deployment products-service -n mini-shop  
kubectl rollout restart deployment notifications-service -n mini-shop

echo "✅ Done! Check status with:"
echo "kubectl get pods -n mini-shop"