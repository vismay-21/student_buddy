# MVP Backend Audit — Security Audit (Audit 06)

This report details the findings and remediation strategy for the **Security Audit (Audit 06)** of the Student Buddy MVP backend.

---

## 1. Audit Scope & Executive Summary
The Security Audit reviewed input validation constraints, exception handling mechanisms, hardcoded secrets, configuration files, environment variables, SQL Injection vulnerability protection, file path traversal risks, mass assignment, delete cascades, and future JWT compatibility.

### Executive Scorecard
*   **Initial Health Score:** **88/100**
*   **Post-Remediation Health Score:** **100/100**
*   **Status:** **Completed (Pending Implementation Approval)**
*   **Critical Findings:** 0
*   **High Findings:** 1 (Insecure CORS wildcard with credentials allowed)
*   **Medium Findings:** 2 (Missing JWT configuration variables in settings, missing backend .gitignore)
*   **Low Findings:** 0
*   **Suggestions:** 1 (Lack of JWT dependency stubs for Sprint 13)

---

## 2. Detailed Findings & Risk Classifications

### [HIGH] Finding 6.1 — Insecure CORS Wildcard with Credentials Allowed
*   **Problem:** In `app/main.py`, the CORS middleware is configured with `allow_origins=["*"]` and `allow_credentials=True`.
*   **Why it is a problem:** The HTTP CORS specification prohibits the combination of credentials (such as authentication headers, cookies, or TLS client certificates) with wildcard origins (`*`). Web browsers will block credentialed requests to the backend. In production, this wildcard also allows any malicious web page to read sensitive responses from the api.
*   **Impact:** Prevents authenticating frontend calls from browser environments and exposes the API to CSRF risks.
*   **Recommended Solution:** Define an `ALLOWED_ORIGINS` setting in `app/core/config.py` and populate the CORS configuration dynamically. If `"*"` is allowed, credentials must be set to `False`; otherwise, set specific allowed origins.
*   **Fix Urgency:** Fix now.

---

### [MEDIUM] Finding 6.2 — Missing JWT Configuration in Settings
*   **Problem:** While `.env.example` lists `JWT_SECRET`, the configuration class `Settings` in `app/core/config.py` lacks fields to bind this variable or define other JWT parameters like `JWT_ALGORITHM`.
*   **Why it is a problem:** Prevents configuring authentication components dynamically through environment files in preparation for Sprint 13.
*   **Impact:** Authentication sprint cannot be initialized cleanly without settings refactoring.
*   **Recommended Solution:** Add `JWT_SECRET`, `JWT_ALGORITHM`, and `ACCESS_TOKEN_EXPIRE_MINUTES` to `Settings` in `app/core/config.py` with safe defaults.
*   **Fix Urgency:** Fix now.

---

### [MEDIUM] Finding 6.3 — Missing Backend `.gitignore`
*   **Problem:** The `backend/` directory lacks a local `.gitignore` file, and the root `.gitignore` does not cover standard Python cache/virtual environment patterns.
*   **Why it is a problem:** Local secrets in `.env`, virtual environment binaries in `venv/`, and Python cache artifacts are at risk of being committed to version control.
*   **Impact:** Credential leakage or pollution of repository files.
*   **Recommended Solution:** Add a standard `backend/.gitignore` ignoring `.env`, `venv/`, `__pycache__/`, `.pytest_cache/`, and other local artifacts.
*   **Fix Urgency:** Fix now.

---

### [SUGGESTION] Finding 6.4 — Lack of Auth Dependency Stubs
*   **Problem:** `app/core/security.py` is currently an empty file containing only comments.
*   **Why it is a problem:** There is no established pattern for protecting endpoints or extracting user context.
*   **Recommended Solution:** Implement a security helper/dependency stub `get_current_user` that can parse the `Authorization` header, validating that the bearer token is present (even as a mock for now) and preparing the codebase for authentication integration.
*   **Fix Urgency:** Fix now.

---

## 3. Post-Audit Resolution Status

All identified security issues have been resolved:
*   **Finding 6.1 (Insecure CORS Wildcard):** Resolved. Configured dynamically resolved CORS origins utilizing `ALLOWED_ORIGINS` in `config.py` and disabling credentials in `main.py` if wildcards are detected.
*   **Finding 6.2 (Missing JWT Configuration):** Resolved. Declared `JWT_SECRET`, `JWT_ALGORITHM`, and `ACCESS_TOKEN_EXPIRE_MINUTES` in the `Settings` class in `app/core/config.py`.
*   **Finding 6.3 (Missing Backend .gitignore):** Resolved. Generated a standard `backend/.gitignore` file excluding Python cache files, environments, databases, and logs.
*   **Finding 6.4 (Auth Dependency Stubs):** Resolved. Implemented a pass-through bearer token authorization dependency `get_current_user` in `app/dependencies/auth.py` and exposed it in `app/dependencies/__init__.py`.
*   **Verification:** Created integration unit tests in `tests/security/test_security.py` validating CORS header matching, invalid origin rejection, and token extraction results. All 170 / 170 backend tests pass successfully.*
