# Design Specification: Deploying Frappe CRM + ERPNext on Coolify

**Date**: 2026-11-15  
**Topic**: Frappe CRM & ERPNext v16 Deployment on Coolify via Docker Compose  
**Repository**: `TY-DEVS/frappe_docker`  
**Target Environment**: Coolify Project `Infrastructure` (`plcmnur9rpv2l58kdsagb8bx`) / Environment `management` (`yyu9v1i79dqh0po4zm3m2twf`)  
**Domain**: `https://erp.ty-dev.site`

---

## 1. Objective

Deploy a unified, production-ready Frappe v16 stack running both **ERPNext v16** and **Frappe CRM** on Coolify using Docker Compose. The deployment must be managed via Coolify MCP, built automatically from this repository, and include automated site provisioning, MariaDB storage, Redis caching/queues, background job workers, scheduler, websocket support, and Coolify Traefik reverse proxy integration.

---

## 2. Architecture & Components

### 2.1 Services Overview

The deployment consists of 10 cooperating containers managed by Docker Compose:

1. **`app-builder` / Image**:
   - Multi-stage Dockerfile (`images/custom/Dockerfile.coolify`) using:
     - Base builder: `frappe/build:version-16`
     - Runtime base: `frappe/base:version-16`
     - Bundled apps (`apps.json`): `erpnext` (branch `version-16`) and `crm` (branch `main`).
2. **`frontend`**:
   - Frappe Nginx image (derived from the built image) serving static assets and proxying requests.
   - Connected to both `frappe_network` (internal) and `coolify` (external Traefik proxy).
   - Port 8080 exposed internally to Traefik.
3. **`backend`**:
   - Frappe Gunicorn WSGI server handling application requests.
4. **`websocket`**:
   - Frappe Socket.IO server handling real-time events on port 9000.
5. **`queue-short` & `queue-long`**:
   - Celery/RQ Python background workers processing default, short, and long-running jobs.
6. **`scheduler`**:
   - Frappe schedule worker triggering periodic and scheduled tasks.
7. **`configurator`**:
   - One-shot initialization container setting global DB, Redis, and SocketIO configurations in `common_site_config.json`.
8. **`create-site`**:
   - One-shot initialization container that runs `bench new-site erp.ty-dev.site --install-app erpnext --install-app crm` if the site does not exist yet.
9. **`db` (MariaDB 11.8)**:
   - Dedicated database container configured with utf8mb4 collation and `innodb-snapshot-isolation=OFF`.
10. **`redis-cache` & `redis-queue`**:
    - Redis 6.2/7 Alpine instances for caching and message queuing.

---

## 3. Data Flow & Networking

```
                     Internet
                        │ (HTTPS: erp.ty-dev.site)
                        ▼
            Coolify Traefik Reverse Proxy
                        │ (Docker Network: coolify)
                        ▼
                frontend (Nginx :8080)
               ┌────────┴────────┐
               │                 │
               ▼                 ▼
        backend (:8000)   websocket (:9000)
               │                 │
         ┌─────┴─────────────────┴─────┐
         ▼                             ▼
    db (MariaDB :3306)      redis-cache & queue (:6379)
```

---

## 4. Storage & Persistence

Named volumes retain all persistent state across container restarts and redeployments:
- `db-data`: MariaDB `/var/lib/mysql`
- `redis-queue-data`: Redis `/data`
- `sites`: Frappe sites directory `/home/frappe/frappe-bench/sites` (stores site configs, uploaded private & public files)
- `logs`: Frappe bench logs `/home/frappe/frappe-bench/logs`

---

## 5. Deployment & Automation Steps via Coolify MCP

1. Push `apps.json`, `images/custom/Dockerfile.coolify`, and `compose.coolify.yaml` to GitHub `TY-DEVS/frappe_docker` (`main`).
2. Invoke `coolify.create_application`:
   - `build_pack`: `dockercompose`
   - `docker_compose_location`: `/compose.coolify.yaml`
   - `git_repository`: `TY-DEVS/frappe_docker`
   - `git_branch`: `main`
   - `domains`: `https://erp.ty-dev.site`
3. Configure environment variables in Coolify (`manage_env`):
   - `DB_PASSWORD`: Strong generated MariaDB root password.
   - `ADMIN_PASSWORD`: Frappe Administrator account password.
   - `FRAPPE_SITE_NAME_HEADER`: `erp.ty-dev.site`
4. Trigger deployment via `coolify.deploy`.
5. Monitor logs and verify healthy container status and web reachability.
