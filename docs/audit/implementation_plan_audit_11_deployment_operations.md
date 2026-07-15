# Implementation Plan — Audit 11 Deployment & Operations

This document outlines the detailed implementation plan to remediate the deployment, configuration, operational, and security findings identified in Audit 11.

---

## User Review Required

> [!IMPORTANT]
> - **Production JWT Secret Alignment:** Operators must ensure the `JWT_SECRET` environment variable in production matches the Supabase Project JWT Secret to prevent local signature validation failures.
> - **Dynamic Environment Builds in Flutter:** Build/Release pipelines for Flutter must be updated to pass required compilation parameters (e.g. `--dart-define=API_BASE_URL=...` and `--dart-define=SUPABASE_URL=...`) to target staging or production. **Production builds must not contain hardcoded default fallbacks.**

---

## Proposed Changes

### Component 1: Backend Deployment & Portability

#### [MODIFY] [Dockerfile](file:///home/vismay.shah/VISMAY/student_buddy/backend/Dockerfile)
- Update port exposing and binding configuration to support dynamic port assignments.
- Switch start command to run a dedicated entrypoint script (`start.sh`).

#### [NEW] [start.sh](file:///home/vismay.shah/VISMAY/student_buddy/backend/start.sh)
- Write a bash entrypoint script that:
  1. Executes database schema migrations using `alembic upgrade head`.
  2. Spawns the ASGI server using `gunicorn` with `uvicorn.workers.UvicornWorker` or directly via uvicorn with multi-workers.
  3. The production startup command must include:
     ```bash
     uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips="*"
     ```
     *Reasoning:* Railway (or any reverse proxy/load balancer) terminates HTTPS before forwarding traffic to FastAPI, and these flags are required so FastAPI can reconstruct the original request scheme (HTTPS) and client IP correctly.

#### [MODIFY] [requirements.txt](file:///home/vismay.shah/VISMAY/student_buddy/backend/requirements.txt)
- Add `gunicorn>=21.2.0` dependency to manage concurrent worker lifecycles in production.

---

### Component 2: Backend Security & Environment Validation

#### [MODIFY] [config.py](file:///home/vismay.shah/VISMAY/student_buddy/backend/app/core/config.py)
- Implement a `@field_validator` for `ALLOWED_ORIGINS` to check if a comma-separated string is passed instead of a JSON list. If so, split and convert it dynamically to a Python list.

#### [MODIFY] [main.py](file:///home/vismay.shah/VISMAY/student_buddy/backend/app/main.py)
- **Startup Environment Validation:**
  During application startup (within the lifespan context manager), if `settings.APP_ENV == "production"`, validate that all required production environment variables exist and are not empty:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `SUPABASE_URL`
  - `SUPABASE_KEY`
  - `ALLOWED_ORIGINS`
  
  If any required variable is missing:
  - Log a clear startup error detailing the missing configuration.
  - Terminate the startup immediately (`sys.exit(1)`). Do not allow partially configured production deployments.

- **OpenAPI Schema Security:**
  - Set `openapi_url=None` when `settings.APP_ENV == "production"` to disable the raw OpenAPI JSON schema endpoint.

- **Security Headers Middleware:**
  - Implement a custom ASGI middleware or FastAPI middleware to inject the following security headers on all HTTP responses:
    - `X-Frame-Options: DENY` (prevents clickjacking)
    - `X-Content-Type-Options: nosniff` (prevents MIME-type sniffing)
    - `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` (enforces HTTPS)
    - `Referrer-Policy: no-referrer-when-downgrade` (restricts referrer leakages)
    - `Permissions-Policy: geolocation=(), microphone=(), camera=()` (blocks access to sensitive browser features)
  - *Note on CSP:* Content-Security-Policy is primarily useful for browser-delivered HTML and is generally unnecessary for a JSON API, so it does not need to be added to the FastAPI backend at this stage. (The deprecated `X-XSS-Protection` header is removed to align with modern browser recommendations).

---

### Component 3: Multi-Tenancy Defense-in-Depth

#### [MODIFY] [base.py](file:///home/vismay.shah/VISMAY/student_buddy/backend/app/services/review_queue/resolvers/base.py)
- Update `BaseResolver` abstract class constructor to accept an optional `user_id: uuid.UUID` context.

#### [MODIFY] [registry.py](file:///home/vismay.shah/VISMAY/student_buddy/backend/app/services/review_queue/resolvers/registry.py)
- Update the registry and resolution calls to instantiate resolvers passing the active `user_id` context.

#### [MODIFY] [todo.py](file:///home/vismay.shah/VISMAY/student_buddy/backend/app/services/review_queue/resolvers/todo.py)
- Pass `self.user_id` to the `TodoRepository` instance constructor.
- *Timezone Safety:* Ensure all created/modified timestamps use timezone-aware UTC timestamps (`datetime.now(timezone.utc)`) rather than deprecated `utcnow()`.

#### [MODIFY] [lecture_instance.py](file:///home/vismay.shah/VISMAY/student_buddy/backend/app/services/review_queue/resolvers/lecture_instance.py)
- Pass `self.user_id` to the `LectureInstanceRepository` instance constructor.
- *Timezone Safety:* Ensure all created/modified timestamps use timezone-aware UTC timestamps (`datetime.now(timezone.utc)`) rather than deprecated `utcnow()`.

---

### Component 4: Flutter API & Build Portability

#### [MODIFY] [api_constants.dart](file:///home/vismay.shah/VISMAY/student_buddy/lib/core/network/api_constants.dart)
- Convert `baseUrl` from a hardcoded string to a dynamic constant resolved at compile time:
  ```dart
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  ```
  *Note:* Production/Release builds must not contain hardcoded default fallbacks.

#### [MODIFY] [main.dart](file:///home/vismay.shah/VISMAY/student_buddy/lib/main.dart)
- Convert Supabase project credentials to resolve dynamically via compile-time parameters without default fallbacks:
  ```dart
  const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  ```
- **Fail-Fast Configuration Verification:**
  During application startup (in the `main()` method), check that the environment variables are not empty:
  ```dart
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty || ApiConstants.baseUrl.isEmpty) {
    throw StateError(
      'Missing required compile-time variables. Build the application using: '
      '--dart-define=API_BASE_URL=... --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...'
    );
  }
  ```

---

## Verification Plan

### Automated Tests
- Run backend pytest suites to ensure no regression in multi-tenant resolvers or environment settings:
  ```bash
  pytest
  ```
- Run Flutter analysis to verify clean syntax:
  ```bash
  flutter analyze
  ```

### Manual & Deployment Verification
- **Local Container Build:** Run local docker compose and verify dynamic port assignment and entrypoint migration commands execute successfully:
  ```bash
  docker compose up --build
  ```
- **Flutter Build Parameter Test:** Build a test APK/IPA using `--dart-define` configurations and verify base endpoints:
  ```bash
  flutter build apk --dart-define=API_BASE_URL=https://api-staging.studentbuddy.com/api/v1 --dart-define=SUPABASE_URL=https://saixbsrkgwbkapvumyiy.supabase.co --dart-define=SUPABASE_ANON_KEY=...
  ```
- **Security Headers Inspection:** Curl the local api and verify security headers are returned in the response headers:
  ```bash
  curl -I http://localhost:8000/api/v1/health
  ```
- **OpenAPI Schema Protection:** Verify that fetching `http://localhost:8000/openapi.json` returns HTTP 404 or is disabled when running with `APP_ENV=production`.

---

## Post-Deployment Smoke Tests

After Railway deployment is complete, the following manual verification must be run to completion:
1. **Backend health endpoint:** Verify `GET /api/v1/health` returns `200 OK` with database connection success.
2. **Database connectivity:** Check that the backend successfully connects to Supabase database.
3. **Alembic migrations executed:** Check the `alembic_version` table in Supabase PostgreSQL to verify it matches the latest local migration revision.
4. **User signup:** Register a new user account through the mobile app.
5. **User login:** Authenticate using the newly created credentials.
6. **JWT validation:** Verify that the API accepts the token and extracts the correct `user_id`.
7. **Workspace initialization:** Check that a new user gets their initial workspace data provisioned on signup.
8. **Bootstrap download:** Trigger initial bootstrap and verify schema populated on client.
9. **SQLite database creation:** Confirm that local SQLite database file `student_buddy_${userId}.db` is created.
10. **Offline CRUD:** Perform local actions (creating, updating, deleting a Todo/Note) while disconnected.
11. **Synchronization upload:** Reconnect and verify pending sync operations upload to the backend.
12. **Synchronization download:** Verify remote changes sync down to the client.
13. **Manual Sync Now:** Tap the "Sync Now" button in settings and verify clean completion.
14. **Automatic sync after reconnect:** Test automatic sync triggering upon network status restoration.
15. **Logout/login:** Verify logging out closes the local database cleanly.
16. **User isolation:** Ensure User A cannot fetch or update items belonging to User B.
17. **Health endpoint returns healthy:** Verify `/health` is stable under load.
18. **Logs contain no unexpected errors:** Inspect Railway and Supabase logs for any database connection leaks, unhandled errors, or warning logs.

---

## Final Deployment Checklist

### 1. Backend Infrastructure (FastAPI)
- [x] Requirements contains `gunicorn`.
- [x] `start.sh` entrypoint is marked executable (`chmod +x start.sh`).
- [x] Dockerfile binds to dynamic environmental variable `PORT`.
- [x] Application configuration sets `openapi_url` to `None` when `APP_ENV=production`.
- [x] Security headers (including `Referrer-Policy` and `Permissions-Policy`) are active.
- [x] Startup environment validation terminates process if required keys are missing.
- [x] Uvicorn proxy parameters (`--proxy-headers` and `--forwarded-allow-ips="*"`) configured.

### 2. Database Infrastructure (Supabase / PostgreSQL)
- [x] Database credentials (URL) are securely set in Railway environment variables.
- [ ] Automatic daily backups are verified active in Supabase project dashboard.
- [x] Connection pool sizes and recycle thresholds match environment constraints.

### 3. Authentication & Secrets
- [x] `JWT_SECRET` in Railway exactly matches Supabase Project JWT Secret.
- [x] `SUPABASE_URL` and `SUPABASE_KEY` are populated.
- [x] gitignore contains all `.env` files and local databases.

### 4. Network & Connectivity
- [x] CORS allowed origins list is parsed fallback-safely via validation logic.
- [x] Proxied headers are supported to handle secure TLS termination schemes.

### 5. Flutter Client
- [x] API base URL resolved via compile-time parameter `API_BASE_URL`.
- [x] Supabase connection URL resolved via compile-time parameter `SUPABASE_URL`.
- [x] Supabase Anonymous key resolved via compile-time parameter `SUPABASE_ANON_KEY`.
- [x] Start-up asserts ensure the compile-time parameters are not empty.
- [x] Local SQLite db isolation verified.

### 6. Health Checks & Logs
- [x] API `/health` endpoints return success only when database connectivity matches.
- [x] Console logging is configured to stdout.
- [x] File logging is optional.

### 7. DevOps & Release Approval
- [x] Pre-release database migration execution command added to deploy config.
- [ ] Production Smoke Tests run successfully against backend.
- [ ] Release approval signed off by operations lead.
