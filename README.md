# Student Buddy

Student Buddy is an integrated, personal productivity operating system designed to streamline academic, task, and expense management for students.

It consists of a mobile application built in Flutter and a high-performance backend built with FastAPI and PostgreSQL, unified under a clean architectural design.

---

## Repository Layout
```text
student_buddy/
├── backend/                  # FastAPI backend service
│   ├── app/                  # Main backend codebase
│   ├── alembic/              # Alembic database migrations
│   └── tests/                # Pytest automation suite
├── lib/                      # Flutter mobile application codebase
│   ├── core/                 # Shared widgets, themes, and states
│   └── screens/              # Screens for Academic, Notes, Finance, and settings
├── docs/                     # Project documentation, designs, and audits
└── pubspec.yaml              # Flutter dependencies and project metadata
```

---

## Tech Stack Overview

### Frontend
- **Framework**: Flutter (SDK 3.x) & Dart
- **State Management**: Riverpod (planned/in-progress) / Local State
- **Networking**: Dio

### Backend
- **Framework**: FastAPI (Asynchronous Python)
- **Database**: PostgreSQL (Supabase / Local)
- **ORM**: SQLAlchemy 2.0 (Async) + asyncpg
- **Migrations**: Alembic

---

## Getting Started

### Backend Setup
For detailed setup instructions, please refer to the [Backend Developer Guide](file:///home/vismay.shah/VISMAY/student_buddy/backend/README.md).
Quickstart:
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

### Frontend Setup
Ensure you have the Flutter SDK installed on your system.
1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
2. Run static analysis:
   ```bash
   flutter analyze
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## Quality Audits
Before proceeding to active Sprints, the Student Buddy MVP underwent a series of technical and architectural quality audits:
- **Audit 1 (Architecture)**: Passed (94/100) — Standardized timezone-aware datetime.
- **Audit 2 (Database)**: Passed (98/100) — Added schema unique constraints, date order verification, and indexes.
- **Audit 3 (Business Logic)**: Passed (98/100) — Resolved template rescheduling duplicate generation conflicts and time inversions.
- **Audit 4 (API)**: Passed (100/100) — Standardized API wrappers and added pagination.
- **Audit 5 (Performance)**: Passed (100/100) — Resolved N+1 queries in dynamic listings and added indexes.
- **Audit 6 (Security)**: Passed (100/100) — Secured CORS config, added JWT configurations, and added bearer auth stubs.
- **Audit 7 (Flutter Integration)**: Passed (100/100) — Decoupled mock states from AppState.
- **Audit 8 (Code Quality)**: Passed (100/100) — Resolved stale TODOs and added Flutter context safeguards.
- **Audit 9 (Testing)**: Passed (100/100) — Eliminated deprecation and transactional SAWarnings.
- **Audit 10 (Production Readiness)**: Passed (100/100) — Integrated connection pooling, Docker containers, and database health checks.
