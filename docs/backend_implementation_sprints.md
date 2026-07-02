# Student Buddy Backend Implementation Sprints
Version: 1.0 (Pre-Finance Module)

---

# Purpose

This document defines the official implementation order of the Student Buddy backend.

The purpose of this document is to ensure that every backend module is developed independently while following the architecture defined in the project documentation.

Each sprint is considered complete only after all required components have been implemented, tested and verified.

---

# Sprint 0 — Backend Foundation

## Objective

Create the backend project foundation.

## Deliverables

- FastAPI Project
- Folder Structure
- Configuration
- Environment Variables
- Logging
- Exception Handling
- Dependency Injection
- SQLAlchemy Configuration
- Alembic Configuration
- PostgreSQL Connection
- Health Endpoint
- README
- requirements.txt

No business logic.

No models.

No APIs.

---

# Sprint 1 — Semester Module

## Tables

- semesters

## Deliverables

- SQLAlchemy Model
- Pydantic Schemas
- Repository
- Service
- API Router
- Tests
- Activity Log Integration

---

# Sprint 2 — Subject Module

## Tables

- subjects
- notes_subjects (automatic creation)

## Deliverables

- CRUD
- Validation
- Automatic Notes Subject Creation
- Repository
- Service
- API
- Tests

---

# Sprint 3 — Lecture Template Module

## Tables

- lecture_templates

## Deliverables

- CRUD
- Validation
- Semester Lecture Generation
- Repository
- Service
- API
- Tests

---

# Sprint 4 — Lecture Instance Module

## Tables

- lecture_instances

## Deliverables

- Attendance Updates
- Whole Day Marking
- Today's Lectures
- History APIs
- Repository
- Service
- API
- Tests

---

# Sprint 5 — Attendance Settings Module

## Tables

- attendance_settings

## Deliverables

- Overall Mode
- Subject Mode
- Custom Mode
- Repository
- Service
- API
- Tests

---

# Sprint 6 — Holiday Module

## Tables

- holidays

## Deliverables

- CRUD
- Holiday Validation
- Automatic Lecture Status Updates
- Repository
- Service
- API
- Tests

---

# Sprint 7 — App Settings Module

## Tables

- app_settings

## Deliverables

- Active Semester
- Theme
- Module Toggles
- Repository
- Service
- API
- Tests

---

# Sprint 8 — Todo Module

## Tables

- todos

## Deliverables

- CRUD
- Categories
- Priorities
- Due Dates
- Repository
- Service
- API
- Tests

---

# Sprint 9 — Notes Repository Module

## Tables

- notes_subjects
- notes_sections
- notes_resources

## Deliverables

- Complete Notes Hierarchy
- Resource Upload Metadata
- Resource Retrieval
- Repository
- Service
- API
- Tests

---

# Sprint 10 — Review Queue Module

## Tables

- review_queue

## Deliverables

- Pending Items
- Resolve Items
- History
- Repository
- Service
- API
- Tests

---

# Sprint 11 — Activity Logs Module

## Tables

- activity_logs

## Deliverables

- Automatic Log Creation
- Timeline Retrieval
- Filters
- Repository
- Service
- API
- Tests

---

# Sprint 12 — Authentication

## Deliverables

- Supabase Authentication
- JWT Validation
- Dependency Injection
- Protected APIs

---

# Sprint 13 — SQLite Synchronization Engine

## Deliverables

- SQLite First Policy
- Upload Sync
- Download Sync
- Conflict Resolution
- Retry Logic
- Sync Metadata

---

# Sprint 14 — Flutter Data Layer Integration

## Deliverables

Replace dummy data with backend APIs.

Connect:

- Riverpod
- Repositories
- Dio
- SQLite

---

# Sprint 15 — WhatsApp Bot Integration

## Deliverables

- Webhooks
- Intent Parsing
- Structured Commands
- Review Queue Integration

No AI.

---

# Sprint 16 — AI Integration

## Deliverables

- Intent Understanding
- RAG
- Context Engine
- Review Queue Learning
- Activity Log Context
- Decision Assistant

---

# Sprint 17 — Finance Module

Finance Module implementation begins only after the core application is stable.

This module will be documented separately.