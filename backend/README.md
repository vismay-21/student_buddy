# Student Buddy Backend

A production-ready, async FastAPI backend service for the Student Buddy student productivity platform.

---

## Technical Stack
- **Framework**: FastAPI (Asynchronous)
- **Database**: PostgreSQL
- **ORM / Driver**: SQLAlchemy 2.0 (Async) + asyncpg
- **Migrations**: Alembic
- **Validation**: Pydantic v2
- **Testing**: Pytest + pytest-asyncio

---

## Project Structure
```text
backend/
├── alembic/                  # Database schema migrations
├── app/                      # Application source code
│   ├── api/                  # API routers (v1 endpoints)
│   ├── core/                 # App config, database session, logging, constants
│   ├── dependencies/         # FastAPI dependency injection functions (database, auth stubs)
│   ├── exceptions/           # Custom exception models and global handlers
│   ├── models/               # SQLAlchemy ORM models
│   ├── repositories/         # Database CRUD operation wrappers
│   ├── schemas/              # Pydantic validation schemas
│   ├── services/             # Core business logic services
│   ├── utils/                # Standard utility helpers (e.g. attendance calculator)
│   └── main.py               # Uvicorn entry point
├── tests/                    # Automated integration & unit tests
├── requirements.txt          # Python dependencies list
└── alembic.ini               # Alembic configuration
```

---

## Getting Started

### 1. Prerequisites
- Python 3.12+
- PostgreSQL database instance

### 2. Environment Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Copy the environment variables template and modify:
   ```bash
   cp .env.example .env
   ```
   *Make sure `DATABASE_URL` matches your local database credentials.*

### 3. Database Migrations
Run Alembic migrations to apply schema updates:
```bash
alembic upgrade head
```

### 4. Running the Development Server
Start the local server with hot reloading enabled:
```bash
uvicorn app.main:app --reload
```
Once running, the interactive documentation is accessible at:
- Swagger UI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- ReDoc: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

---

## Running the Tests
Execute the backend test suite via `pytest`:
```bash
pytest
```
To run tests with stdout print enabled:
```bash
pytest -s
```
