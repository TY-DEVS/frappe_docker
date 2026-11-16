# Multi-Tenant ERPNext & Frappe CRM Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Isolate ERPNext and Frappe CRM onto two dedicated virtual sites (`https://erp.ty-dev.site` and `https://crm.ty-dev.site`) on a single multi-tenant Frappe Docker Compose stack with separate databases on a shared MariaDB and Redis instance.

**Architecture:** Use Frappe's native DNS-based multitenancy. Nginx receives requests for both domains via Traefik and dynamically passes `$http_host` to Gunicorn. The `create-site` service automates the provisioning of both sites with their respective applications (`erpnext` on `erp.ty-dev.site` and `crm` on `crm.ty-dev.site`).

**Tech Stack:** Docker Compose, Coolify, Traefik, Frappe Framework v16, ERPNext v16, Frappe CRM v16, MariaDB 11.8, Redis 7.

## Global Constraints
- Target domains: `https://erp.ty-dev.site` (ERPNext) and `https://crm.ty-dev.site` (Frappe CRM).
- Shared resources: MariaDB 11.8 container (`db`) and Redis 7 containers (`redis-cache`, `redis-queue`).
- Persistent storage: `sites`, `logs`, `db-data`, `redis-queue-data`.
- Keep existing `erp.ty-dev.site` site and data intact.

---

### Task 1: Update Docker Compose Configuration

**Files:**
- Modify: `compose.coolify.yaml`

- [ ] **Step 1: Update Traefik Router Labels on `frontend`**
Update `compose.coolify.yaml` under `frontend.labels` so Traefik listens for both domains:
```yaml
      - traefik.http.routers.frappe-erp-http.rule=Host(`erp.ty-dev.site`) || Host(`crm.ty-dev.site`)
      - traefik.http.routers.frappe-erp-http.entrypoints=http
      - traefik.http.routers.frappe-erp-https.rule=Host(`erp.ty-dev.site`) || Host(`crm.ty-dev.site`)
      - traefik.http.routers.frappe-erp-https.entrypoints=https
      - traefik.http.routers.frappe-erp-https.tls=true
      - traefik.http.routers.frappe-erp-https.tls.certresolver=letsencrypt
```

- [ ] **Step 2: Remove Hardcoded Site Header in `frontend`**
Remove `FRAPPE_SITE_NAME_HEADER: ${FRAPPE_SITE_NAME_HEADER:-erp.ty-dev.site}` so Nginx passes through the dynamic incoming `$host` header for multitenant routing.

- [ ] **Step 3: Update `create-site` Service Script**
Update `create-site` in `compose.coolify.yaml` to provision both `erp.ty-dev.site` and `crm.ty-dev.site`:
```bash
        # 1. Manage ERPNext site
        if [ -d "sites/erp.ty-dev.site" ]; then
          echo "Site erp.ty-dev.site exists, running migrations...";
          bench --site erp.ty-dev.site migrate;
        else
          echo "Creating site erp.ty-dev.site with ERPNext...";
          bench new-site erp.ty-dev.site \
            --mariadb-user-host-login-scope='%' \
            --admin-password=$${ADMIN_PASSWORD:-admin} \
            --db-root-username=root \
            --db-root-password=$${DB_PASSWORD:-admin} \
            --install-app erpnext;
        fi;

        # 2. Manage Frappe CRM site
        if [ -d "sites/crm.ty-dev.site" ]; then
          echo "Site crm.ty-dev.site exists, running migrations...";
          bench --site crm.ty-dev.site migrate;
        else
          echo "Creating site crm.ty-dev.site with Frappe CRM...";
          bench new-site crm.ty-dev.site \
            --mariadb-user-host-login-scope='%' \
            --admin-password=$${ADMIN_PASSWORD:-admin} \
            --db-root-username=root \
            --db-root-password=$${DB_PASSWORD:-admin} \
            --install-app crm;
          bench --site crm.ty-dev.site set-config home_page crm;
        fi;
```

- [ ] **Step 4: Commit and Push**
Commit the changes to git:
`git commit -am "feat(compose): add multi-tenant routing and provisioning for crm.ty-dev.site"`
`git push origin main`

---

### Task 2: Update Coolify Application Configuration

- [ ] **Step 1: Update Application Domains in Coolify**
Call `manage_application` tool with `uuid: "znll1xddverpkikx0bziglmh"` and update `docker_compose_domains`:
```json
[
  {"name": "frontend", "domain": "https://erp.ty-dev.site,https://crm.ty-dev.site"}
]
```

- [ ] **Step 2: Verify Application Settings**
Call `get_application` to confirm that `docker_compose_domains` reflects both domains.

---

### Task 3: Deploy & Provision Stack

- [ ] **Step 1: Trigger Coolify Deployment**
Call `deploy` tool with `uuid: "znll1xddverpkikx0bziglmh"`.

- [ ] **Step 2: Monitor Deployment**
Poll `get_deployment` until deployment status is `finished`.

---

### Task 4: Verify Both Isolated Sites

- [ ] **Step 1: Verify `erp.ty-dev.site`**
Run `curl.exe -Iv https://erp.ty-dev.site` and confirm:
- HTTP 200 OK
- ERPNext headers and assets (`erpnext-web.bundle.*.css`).

- [ ] **Step 2: Verify `crm.ty-dev.site`**
Run `curl.exe -Iv https://crm.ty-dev.site` and confirm:
- HTTP 200 OK / SSL valid.
- Frappe CRM assets or login page.

- [ ] **Step 3: Verify Database Isolation**
Verify that `sites/erp.ty-dev.site` and `sites/crm.ty-dev.site` point to separate database names in MariaDB.
