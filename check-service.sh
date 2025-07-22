#!/bin/bash

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_service() {
    local service=$1
    local port=$2
    local endpoint=${3:-actuator/health}

    echo "Verificando $service..."
    
    # Verificar si el contenedor está corriendo
    if ! docker compose ps $service | grep -q "healthy"; then
        echo -e "${RED}❌ $service no está corriendo${NC}"
        return 1
    fi

    # Esperar a que el servicio responda
    for i in {1..30}; do
        if curl -s "http://localhost:$port/$endpoint" > /dev/null; then
            echo -e "${GREEN}✅ $service está healthy${NC}"
            return 0
        fi
        echo "Esperando... ($i/30)"
        sleep 2
    done

    echo -e "${RED}❌ $service no responde${NC}"
    return 1
}

case "$1" in
    "nats")
        check_service "nats-server" "8222" "healthz"
        ;;
    "orders")
        check_service "orders-service" "8081"
        ;;
    "products")
        check_service "products-service" "8082"
        ;;
    "notifications")
        check_service "notifications-service" "8083"
        ;;
    "nginx")
        check_service "nginx" "8088" "health"
        ;;
    *)
        echo "Uso: ./check-service.sh [nats|orders|products|notifications|nginx]"
        exit 1
        ;;
esac