# -------------------------------------------------------------
# Etapa 1: BUILD (Compilación de la aplicación Java)
# -------------------------------------------------------------
FROM maven:3.8.5-openjdk-17-slim AS builder

# Metadatos para la etapa de build (opcional, pero útil para referencia)
LABEL maintainer="mini-shop"
LABEL service="notifications-service"
LABEL stage="build"

# Crear directorio de trabajo para el proyecto Maven
WORKDIR /usr/src/app

# Copiar el archivo POM (Project Object Model) primero para aprovechar el caché de capas
# Si el pom.xml no cambia, Maven no descargará de nuevo las dependencias.
COPY pom.xml .

# Descargar las dependencias para la capa de caché.
# Usar 'dependency:go-offline' es una buena práctica para asegurar que todas las dependencias se descargan
# antes de copiar el código fuente.
RUN mvn dependency:go-offline -B

# Copiar todo el código fuente de la aplicación
COPY src ./src

# Construir la aplicación Spring Boot.
# Usa -DskipTests para saltar los tests si no quieres ejecutarlos durante la construcción de la imagen.
# O omite -DskipTests si quieres que los tests se ejecuten.
RUN mvn package -DskipTests

# El JAR generado estará en target/orders-service-*.jar


# -------------------------------------------------------------
# Etapa 2: RUN (Ejecución de la aplicación en un entorno de producción ligero)
# -------------------------------------------------------------
FROM openjdk:17-jdk-slim

# Metadatos para la imagen final
LABEL maintainer="mini-shop"
LABEL service="notifications-service"
LABEL version="1.0"
LABEL stage="run"

# Instalar herramientas necesarias (solo si son realmente requeridas en tiempo de ejecución)
# curl es útil para los health checks
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Crear usuario no-root para seguridad
RUN groupadd -r spring && useradd -r -g spring spring

# Copiar el JAR construido desde la etapa 'builder'
# Asumimos que el JAR se llama notifications-service-<version>.jar.
# Puedes usar un comodín * si el nombre exacto de la versión cambia.
COPY --from=builder /usr/src/app/target/notifications-service-*.jar app.jar

# Copiar archivos estáticos (public) - si son servidos por Spring Boot
# Asegúrate de que tu estructura de proyecto de Spring Boot realmente sirva estos archivos desde /app/public/.
# Si estos archivos no existen o no son usados por el JAR, puedes omitir esta línea.
COPY public/ /app/public/

# Cambiar propietario de los archivos para el usuario no-root
RUN chown -R spring:spring /app

# Cambiar a usuario no-root para ejecutar la aplicación
USER spring

# Puerto que expone el servicio
EXPOSE 8083

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8083/actuator/health

# Variables de entorno por defecto
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SPRING_PROFILES_ACTIVE="docker"

# Comando para ejecutar la aplicación
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]