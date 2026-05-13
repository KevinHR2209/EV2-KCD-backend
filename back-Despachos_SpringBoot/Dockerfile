# =============================================
# ETAPA 1: Build con Maven
# =============================================
FROM maven:3.9.6-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copiar solo el pom primero para aprovechar cache de dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar el codigo fuente y compilar
COPY src ./src
RUN mvn package -DskipTests -B

# =============================================
# ETAPA 2: Imagen final minima con usuario no root
# =============================================
FROM eclipse-temurin:21-jre-alpine

# Usuario no root por seguridad
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar el JAR generado en la etapa de build
COPY --from=build /app/target/*.jar app.jar

# Cambiar propietario al usuario no root
RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
