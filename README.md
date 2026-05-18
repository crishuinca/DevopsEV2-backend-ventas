# InnovaTech — Backend Ventas (Spring Boot)

**Descripción**  
API REST de ventas (Spring Boot 3, Java 21). Imagen Docker multi-stage, registro en **ECR** y despliegue automático en la **EC2 backend** al hacer push a la rama `deploy`. Se conecta a MySQL en la misma instancia backend (`mysql-innovatech`, puerto 3306).

---

## 🧭 Estructura del proyecto

```
DevopsEV2-backend-ventas/
├── README.md
├── .github/workflows/deploy.yml
└── Springboot-API-REST/
    ├── src/main/java/com/citt/
    ├── Dockerfile
    ├── docker-compose.yml      # API + MySQL local
    ├── entrypoint.sh
    └── pom.xml
```

---

## 🚀 Requisitos

- Docker y Docker Compose v2
- Java 21 y Maven 3.9+ (desarrollo sin Docker)
- AWS Academy Learner Lab (despliegue)
- Secrets GitHub documentados en `infra/README.md`

---

## ⚙️ Flujo de uso

### Local (solo este servicio)

```bash
cd Springboot-API-REST
docker compose up -d --build
```

API: **http://localhost:8081**  
Swagger: **http://localhost:8081/swagger-ui.html**

### Despliegue AWS

1. Aplicar Terraform (`infra`).
2. Configurar secrets: `EC2_HOST` = IP pública backend, `DB_PRIVATE_IP` = IP **privada** backend.
3. Push a **`deploy`** → GitHub Actions → ECR → EC2 puerto **8081**.

---

## 📦 ¿Qué despliega este proyecto?

| Entorno | Contenedor | Puerto |
|---------|------------|--------|
| Local | `backend-ventas` | 8081 → 8080 |
| Local | `db-ventas` (MySQL 8) | 3306 |
| AWS | `innovatech-backend-ventas` | 8081 (solo accesible desde SG del frontend) |
| AWS | `mysql-innovatech` (host) | 3306, BD `ventas_db` |

Variables en deploy: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`.

---

## 🧭 Diagrama de arquitectura

```
GitHub (rama deploy) → Actions → ECR
                              ↓ SSH
                    EC2 Backend (pública para CI, APIs privadas)
                    ├── mysql-innovatech:3306
                    └── innovatech-backend-ventas:8081
                              ↑
                    EC2 Frontend (proxy /api/v1/ventas)
```

---

## 📌 Mejores prácticas incluidas

**Multi-stage Dockerfile:** `maven` compila el JAR; runtime `eclipse-temurin:21-jre`.

**Usuario no-root:** usuario/grupo `spring`, directiva `USER spring:spring`.

**Volúmenes**

| Tipo | Dónde | Motivo |
|------|--------|--------|
| **Named volume** | `docker-compose.yml` → `ventas-data-local:/var/lib/mysql` | En local, los datos de ventas sobreviven a `docker compose down` sin borrar volúmenes. |
| Sin volumen en deploy API | `deploy.yml` | La app es stateless; la persistencia es responsabilidad del contenedor MySQL en el host. |

**MySQL en EC2:** un solo contenedor `mysql-innovatech` compartido con despachos (segunda BD creada por script en deploy).

**CI/CD:** build → push `innovatech-backend-ventas:latest` → SSH → swap 1G si hace falta → espera MySQL → `docker run`.

---

## 🔧 Cómo extender este proyecto

- Añadir `-v mysql-data:/var/lib/mysql` en el `docker run` de MySQL en EC2 para persistencia explícita.
- Perfiles Spring (`application-prod.properties`) por ambiente.
- Tests en el pipeline antes del push a ECR.
- Métricas con Actuator + health en el workflow.
