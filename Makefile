# Makefile para Mini-Shop
# Simplifica los comandos Docker más comunes

# make build          # Construir y desplegar todo
# make up             # Solo desplegar servicios existentes
# make info           # Ver URLs de acceso (puerto 8088)
# make health         # Verificar health checks
# make detect-ip      # Detectar IP recomendada
# make deploy-interactive  # Usar script interactivo

.PHONY: help build up down logs clean dev-up dev-down restart status health info shell-orders shell-products shell-notifications quick-build quick-restart

# Variables
COMPOSE_FILE = docker-compose.yml
DEV_COMPOSE_FILE = docker-compose.dev.yml
PROJECT_NAME = mini-shop

# Detectar Docker Compose command y usar project name
DOCKER_COMPOSE_CMD := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose -p $(PROJECT_NAME)"; else echo "docker-compose -p $(PROJECT_NAME)"; fi)

# Colores para output
GREEN = \033[0;32m
BLUE = \033[0;34m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

help: ## Mostrar ayuda
	@echo "$(BLUE)🚀 Mini-Shop - Comandos disponibles:$(NC)"
	@echo ""
	@echo "$(YELLOW)📦 Comandos principales:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "logs-" | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)📋 Comandos de logs:$(NC)"
	@grep -E '^logs-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Ejemplos de uso:$(NC)"
	@echo "  make build      # Construir y desplegar (puerto 8088)"
	@echo "  make up         # Solo desplegar servicios existentes"
	@echo "  make logs       # Ver logs en tiempo real"
	@echo "  make dev-up     # Solo infraestructura para desarrollo"

build: ## Construir servicios Java y crear imágenes Docker
	@echo "$(BLUE)📦 Construyendo servicios Java...$(NC)"
	mvn clean install -DskipTests
	@for service in orders-service products-service notifications-service; do \
		echo "$(BLUE)📦 Building $$service...$(NC)"; \
		cd $$service && mvn clean package -DskipTests && cd ..; \
	done
	@echo "$(BLUE)🐳 Construyendo imágenes Docker...$(NC)"
	$(DOCKER_COMPOSE_CMD) build --no-cache

up: build ## Desplegar todos los servicios (puerto 8088)
	@echo "$(BLUE)🚀 Desplegando servicios...$(NC)"
	$(DOCKER_COMPOSE_CMD) up -d
	@echo "$(GREEN)✅ Servicios desplegados!$(NC)"
	@make info

deploy: up ## Alias para up

down: ## Detener todos los servicios
	@echo "$(BLUE)🛑 Deteniendo servicios...$(NC)"
	$(DOCKER_COMPOSE_CMD) down
	@echo "$(GREEN)✅ Servicios detenidos$(NC)"

logs: ## Ver logs de todos los servicios
	$(DOCKER_COMPOSE_CMD) logs -f

logs-orders: ## Ver logs del servicio de orders
	$(DOCKER_COMPOSE_CMD) logs -f orders-service

logs-products: ## Ver logs del servicio de products
	$(DOCKER_COMPOSE_CMD) logs -f products-service

logs-notifications: ## Ver logs del servicio de notifications
	$(DOCKER_COMPOSE_CMD) logs -f notifications-service

logs-nats: ## Ver logs de NATS
	$(DOCKER_COMPOSE_CMD) logs -f nats-server

logs-nginx: ## Ver logs de Nginx
	$(DOCKER_COMPOSE_CMD) logs -f nginx

dev-up: ## Levantar solo infraestructura para desarrollo
	@echo "$(BLUE)🔧 Levantando infraestructura de desarrollo...$(NC)"
	$(DOCKER_COMPOSE_CMD) -f $(DEV_COMPOSE_FILE) up -d
	@echo "$(GREEN)✅ Infraestructura lista para desarrollo!$(NC)"
	@echo ""
	@echo "$(YELLOW)Ahora puedes ejecutar los servicios localmente:$(NC)"
	@echo "  cd orders-service && ./mvnw spring-boot:run"
	@echo "  cd products-service && ./mvnw spring-boot:run"
	@echo "  cd notifications-service && ./mvnw spring-boot:run"

dev-down: ## Detener infraestructura de desarrollo
	$(DOCKER_COMPOSE_CMD) -f $(DEV_COMPOSE_FILE) down

clean: ## Limpiar contenedores, imágenes y volúmenes
	@echo "$(BLUE)🧹 Limpiando contenedores...$(NC)"
	$(DOCKER_COMPOSE_CMD) down --remove-orphans
	$(DOCKER_COMPOSE_CMD) -f $(DEV_COMPOSE_FILE) down --remove-orphans 2>/dev/null || true
	@echo "$(BLUE)🧹 Limpiando imágenes...$(NC)"
	docker image prune -f
	docker system prune -f
	@echo "$(GREEN)✅ Limpieza completada$(NC)"

restart: down up ## Reiniciar todos los servicios

status: ## Ver estado de los servicios
	@echo "$(BLUE)📊 Estado de los servicios:$(NC)"
	$(DOCKER_COMPOSE_CMD) ps

health: ## Verificar health checks de los servicios
	@echo "$(BLUE)❤️  Verificando health checks...$(NC)"
	@echo ""
	@echo "$(YELLOW)Nginx (puerto 8088):$(NC)"
	@curl -s http://localhost:8088/health && echo " ✅" || echo " ❌"
	@echo "$(YELLOW)NATS:$(NC)"
	@curl -s http://localhost:8222/healthz && echo " ✅" || echo " ❌"
	@echo "$(YELLOW)Orders Service:$(NC)"
	@curl -s http://localhost:8088/health/orders && echo " ✅" || echo " ❌"
	@echo "$(YELLOW)Products Service:$(NC)"
	@curl -s http://localhost:8088/health/products && echo " ✅" || echo " ❌"
	@echo "$(YELLOW)Notifications Service:$(NC)"
	@curl -s http://localhost:8088/health/notifications && echo " ✅" || echo " ❌"

info: ## Mostrar información de acceso a los servicios
	@echo ""
	@echo "$(GREEN)🌐 Servicios disponibles (Puerto 8088):$(NC)"
	@echo "  • Portal Principal:      http://localhost:8088"
	@echo "  • Orders App:           http://localhost:8088/orders-app"
	@echo "  • Products App:         http://localhost:8088/products-app"
	@echo "  • Notifications App:    http://localhost:8088/notifications-app"
	@echo "  • H2 Console:          http://localhost:8088/h2-console"
	@echo "  • NATS Monitoring:     http://localhost:8222"
	@echo ""
	@echo "$(GREEN)🔍 Health Checks:$(NC)"
	@echo "  • General:             http://localhost:8088/health"
	@echo "  • Orders:              http://localhost:8088/health/orders"
	@echo "  • Products:            http://localhost:8088/health/products"
	@echo "  • Notifications:       http://localhost:8088/health/notifications"
	@echo ""
	@echo "$(YELLOW)💡 Para acceso externo, reemplaza 'localhost' con la IP del servidor$(NC)"

shell-orders: ## Abrir shell en el contenedor de orders
	$(DOCKER_COMPOSE_CMD) exec orders-service /bin/sh

shell-products: ## Abrir shell en el contenedor de products
	$(DOCKER_COMPOSE_CMD) exec products-service /bin/sh

shell-notifications: ## Abrir shell en el contenedor de notifications
	$(DOCKER_COMPOSE_CMD) exec notifications-service /bin/sh

shell-nginx: ## Abrir shell en el contenedor de nginx
	$(DOCKER_COMPOSE_CMD) exec nginx /bin/sh

# Comandos de desarrollo rápido
quick-build: ## Build rápido sin tests
	mvn clean install -DskipTests -T 1C

quick-restart: ## Restart rápido de un servicio específico
	@echo "¿Qué servicio quieres reiniciar?"
	@echo "1. orders-service"
	@echo "2. products-service" 
	@echo "3. notifications-service"
	@echo "4. nginx"
	@read -p "Selecciona (1-4): " choice; \
	case $$choice in \
		1) $(DOCKER_COMPOSE_CMD) restart orders-service ;; \
		2) $(DOCKER_COMPOSE_CMD) restart products-service ;; \
		3) $(DOCKER_COMPOSE_CMD) restart notifications-service ;; \
		4) $(DOCKER_COMPOSE_CMD) restart nginx ;; \
		*) echo "Opción inválida" ;; \
	esac

# Comandos de diagnóstico
detect-ip: ## Detectar IP recomendada para el servidor
	@if [ -f "./detect-ip.sh" ]; then \
		echo "$(BLUE)🔍 Detectando IP recomendada...$(NC)"; \
		./detect-ip.sh; \
	else \
		echo "$(RED)❌ Script detect-ip.sh no encontrado$(NC)"; \
	fi

test-connectivity: ## Probar conectividad de servicios
	@if [ -f "./test-vpn-connectivity.sh" ]; then \
		echo "$(BLUE)🔍 Probando conectividad...$(NC)"; \
		./test-vpn-connectivity.sh; \
	else \
		echo "$(RED)❌ Script test-vpn-connectivity.sh no encontrado$(NC)"; \
	fi

# Comandos de despliegue con script
deploy-interactive: ## Usar script interactivo de despliegue
	@if [ -f "./compose-deploy.sh" ]; then \
		./compose-deploy.sh; \
	else \
		echo "$(RED)❌ Script compose-deploy.sh no encontrado$(NC)"; \
	fi
