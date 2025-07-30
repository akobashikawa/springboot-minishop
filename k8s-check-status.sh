#!/bin/bash
echo "🔍 Verificando estado de Mini-Shop en Kubernetes..."
echo "================================================="

echo "📦 Pods:"
kubectl get pods -n mini-shop

echo ""
echo "🔗 Services:"
kubectl get svc -n mini-shop

echo ""
echo "🌐 Ingress:"
kubectl get ingress -n mini-shop

echo ""
echo "❤️ Health Checks:"
curl -s http://52.168.134.57/health && echo " ✅ General OK" || echo " ❌ General FAIL"
curl -s http://52.168.134.57/health/orders && echo " ✅ Orders OK" || echo " ❌ Orders FAIL"
curl -s http://52.168.134.57/health/products && echo " ✅ Products OK" || echo " ❌ Products FAIL"
curl -s http://52.168.134.57/health/notifications && echo " ✅ Notifications OK" || echo " ❌ Notifications FAIL"