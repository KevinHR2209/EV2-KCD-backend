# EJKEVIN — Plataforma Innovatech Chile

Proyecto de contenedorización y despliegue automatizado desarrollado para la EP2 del curso ISY1101 - Introducción a Herramientas DevOps.

La plataforma está compuesta por un **frontend en React/Vite**, dos **microservicios Spring Boot** (Despachos y Ventas) y una base de datos **MySQL 8**, todo orquestado con Docker Compose y desplegado en AWS EC2 mediante un pipeline CI/CD en GitHub Actions.

---

## Arquitectura del sistema

```
Internet
   │
   ▼
┌──────────────────────────────┐
│  EC2 Pública (Frontend)      │
│  Puerto 80 → Nginx           │
│  Contenedor: frontendapp     │
└──────────────┬───────────────┘
               │ Red privada (Security Group)
               ▼
┌──────────────────────────────┐
│  EC2 Privada (Backend)       │
│  ├── msdespacho  :8081       │
│  ├── msventas    :8082       │
│  └── mysqldb     :3306       │
└──────────────────────────────┘
```

**Solo el frontend es accesible desde Internet.**  
El backend opera en subred privada y solo acepta tráfico desde el Security Group del frontend.

---

## Estructura del repositorio

```
EJKEVIN/
├── docker-compose.yml              # Orquestación de todos los servicios
├── .env.example                    # Variables de entorno (plantilla)
├── mysql-init/
│   └── init.sql                    # Crea despacho_db y ventas_db al iniciar
├── front_despacho/                 # Frontend React + Vite
│   ├── Dockerfile                  # Multi-stage: Node build + Nginx serve
│   ├── .dockerignore
│   ├── .env.example
│   └── src/
├── back-Despachos_SpringBoot/
│   └── Springboot-API-REST-DESPACHO/
│       ├── Dockerfile              # Multi-stage: Maven build + JRE Alpine
│       ├── .dockerignore
│       └── src/
├── back-Ventas_SpringBoot/
│   └── Springboot-API-REST/
│       ├── Dockerfile              # Multi-stage: Maven build + JRE Alpine
│       ├── .dockerignore
│       └── src/
└── .github/
    └── workflows/
        └── deploy.yml              # Pipeline CI/CD GitHub Actions
```

---

## Requisitos previos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado
- [Docker Compose](https://docs.docker.com/compose/) (incluido en Docker Desktop)
- [Git](https://git-scm.com/)

---

## Ejecución local

### 1. Clonar el repositorio
```bash
git clone https://github.com/KevinHR2209/EJKEVIN.git
cd EJKEVIN
```

### 2. Crear archivo de variables de entorno
```bash
cp .env.example .env
```
El archivo `.env` ya contiene valores por defecto para desarrollo local. No es necesario modificar nada para ejecutar localmente.

### 3. Levantar todos los servicios
```bash
docker compose up --build
```

### 4. Verificar que todo funciona

| Servicio | URL |
|---|---|
| Frontend | http://localhost |
| API Despachos (Swagger) | http://localhost:8081/swagger-ui.html |
| API Ventas (Swagger) | http://localhost:8082/swagger-ui.html |
| MySQL | localhost:3306 |

### 5. Detener los servicios
```bash
docker compose down
```

---

## Persistencia de datos

La base de datos MySQL utiliza un **named volume** (`mysql_data`):

```yaml
volumes:
  mysql_data:
```

**¿Por qué named volume y no bind mount?**  
Los named volumes son gestionados completamente por Docker, son portables entre entornos (local y EC2) y no dependen de rutas absolutas del sistema operativo host. Un bind mount requeriría una ruta física específica en cada máquina, lo que dificulta el despliegue en AWS EC2.

Para comprobar la persistencia:
```bash
# 1. Levantar y crear datos en la app
docker compose up -d

# 2. Bajar los contenedores (SIN -v para no borrar el volumen)
docker compose down

# 3. Volver a levantar — los datos siguen ahí
docker compose up -d
```

---

## Descripción de los Dockerfiles

### Frontend (`front_despacho/Dockerfile`)
- **Etapa 1 (build):** imagen `node:20-alpine` — instala dependencias y compila el proyecto con Vite
- **Etapa 2 (serve):** imagen `nginx:stable-alpine` — sirve los archivos estáticos compilados
- Las variables `VITE_API_DESPACHO` y `VITE_API_VENTAS` se inyectan como `ARG` en tiempo de build

### Backend Despachos y Ventas (`Dockerfile`)
- **Etapa 1 (build):** imagen `maven:3.9.9-eclipse-temurin-17` — compila el JAR con Maven
- **Etapa 2 (runtime):** imagen `eclipse-temurin:17-jre-alpine` — solo contiene el JRE, sin Maven ni código fuente
- **Usuario no root:** se crea el usuario `spring` aplicando el principio de mínimo privilegio
- **Resultado:** imagen final ~80% más liviana que usando la imagen completa de Maven

---

## Variables de entorno

Copia `.env.example` como `.env` y ajusta los valores según el entorno:

| Variable | Descripción | Local | Producción |
|---|---|---|---|
| `MYSQL_ROOT_PASSWORD` | Contraseña root MySQL | `root123` | secret seguro |
| `DB_USERNAME` | Usuario de base de datos | `root` | `root` |
| `DB_PASSWORD` | Contraseña de base de datos | `root123` | secret seguro |
| `VITE_API_DESPACHO` | URL del ms-despacho | `http://localhost:8081` | `http://<IP_EC2_BACK>:8081` |
| `VITE_API_VENTAS` | URL del ms-ventas | `http://localhost:8082` | `http://<IP_EC2_BACK>:8082` |

---

## Pipeline CI/CD

El workflow `.github/workflows/deploy.yml` se activa automáticamente con cada `push` a la rama **`deploy`**.

### Flujo del pipeline

```
push a rama deploy
        │
        ▼
  1. Checkout del código
        │
        ▼
  2. Login a Docker Hub
        │
        ▼
  3. Build y Push de las 3 imágenes
  (frontend + ms-despacho + ms-ventas)
        │
        ▼
  4. SSH a EC2 Backend → docker compose up -d
        │
        ▼
  5. SSH a EC2 Frontend → docker compose up -d
```

### Secrets requeridos en GitHub

Ve a **Settings → Secrets and variables → Actions** y agrega:

| Secret | Descripción |
|---|---|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Access token de Docker Hub |
| `EC2_HOST_FRONT` | IP pública de EC2 frontend |
| `EC2_HOST_BACK` | IP privada de EC2 backend |
| `EC2_USER` | Usuario SSH (`ec2-user`) |
| `SSH_PRIVATE_KEY` | Contenido del archivo `.pem` |
| `MYSQL_ROOT_PASSWORD` | Contraseña root MySQL |
| `DB_PASSWORD` | Contraseña de base de datos |
| `VITE_API_DESPACHO` | URL pública del ms-despacho |
| `VITE_API_VENTAS` | URL pública del ms-ventas |

---

## Integrantes

- Kevin Hernández R.

---

## Tecnologías utilizadas

- React 18 + Vite + TailwindCSS
- Spring Boot 3 (Java 17)
- MySQL 8.0
- Docker + Docker Compose
- GitHub Actions (CI/CD)
- AWS EC2
- Nginx
