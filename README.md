# EV2-KCD-backend — Innovatech Chile

Backend compuesto por dos microservicios Spring Boot para el sistema de Innovatech Chile.
Evaluación Parcial N°2 — ISY1101 Introducción a Herramientas DevOps.

---

## 🏗️ Arquitectura

```
                     Subred Privada AWS
┌──────────────────────────────────────────┐
│  EC2 Backend                           │
│  ┌───────────────┐  ┌──────────────┐  │
│  │ Despachos    │  │ Ventas       │  │
│  │ :8080        │  │ :8081        │  │
│  └────────┤─────┘  └───────┤──────┘  │
│           │                  │           │
│           └────▼──────────┘           │
│        ┌───────────┐                   │
│        │ MySQL:3306 │                   │
│        │ (volumen)  │                   │
│        └───────────┘                   │
└──────────────────────────────────────────┘
```

- Solo accesible desde el Frontend (subred privada).
- Ambos servicios comparten la misma instancia EC2.
- Base de datos MySQL con volumen Docker para persistencia.

---

## 📁 Estructura del Repositorio

```
EV2-KCD-backend/
├── back-Despachos_SpringBoot/
│   ├── Dockerfile          # Multi-stage build, usuario no root
│   ├── pom.xml
│   └── src/
├── back-Ventas_SpringBoot/
│   ├── Dockerfile          # Multi-stage build, usuario no root
│   ├── pom.xml
└── src/
└── .github/workflows/
    ├── deploy-despachos.yml
    └── deploy-ventas.yml
```

---

## 🐳 Dockerfiles (Multi-stage)

Ambos servicios usan la misma estrategia:

| Etapa | Imagen base | Propósito |
|---|---|---|
| `build` | `maven:3.9.6-eclipse-temurin-21-alpine` | Compilar el JAR |
| `run` | `eclipse-temurin:21-jre-alpine` | Solo el JRE, sin Maven |

- Imagen final: ~180MB (vs ~600MB sin multi-stage).
- Corre con **usuario no root** (`appuser`) por seguridad.
- Despachos expone puerto **8080**, Ventas expone puerto **8081**.

---

## ⚙️ Variables de Entorno

| Variable | Descripción |
|---|---|
| `SPRING_DATASOURCE_URL` | URL JDBC (ej: `jdbc:mysql://mysql:3306/db`) |
| `SPRING_DATASOURCE_USERNAME` | Usuario de la BD |
| `SPRING_DATASOURCE_PASSWORD` | Contraseña de la BD |

---

## 🚀 Levantar Localmente

```bash
# Despachos
cd back-Despachos_SpringBoot
docker build -t back-despachos .
docker run -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/db \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=secret \
  back-despachos

# Ventas
cd back-Ventas_SpringBoot
docker build -t back-ventas .
docker run -p 8081:8081 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/db \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=secret \
  back-ventas
```

---

## 🔄 Pipeline CI/CD

Cada microservicio tiene su propio workflow, activado con **push a la rama `deploy`**:

```
push a rama deploy
       │
       ▼
  1. Checkout codigo
       │
       ▼
  2. Configurar credenciales AWS
       │
       ▼
  3. Login a Amazon ECR
       │
       ▼
  4. mvn package → docker build → docker push → ECR
       │
       ▼
  5. SSH a EC2 → docker pull → docker run
```

### GitHub Secrets requeridos

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS |
| `AWS_REGION` | Región AWS (ej: `us-east-1`) |
| `ECR_REGISTRY` | URL del registro ECR |
| `ECR_REPO_DESPACHOS` | Nombre del repo ECR para Despachos |
| `ECR_REPO_VENTAS` | Nombre del repo ECR para Ventas |
| `EC2_HOST_BACKEND` | IP o DNS de la EC2 backend |
| `EC2_USER` | Usuario SSH (ej: `ec2-user`) |
| `EC2_SSH_KEY` | Clave privada SSH (`.pem`) |
| `DB_URL` | URL JDBC de MySQL |
| `DB_USER` | Usuario de la BD |
| `DB_PASSWORD` | Contraseña de la BD |

---

## 🛡️ Seguridad

- Contenedores corren con **usuario no root**.
- Credenciales gestionadas como **GitHub Secrets** (nunca en el código).
- Backend en **subred privada** de AWS, sin acceso directo desde Internet.

---

## 👥 Equipo

- **Kevin HR** — KevinHR2209
