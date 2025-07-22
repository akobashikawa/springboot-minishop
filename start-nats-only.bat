@echo off
REM Script para levantar solo NATS dedicado para Mini-Shop (Windows)

echo 🚀 Iniciando NATS dedicado para Mini-Shop
echo ==========================================
echo.

REM Verificar si Docker está corriendo
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker no está corriendo
    pause
    exit /b 1
)

REM Verificar si ya existe un contenedor de NATS
docker ps -a --format "table {{.Names}}" | findstr "mini-shop-nats" >nul
if not errorlevel 1 (
    echo ⚠️  Ya existe un contenedor mini-shop-nats
    set /p response="¿Quieres eliminarlo y crear uno nuevo? (y/n): "
    if /i "%response%"=="y" (
        docker rm -f mini-shop-nats-dev 2>nul
        docker rm -f mini-shop-nats 2>nul
    ) else (
        echo Abortando...
        pause
        exit /b 1
    )
)

REM Crear red si no existe
docker network create mini-shop-dev-net 2>nul

REM Iniciar NATS
echo 🔄 Iniciando NATS en puerto 4222...
docker run -d ^
    --name mini-shop-nats ^
    --network mini-shop-dev-net ^
    -p 4222:4222 ^
    -p 8222:8222 ^
    -p 6222:6222 ^
    nats:2.10-alpine ^
    --http_port 8222 ^
    --name mini-shop-nats-standalone ^
    --server_name mini-shop-standalone

REM Esperar que NATS esté listo
echo ⏳ Esperando que NATS esté listo...
timeout /t 5 /nobreak >nul

REM Verificar que NATS está funcionando
curl -s http://localhost:8222/healthz >nul 2>&1
if not errorlevel 1 (
    echo ✅ NATS está corriendo correctamente!
    echo.
    echo 🌐 Accesos disponibles:
    echo   • NATS Client:    nats://localhost:4222
    echo   • NATS Monitor:   http://localhost:8222
    echo.
    echo 🔧 Para desarrollar con este NATS:
    echo   set SPRING_PROFILES_ACTIVE=local-with-docker-nats
    echo   cd orders-service ^&^& mvnw spring-boot:run
    echo   cd products-service ^&^& mvnw spring-boot:run
    echo   cd notifications-service ^&^& mvnw spring-boot:run
    echo.
    echo 🛑 Para detener NATS:
    echo   docker stop mini-shop-nats ^&^& docker rm mini-shop-nats
) else (
    echo ❌ NATS no está respondiendo
    echo Ver logs: docker logs mini-shop-nats
    pause
    exit /b 1
)

echo.
pause
