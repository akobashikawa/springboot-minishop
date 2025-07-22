@echo off
REM 🚀 Script de construcción y despliegue para Mini-Shop (Windows)
REM Versión: 1.0

echo 🚀 Mini-Shop - Build ^& Deploy Script
echo ========================================
echo.

REM Variables
set PROJECT_NAME=mini-shop
set TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

echo ¿Qué operación deseas realizar?
echo 1. 🔨 Build completo (limpiar + construir + desplegar)
echo 2. 🚀 Solo desplegar (usar imágenes existentes)
echo 3. 🧹 Solo limpiar
echo 4. 📦 Solo construir (sin desplegar)
echo 5. 🔍 Ver estado de servicios
echo 6. 📋 Ver logs
echo.
set /p choice="Selecciona una opción (1-6): "

if "%choice%"=="1" goto build_complete
if "%choice%"=="2" goto deploy_only
if "%choice%"=="3" goto cleanup_only
if "%choice%"=="4" goto build_only
if "%choice%"=="5" goto show_status
if "%choice%"=="6" goto show_logs
goto invalid_option

:build_complete
echo.
echo ➤ Verificando dependencias...
call :check_dependencies
if errorlevel 1 exit /b 1

echo ➤ Limpiando containers anteriores...
call :cleanup

echo ➤ Construyendo servicios Java...
call :build_services
if errorlevel 1 exit /b 1

echo ➤ Construyendo imágenes Docker...
call :build_images
if errorlevel 1 exit /b 1

echo ➤ Desplegando servicios...
call :deploy
if errorlevel 1 exit /b 1

echo ➤ Verificando despliegue...
call :verify_deployment

call :show_info
goto end

:deploy_only
echo.
echo ➤ Verificando dependencias...
call :check_dependencies
if errorlevel 1 exit /b 1

echo ➤ Desplegando servicios...
call :deploy
if errorlevel 1 exit /b 1

echo ➤ Verificando despliegue...
call :verify_deployment

call :show_info
goto end

:cleanup_only
echo.
echo ➤ Limpiando containers anteriores...
call :cleanup
echo ✅ Limpieza completada
goto end

:build_only
echo.
echo ➤ Verificando dependencias...
call :check_dependencies
if errorlevel 1 exit /b 1

echo ➤ Construyendo servicios Java...
call :build_services
if errorlevel 1 exit /b 1

echo ➤ Construyendo imágenes Docker...
call :build_images
if errorlevel 1 exit /b 1

echo ✅ Construcción completada
goto end

:show_status
%DOCKER_COMPOSE_CMD% ps
echo.
%DOCKER_COMPOSE_CMD% logs --tail=50
goto end

:show_logs
echo.
echo ¿De qué servicio quieres ver los logs?
echo 1. Todos
echo 2. Orders
echo 3. Products
echo 4. Notifications
echo 5. NATS
echo 6. Nginx
set /p log_choice="Selecciona (1-6): "

if "%log_choice%"=="1" %DOCKER_COMPOSE_CMD% logs -f
if "%log_choice%"=="2" %DOCKER_COMPOSE_CMD% logs -f orders-service
if "%log_choice%"=="3" %DOCKER_COMPOSE_CMD% logs -f products-service
if "%log_choice%"=="4" %DOCKER_COMPOSE_CMD% logs -f notifications-service
if "%log_choice%"=="5" %DOCKER_COMPOSE_CMD% logs -f nats-server
if "%log_choice%"=="6" %DOCKER_COMPOSE_CMD% logs -f nginx
goto end

:invalid_option
echo Opción inválida
exit /b 1

REM ========================================
REM FUNCIONES
REM ========================================

:check_dependencies
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker no está instalado
    exit /b 1
)

REM Verificar Docker Compose (nueva versión integrada o standalone)
docker compose version >nul 2>&1
if errorlevel 1 (
    docker-compose --version >nul 2>&1
    if errorlevel 1 (
        echo ❌ Docker Compose no está disponible
        echo    Instala Docker Compose o actualiza Docker a una versión que lo incluya
        exit /b 1
    ) else (
        echo ✅ Usando Docker Compose (standalone)
        set DOCKER_COMPOSE_CMD=docker-compose
    )
) else (
    echo ✅ Usando Docker Compose (integrado)
    set DOCKER_COMPOSE_CMD=docker compose
)

mvn --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Maven no está instalado
    exit /b 1
)

echo ✅ Todas las dependencias están disponibles
exit /b 0

:cleanup
%DOCKER_COMPOSE_CMD% down --remove-orphans 2>nul
docker system prune -f 2>nul
exit /b 0

:build_services
echo 📦 Building root project...
mvn clean install -DskipTests
if errorlevel 1 exit /b 1

echo 📦 Building orders-service...
cd orders-service
mvn clean package -DskipTests
if errorlevel 1 exit /b 1
cd ..

echo 📦 Building products-service...
cd products-service
mvn clean package -DskipTests
if errorlevel 1 exit /b 1
cd ..

echo 📦 Building notifications-service...
cd notifications-service
mvn clean package -DskipTests
if errorlevel 1 exit /b 1
cd ..

echo ✅ Todos los servicios construidos exitosamente
exit /b 0

:build_images
%DOCKER_COMPOSE_CMD% build --no-cache
if errorlevel 1 exit /b 1
echo ✅ Imágenes Docker construidas exitosamente
exit /b 0

:deploy
%DOCKER_COMPOSE_CMD% up -d
if errorlevel 1 exit /b 1
echo ✅ Servicios desplegados exitosamente
exit /b 0

:verify_deployment
echo Esperando que los servicios estén listos...
timeout /t 30 /nobreak >nul

echo 🔍 Verificando servicios...
REM Aquí podrías agregar checks específicos con curl si está disponible
echo ⏳ Los servicios están iniciando... Verifica manualmente en el browser
exit /b 0

:show_info
echo.
echo ➤ Información de los servicios:
echo.
echo 🌐 Acceso a los servicios:
echo   • Mini-Shop Portal:      http://localhost
echo   • Orders Service:        http://localhost/orders-app
echo   • Products Service:      http://localhost/products
echo   • Notifications Service: http://localhost/notifications-app
echo   • H2 Console:           http://localhost/h2-console
echo   • NATS Monitoring:      http://localhost:8222
echo.
echo 🔍 Health Checks:
echo   • General:              http://localhost/health
echo   • Orders:               http://localhost/health/orders
echo   • Products:             http://localhost/health/products
echo   • Notifications:        http://localhost/health/notifications
echo.
echo 📊 Logs:
echo   • Ver todos los logs:   %DOCKER_COMPOSE_CMD% logs -f
echo   • Ver logs específicos: %DOCKER_COMPOSE_CMD% logs -f [service-name]
echo.
exit /b 0

:end
echo.
echo 🎉 Proceso completado!
pause
