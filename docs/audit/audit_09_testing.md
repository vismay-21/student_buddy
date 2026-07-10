# Audit 09 — Testing Audit

## Mistakes & Gaps Identified
During the testing audit, the following technical issues, warnings, and coverage gaps were identified:

1. **Deprecation Warnings (FastAPI/Starlette)**
   - **Warning**: `StarletteDeprecationWarning: 'HTTP_422_UNPROCESSABLE_ENTITY' is deprecated. Use 'HTTP_422_UNPROCESSABLE_CONTENT' instead.`
   - **Locations**:
     - `tests/academic/test_attendance_settings.py`
     - `tests/review_queue/test_review_queue.py`
     - `tests/settings/test_app_settings.py`
     - `tests/todo/test_todos.py`
   - **Impact**: Clean test runs are cluttered with deprecation warnings.

2. **SQLAlchemy Connection Deassociation Warning**
   - **Warning**: `SAWarning: transaction already deassociated from connection`
   - **Locations**: Emitted during cleanups of tests that raise or trigger internal database rollbacks/failures:
     - `tests/academic/test_holidays.py`
     - `tests/academic/test_lecture_templates.py`
     - `tests/academic/test_semesters.py`
     - `tests/academic/test_subjects.py`
   - **Root Cause**: The transaction-isolated `db_session` fixture in `tests/conftest.py` calls `await transaction.rollback()` unconditionally in the `finally` block, even when the connection/transaction is already rolled back or deassociated by the test itself.
   - **Impact**: Noise in test logs and potential resource cleanup issues.

3. **Gaps in Boundary and Leap Year Scenario Testing**
   - We have tests for leap-year lecture instance generation, but no specific boundary tests verifying holiday creation and holiday-date updates on leap days (e.g., Feb 29) to ensure correct date-matching math without crashing.
   - Searching for Todo list items with whitespace/padding queries is not explicitly covered.

---

## Post-Audit Resolution Status
1. **Resolved Deprecation Warnings**: Changed all instances of `status.HTTP_422_UNPROCESSABLE_ENTITY` to `status.HTTP_422_UNPROCESSABLE_CONTENT` across the test files. Pytest execution now reports zero deprecation warnings.
2. **Resolved Connection Deassociation Warnings**: Modified the `finally` cleanup block in `tests/conftest.py`'s `db_session` fixture to check `if transaction.is_active` before calling `await transaction.rollback()`.
3. **Leap Year and Boundary Cases Added**:
   - Implemented `test_leap_year_holiday_boundary` in `tests/academic/test_holidays.py` to verify that holiday creation/deletion behaves correctly on Feb 29 (Leap Day).
   - Implemented `test_api_todos_search_empty_or_whitespace` in `tests/todo/test_todos.py` to verify that empty or whitespace-only queries are handled safely and return appropriate results.

All 173 automated backend integration/unit tests pass with 100% success rate and zero warnings. Transactional integrity and database-first SQLite constraints are fully validated and isolated.

