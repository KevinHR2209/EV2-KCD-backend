# ETAPA 1: compilar el proyecto
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# ETAPA 2: imagen final liviana
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Usuario no root (seguridad)
RUN addgroup -S spring && adduser -S spring -G spring

COPY --from=build /app/target/*.jar app.jar
RUN chown -R spring:spring /app
USER spring

EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
