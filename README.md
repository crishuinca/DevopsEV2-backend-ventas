# InnovaTech — Backend Ventas (Spring Boot)

**Descripción**  
API REST de ventas (Spring Boot 3, Java 21). Imagen Docker multi-stage, registro en **ECR** y despliegue en **EKS** orquestado por el pipeline central de `DevopsEV2-infra`. Se conecta a MySQL en el clúster (`mysql:3306`, base `ventas_db`).

---

## 🧭 Estructura del proyecto

```
DevopsEV2-backend-ventas/
├── README.md
└── Springboot-API-REST/
    ├── src/main/java/com/citt/
    ├── src/test/java/             # VentaServiceTest, context tests
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
- Infra y secrets documentados en `DevopsEV2-infra/README.md`

---

## ⚙️ Flujo de uso

### Local (solo este servicio)

```bash
cd Springboot-API-REST
docker compose up -d --build
```

API: **http://localhost:8081**  
Swagger: **http://localhost:8081/swagger-ui.html**

### Despliegue AWS (EV3 — EKS)

1. Aplicar Terraform en `DevopsEV2-infra` (`etapa_1` + `etapa_3`).
2. Configurar secrets AWS en **DevopsEV2-infra**.
3. Push a **`deploy`** en **DevopsEV2-infra** → build imagen → push ECR → deployment `backend-ventas` en EKS.

Verificar:

```bash
kubectl get pods -l app=backend-ventas
kubectl get hpa backend-ventas-hpa
```

> El despliegue AWS se dispara únicamente desde **DevopsEV2-infra** (rama `deploy`).

---

## 📦 ¿Qué despliega este proyecto?

| Entorno | Contenedor / Pod | Puerto |
|---------|------------------|--------|
| Local | `backend-ventas` | 8081 → 8080 |
| Local | `db-ventas` (MySQL 8) | 3306 |
| AWS (EKS) | `backend-ventas` (3 réplicas, HPA 1–6) | Service ClusterIP **8080** |
| AWS (EKS) | `mysql` (pod compartido) | `mysql:3306`, BD `ventas_db` |

Variables en K8s: `DB_HOST`, `DB_ENDPOINT`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` (desde Secret `db-credentials`).

**ECR:** `innovatech-backend-ventas`

---

## 🧭 Diagrama de arquitectura

```
DevopsEV2-infra (cd.yml, rama deploy)
        ├── checkout este repo
        ├── docker build + push → ECR
        └── kubectl set image deployment/backend-ventas
                              │
                              ▼
              Pod backend-ventas :8080  ← HPA (CPU 50%)
                              │
                              ▼
              Pod MySQL :3306 / ventas_db
                              ↑
              Pod frontend (proxy /api/v1/ventas)
```

---

## 📌 Mejores prácticas incluidas

**Multi-stage Dockerfile:** `maven` compila el JAR; runtime `eclipse-temurin:21-jre`.

**Usuario no-root:** usuario/grupo `spring`, directiva `USER spring:spring`.

**Volúmenes**

| Tipo | Dónde | Motivo |
|------|--------|--------|
| **Named volume** | `docker-compose.yml` → `ventas-data-local:/var/lib/mysql` | En local, los datos de ventas sobreviven a `docker compose down` sin borrar volúmenes. |
| Sin PVC en EKS | `k8s/mysql.yml` (actual) | MySQL en pod; aceptable para lab; se puede añadir PVC en extensiones. |

**MySQL en EKS:** un solo pod `mysql` compartido con despachos (`despachos_db` creada por ConfigMap `mysql-init`).

**CI/CD (EV3):** build → push `innovatech-backend-ventas:${GITHUB_SHA}` → `kubectl set image` + `rollout status`.

**HPA:** `backend-ventas-hpa` escala entre 1 y 6 réplicas según CPU (requiere metrics-server).

---

## 🔧 Cómo extender este proyecto

- PersistentVolumeClaim para MySQL en el manifiesto K8s.
- Perfiles Spring (`application-prod.properties`) por ambiente.
- Tests en el pipeline (`mvn test`) antes del build Docker.
- Métricas con Actuator + health probes en el deployment.
- Flyway/Liquibase para migraciones de esquema.
