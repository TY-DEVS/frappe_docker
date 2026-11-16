# Implementation Plan: Frappe Helpdesk Multi-Tenant Integration

- **Date:** 2026-11-16
- **Target Domain:** `https://helpdesk.ty-dev.site`
- **Application UUID:** `znll1xddverpkikx0bziglmh`
- **Spec:** [2026-11-16-frappe-helpdesk-integration-design.md](file:///c:/Business/TYDev/infra/apps/frappe_docker/docs/superpowers/specs/2026-11-16-frappe-helpdesk-integration-design.md)

---

## Proposed Tasks

### Task 1: Update Dockerfile for Helpdesk
- **Files Modified:** `Dockerfile`
- **Steps:**
  1. Add `bench get-app --branch=version-16 --resolve-deps helpdesk https://github.com/frappe/helpdesk`.
  2. Add `(cd apps/helpdesk/desk && yarn install --network-concurrency 1 --network-timeout 300000 && yarn build)`.
  3. Add `bench build --app helpdesk`.
  4. Link `apps/helpdesk/helpdesk/public` to `assets/helpdesk`.
- **Verification:** Run `git diff Dockerfile` and ensure syntax is clean.

### Task 2: Update Compose File for Helpdesk
- **Files Modified:** `compose.coolify.yaml`
- **Steps:**
  1. Add Traefik labels for `frappe-helpdesk-http` and `frappe-helpdesk-https` targeting `helpdesk.ty-dev.site`.
  2. Add automated site check/creation in `create-site` service for `helpdesk.ty-dev.site`.
- **Verification:** Run `docker compose -f compose.coolify.yaml config` syntax validation.

### Task 3: Update Coolify Application Domains
- **Steps:**
  1. Call Coolify API via MCP or SSH to update `docker_compose_domains` to:
     `[{"name": "frontend", "domain": "https://erp.ty-dev.site,https://crm.ty-dev.site,https://helpdesk.ty-dev.site"}]`
- **Verification:** Query Coolify application and verify domains list.

### Task 4: Push to Git & Deploy Stack
- **Steps:**
  1. Commit and push changes to `origin/main`.
  2. Trigger deployment in Coolify or execute build.
  3. Wait for image build and container startup.
- **Verification:** Verify all containers in stack are running (`docker ps`).

### Task 5: Site Initialization & Verification
- **Steps:**
  1. Ensure `helpdesk.ty-dev.site` database is initialized and `helpdesk` app is installed.
  2. Verify Traefik routing and SSL: `curl.exe -Iv https://helpdesk.ty-dev.site`.
  3. Test Administrator login on `helpdesk.ty-dev.site`.
  4. Verify authenticated `/helpdesk` workspace returns HTTP 200 OK.
  5. Non-regression check on `erp.ty-dev.site`, `crm.ty-dev.site`, and `app.ty-dev.site`.
- **Verification:** All 4 domains respond with expected status codes and assets.
