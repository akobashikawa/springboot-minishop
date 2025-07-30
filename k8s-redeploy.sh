#!/bin/bash

echo "🔧 Fixing NATS configuration issue..."

# Apply the corrected configuration
kubectl apply -f config-k8s/mini-shop-k8s.yaml

# Restart all deployments to pick up new config
echo "🔄 Restarting deployments..."
kubectl rollout restart deployment orders-service -n mini-shop
kubectl rollout restart deployment products-service -n mini-shop
kubectl rollout restart deployment notifications-service -n mini-shop

# Wait for rollout to complete
echo "⏳ Waiting for deployments to complete..."
kubectl rollout status deployment orders-service -n mini-shop
kubectl rollout status deployment products-service -n mini-shop
kubectl rollout status deployment notifications-service -n mini-shop

echo "✅ Fixed! Checking pod status:"
kubectl get pods -n mini-shop