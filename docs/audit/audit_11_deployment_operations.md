# Student Buddy Backend Audit — Deployment & Operations Audit (Audit 11)

This report evaluates the deployment infrastructure, environment configuration, database operations, security configurations, and production readiness of the Student Buddy backend and mobile client before release to Railway (FastAPI) and Supabase (PostgreSQL).

---

## 1. Scorecard

*   **Initial Health Score:** 85/100
*   **Projected Health Score:** 100/100
*   **Findings Count:** 9
    *   **Critical:** 0
    *   **High:** 2 (Finding 11.1, Finding 11.2)
    *   **Medium:** 4 (Finding 11.3, Finding 11.4, Finding 11.5, Finding 11.6)
    *   **Low:** 3 (Finding 11.7, Finding 11.8, Finding 11.9)
    *   **Suggestions:** 0
*   **Go / No-Go Recommendation:** **No-Go** (until high and medium findings are resolved via the implementation plan).

---

## 2. Scope & Methodology

This audit conducted a full code and configuration review of both the FastAPI backend and Flutter client modules. The evaluation focused on the following 19 critical readiness areas:
1.  **Deployment Readiness** (ASGI, Docker, lifecycles, and cloud hosting compatibility).
2.  **Environment Variables** (settings models, validation, and defaults).
3.  **Secrets Management** (credential isolation and protection).
4.  **Database Operations** (Alembic migration safety and execution).
5.  **PostgreSQL Production Readiness** (connection pooling and constraints).
6.  **Authentication Production Readiness** (JWT validation and JWKS).
7.  **Synchronization Engine Readiness** (idempotency, coalescing, and protocol safety).
8.  **SQLite Production Readiness** (local schemas, multi-tenancy, and lifecycle).
9.  **API Production Readiness** (status codes, response schemas, and error boundaries).
10. **Logging** (process levels and output structure).
11. **Monitoring & Diagnostics** (database-connected health checks).
12. **CORS / HTTPS** (origin control and TLS termination).
13. **Flutter Production Readiness** (compile-time variable configurations and exception paths).
14. **Repository Documentation** (developer onboarding and deployment runbooks).
15. **Security Review** (headers and resource authorization).
16. **Performance Review** (latency, connections, and database indexing).
17. **Disaster Recovery** (backups, rollback steps, and offline database rebuilds).
18. **DevOps Readiness** (release sequences and deployment patterns).
19. **Remaining Technical Debt** (code debt and maintenance backlogs).

---

## 3. Detailed Findings

### Finding 11.1: Missing Automated Migration Execution in Production (High)
*   **Problem:** There is no automated mechanism in the `Dockerfile` or `docker-compose.yaml` to run database migrations (`alembic upgrade head`) upon container deployment.
*   **Why it is a problem:** If container deployments scale out or update without executing schema migrations, the database schema will fall out of sync with backend models, leading to database errors at runtime.
*   **Impact:** Deployment failures and schema mismatch crashes.
*   **Recommended Solution:** Introduce an entrypoint execution script (`start.sh`) that automatically runs migrations before spawning the FastAPI web service, and configure Railway's custom release phases or start commands to execute this script.
*   **Action Plan:** Fix prior to production release.

---

### Finding 11.2: Hardcoded Localhost API Base URL in Flutter Client (High)
*   **Problem:** The base URL of the backend API is hardcoded as `http://127.0.0.1:8000/api/v1` inside `lib/core/network/api_constants.dart`.
*   **Why it is a problem:** Release builds of the Flutter client will attempt to reach the backend locally on the physical mobile device rather than connecting to the public production endpoint over HTTPS, breaking all network-dependent capabilities.
*   **Impact:** Broken mobile application sync, login, and signup in staging and production.
*   **Recommended Solution:** Replace the hardcoded constant with a dynamic environment resolver that utilizes Flutter's `--dart-define` compilation parameters, allowing base URLs to be injected at build time (e.g. `--dart-define=API_BASE_URL=https://api.studentbuddy.com/api/v1`).
*   **Action Plan:** Fix prior to production release.

---

### Finding 11.3: Exposed OpenAPI Schema URL `/openapi.json` in Production (Medium)
*   **Problem:** While Swagger (`/docs`) and ReDoc (`/redoc`) routes are conditionally disabled when `APP_ENV == "production"`, the raw OpenAPI JSON endpoint (`/openapi.json`) remains enabled.
*   **Why it is a problem:** Attackers can fetch the schema directly via `/openapi.json` and reconstruct the entire structure, routes, schemas, and parameter constraints of the API.
*   **Impact:** API structural leakage and reconnaissance vulnerability.
*   **Recommended Solution:** Configure the `openapi_url` parameter in the `FastAPI` application constructor to evaluate to `None` if `APP_ENV == "production"`.
*   **Action Plan:** Fix prior to production release.

---

### Finding 11.4: Lack of HTTP Security Headers Middleware (Medium)
*   **Problem:** The FastAPI application does not configure standard security headers (e.g., `X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security`, or `Content-Security-Policy`).
*   **Why it is a problem:** Deployed APIs are vulnerable to cross-site scripting (XSS), clickjacking, MIME-sniffing, and protocol downgrade attacks.
*   **Impact:** Reduced defense-in-depth security rating.
*   **Recommended Solution:** Add a middleware block in `app/main.py` that injects default security headers on all responses.
*   **Action Plan:** Fix prior to production release.

---

### Finding 11.5: Missing Proxy Headers Configuration for ASGI/Uvicorn (Medium)
*   **Problem:** Uvicorn is spawned without proxy forwarding configurations (e.g. `--proxy-headers` and `--forwarded-allow-ips`), and the application lacks middleware to reconstruct secure headers behind load balancers.
*   **Why it is a problem:** Railway and other cloud platforms terminate TLS at their gateway proxy. Without header forwarding, FastAPI will interpret incoming traffic as HTTP (not HTTPS), breaking redirect generation and scheme validation.
*   **Impact:** Redirection loops, mixed-content errors, and insecure cookie handling.
*   **Recommended Solution:** Configure uvicorn startup flags in the deployment process to include `--proxy-headers` and `--forwarded-allow-ips="*"`.
*   **Action Plan:** Fix prior to production release.

---

### Finding 11.6: Insecure Pydantic Settings ALLOWED_ORIGINS Environment Parsing (Medium)
*   **Problem:** The `ALLOWED_ORIGINS` field in `Settings` is typed as a `list[str]`.
*   **Why it is a problem:** If `ALLOWED_ORIGINS` is configured in production environment variables as a standard comma-separated string (e.g., `https://app.studentbuddy.com,https://api.studentbuddy.com`), Pydantic Settings v2 will fail to parse it and crash the application on startup, as it expects JSON-formatted arrays by default.
*   **Impact:** Deployment crashes due to parsing errors.
*   **Recommended Solution:** Implement a Pydantic `@field_validator` on `ALLOWED_ORIGINS` that parses comma-separated lists fallback-safely if the value is provided as a plain string.
*   **Action Plan:** Fix prior to production release.

---

### Finding 11.7: Unscoped Repositories in Review Queue Resolvers (Low)
*   **Problem:** The `TodoResolver` and `LectureInstanceResolver` instantiate their database repositories (`TodoRepository`, `LectureInstanceRepository`) without passing a `user_id` context.
*   **Why it is a problem:** While the outer `ReviewQueue` API endpoint verifies ownership, the sub-resolvers operate on the database unscoped. If a security issue or logical gap allows an attacker to resolve an item they own with a target ID belonging to another user, the unscoped repository will modify the foreign record.
*   **Impact:** Potential cross-tenant data modification vulnerabilities.
*   **Recommended Solution:** Update the `BaseResolver` interface and resolver registry to accept the active `user_id` and initialize database repositories scoped to that tenant.
*   **Action Plan:** Resolve during maintenance window.

---

### Finding 11.8: Absence of gunicorn/process manager in requirements.txt (Low)
*   **Problem:** The dependencies only list `uvicorn`. There is no process manager (like `gunicorn`) configured to manage worker process lifecycles.
*   **Why it is a problem:** In production environments, running raw uvicorn without a process controller limits concurrency management and increases vulnerability to process crashes and resource leaks.
*   **Impact:** Performance degradation under concurrent loads and lack of process auto-recovery.
*   **Recommended Solution:** Add `gunicorn` to `requirements.txt` and configure a production-ready start script that launches uvicorn workers via gunicorn.
*   **Action Plan:** Resolve during maintenance window.

---

### Finding 11.9: Hardcoded Dynamic Port in Dockerfile (Low)
*   **Problem:** The `Dockerfile` has a hardcoded port mapping (`EXPOSE 8000` and `--port 8000` in the CMD).
*   **Why it is a problem:** Railway and other container-hosting environments assign a dynamic port environment variable (`PORT`) to the container. If uvicorn ignores this port and binds strictly to `8000`, the health checks from the gateway proxy will fail, and the service will be killed.
*   **Impact:** Cloud deployment failures and port mapping mismatches.
*   **Recommended Solution:** Update the container start command to bind dynamically to the `PORT` environment variable, defaulting to `8000` if it is not set.
*   **Action Plan:** Resolve during maintenance window.

---

## 4. Production Readiness Analysis & Verification

### Passed Audits
*   **Database Constraints & Indexes:** Passed. Database schemas are highly optimized, contain necessary indexes (including `lecture_date` and `uq_lecture_instance_template_date`), and enforce check constraints.
*   **Connection Pooling:** Passed. Engine configurations utilize customized connection pools, overflow parameters, and recycled durations.
*   **Database Health Check:** Passed. `/api/v1/health` executes a live `SELECT 1` database query and properly returns HTTP 503 if the database is unreachable.
*   **SQLite Tenant Isolation:** Passed. The mobile client implements user-scoped databases named `student_buddy_${userId}.db`, which isolates local data files per authenticated session.
*   **Synchronization Version Safety:** Passed. The client and server validate the synchronization protocol version range (`1`) during bootstrap and delta snapshots, safely aborting without SQLite transactions on mismatches.
*   **Logging Observability:** Passed. Startup events log the active protocol version, and files can be optionally logged rotating-safely via configurable settings.

---

## 5. Disaster Recovery Assumptions

*   **Database Backups:** Supabase automatically manages daily physical backups. Manual backups can be triggered via the CLI.
*   **Migration Recovery:** Database schema upgrades are executed transactionally. If an Alembic migration fails, the changes are rolled back.
*   **Mobile DB Corruption:** If the client-side SQLite file becomes corrupted, the app detects the failure, isolates or removes the corrupted database file, and prompts the user to re-authenticate. Upon logging back in, the initialization flow calls `/me/bootstrap` to rebuild the SQLite database from the cloud authoritative source.

---

## 6. Go / No-Go Decision

*   **Current Status:** **NO-GO**
*   **Justification:** The hardcoded API URL in Flutter and the missing automated migration commands/port-binding configs in Docker make deploying the system to production on Railway immediately fail.
*   **Target Status:** **GO** (following completion of the steps documented in the accompanying implementation plan).
