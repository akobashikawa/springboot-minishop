#!/bin/bash

# 🚀 Script de construcción y despliegue para Mini-Shop
# Versión: 1.0

set -e  # Salir si cualquier comando falla

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Mini-Shop - Build & Deploy Script${NC}"
echo "========================================"
echo ""

# Variables
PROJECT_NAME="mini-shop"
VERSION=$(date +%Y%m%d-%H%M%S)

# Función para imprimir mensajes
print_step() {
    echo -e "${GREEN}➤ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Variables
PROJECT_NAME="mini-shop"
VERSION=$(date +%Y%m%d-%H%M%S)

# Set Docker Compose command based on availability
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    DOCKER_COMPOSE_CMD=""
fi

# Verificar dependencias
check_dependencies() {
    print_step "Verificando dependencias..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        exit 1
    fi
    
    # Verificar Docker Compose
    if [ -z "$DOCKER_COMPOSE_CMD" ]; then
        print_error "Docker Compose no está disponible"
        print_error "Instala Docker Compose o actualiza Docker a una versión que lo incluya"
        exit 1
    fi
    
    if ! command -v mvn &> /dev/null; then
        print_error "Maven no está instalado"
        exit 1
    fi
    
    echo "✅ Todas las dependencias están disponibles"
}

# Limpiar containers anteriores
cleanup() {
    print_step "Limpiando containers anteriores..."
    if [ -n "$DOCKER_COMPOSE_CMD" ]; then
        ${DOCKER_COMPOSE_CMD} down --remove-orphans || true
    fi
    docker system prune -f || true
}

# Construir aplicaciones Java
build_services() {
    print_step "Construyendo servicios Java..."
    
    # Build root project
    echo "📦 Building root project..."
    mvn clean install -DskipTests
    
    # Build each service
    for service in orders-service products-service notifications-service; do
        echo "📦 Building $service..."
        cd $service
        mvn clean package -DskipTests
        cd ..
    done
    
    echo "✅ Todos los servicios construidos exitosamente"
}

# Construir imágenes Docker
build_images() {
    print_step "Construyendo imágenes Docker..."
    
    # Usar docker compose para build
    $DOCKER_COMPOSE_CMD build --no-cache
    
    echo "✅ Imágenes Docker construidas exitosamente"
}

# Desplegar servicios
deploy() {
    print_step "Desplegando servicios..."
    
    # Levantar servicios
    $DOCKER_COMPOSE_CMD up -d
    
    echo "✅ Servicios desplegados exitosamente"
}

# Verificar health checks
verify_deployment() {
    print_step "Verificando despliegue..."
    
    echo "Esperando que los servicios estén listos..."
    sleep 30
    
    # Verificar cada servicio - usando puerto 8088 para nginx
    services=("localhost:8088/health" "nats-server:8222/healthz" "orders-service:8081/actuator/health" "products-service:8082/actuator/health" "notifications-service:8083/actuator/health")
    
    for service_endpoint in "${services[@]}"; do
        if [[ "$service_endpoint" == localhost* ]]; then
            service_name="nginx"
            endpoint="http://$service_endpoint"
        else
            service_name=$(echo $service_endpoint | cut -d':' -f1)
            endpoint="http://localhost:$(echo $service_endpoint | cut -d':' -f2-)"
        fi
        
        echo "🔍 Verificando $service_name..."
        
        for i in {1..10}; do
            if curl -s -f "$endpoint" > /dev/null; then
                echo "✅ $service_name está funcionando"
                break
            else
                if [ $i -eq 10 ]; then
                    print_warning "$service_name no responde después de 10 intentos"
                else
                    echo "⏳ Intento $i/10 para $service_name..."
                    sleep 5
                fi
            fi
        done
    done
}

# Mostrar información de los servicios
show_info() {
    print_step "Información de los servicios:"
    echo ""
    echo "🌐 Acceso a los servicios (Puerto 8088):"
    echo "  • Mini-Shop Portal:      http://localhost:8088"
    echo "  • Orders Service:        http://localhost:8088/orders-app"
    echo "  • Products Service:      http://localhost:8088/products-app"
    echo "  • Notifications Service: http://localhost:8088/notifications-app"
    echo "  • H2 Console:           http://localhost:8088/h2-console"
    echo "  • NATS Monitoring:      http://localhost:8222"
    echo ""
    echo "🔍 Health Checks:"
    echo "  • General:              http://localhost:8088/health"
    echo "  • Orders:               http://localhost:8088/health/orders"
    echo "  • Products:             http://localhost:8088/health/products"  
    echo "  • Notifications:        http://localhost:8088/health/notifications"
    echo ""
    echo "📊 Logs:"
    echo "  • Ver todos los logs:   $DOCKER_COMPOSE_CMD logs -f"
    echo "  • Ver logs específicos: $DOCKER_COMPOSE_CMD logs -f [service-name]"
    echo ""
}

# Función principal
main() {
    echo "¿Qué operación deseas realizar?"
    echo "1. 🔨 Build completo (limpiar + construir + desplegar)"
    echo "2. 🚀 Solo desplegar (usar imágenes existentes)"
    echo "3. 🧹 Solo limpiar"
    echo "4. 📦 Solo construir (sin desplegar)"
    echo "5. 🔍 Ver estado de servicios"
    echo "6. 📋 Ver logs"
    echo ""
    read -p "Selecciona una opción (1-6): " choice
    
    case $choice in
        1)
            check_dependencies
            cleanup
            build_services
            build_images
            deploy
            verify_deployment
            show_info
            ;;
        2)
            check_dependencies
            deploy
            verify_deployment
            show_info
            ;;
        3)
            cleanup
            echo "✅ Limpieza completada"
            ;;
        4)
            check_dependencies
            build_services
            build_images
            echo "✅ Construcción completada"
            ;;
        5)
            $DOCKER_COMPOSE_CMD ps
            echo ""
            $DOCKER_COMPOSE_CMD logs --tail=50
            ;;
        6)
            echo "¿De qué servicio quieres ver los logs?"
            echo "1. Todos"
            echo "2. Orders"
            echo "3. Products"
            echo "4. Notifications"
            echo "5. NATS"
            echo "6. Nginx"
            read -p "Selecciona (1-6): " log_choice
            
            case $log_choice in
                1) $DOCKER_COMPOSE_CMD logs -f ;;
                2) $DOCKER_COMPOSE_CMD logs -f orders-service ;;
                3) $DOCKER_COMPOSE_CMD logs -f products-service ;;
                4) $DOCKER_COMPOSE_CMD logs -f notifications-service ;;
                5) $DOCKER_COMPOSE_CMD logs -f nats-server ;;
                6) $DOCKER_COMPOSE_CMD logs -f nginx ;;
                *) echo "Opción inválida" ;;
            esac
            ;;
        *)
            echo "Opción inválida"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main
