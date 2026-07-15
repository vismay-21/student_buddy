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

# Sprint 12 — Backend Verification & Flutter API Integration

## Objectives

### Backend Verification
- Run FastAPI locally.
- Verify every API using Swagger.
- Test CRUD operations.
- Test validations.
- Test business rules.
- Verify Activity Logs.
- Verify Review Queue.
- Verify lecture generation.
- Verify attendance calculations.
- Fix any backend bugs.

### Flutter Integration
- Replace every piece of dummy data with backend APIs.
- Connect Flutter to FastAPI using:
  - Dio
  - Repository Layer
  - DTOs
  - API Clients
- Do NOT implement:
  - Authentication
  - SQLite
  - Offline Sync
  - WhatsApp
  - AI
- The app should become completely usable with a running backend.

### Supported Modules
- Semester
- Subjects
- Timetable
- Attendance
- Todo
- Notes
- Review Queue
- Settings
- Activity Timeline

## Deliverable
- A complete working Student Buddy application using the existing REST APIs.

---

# Sprint 13 — Authentication (Completed)

## Deliverables
- Supabase Authentication & Multi-Tenancy Architecture
- PyJWT token validation & local signature verification
- Protected REST API endpoints using FastAPI dependencies
- Decoupled application-level `users` database table
- Workspace provisioning auto-initialization flow (`POST /api/v1/users/me/initialize`)
- Scoped repository constructors for data isolation
- Multi-tenant test suite using mocked authentication overrides

# Sprint 14A — Offline Foundation (Completed)

## Goal
Transform Student Buddy into a fully functional offline-first application while preserving the existing authenticated architecture. 

During Sprint 14A:
* SQLite becomes the primary local data store for the running Flutter application.
* PostgreSQL remains the authoritative cloud database.
* The application reads and writes data only through SQLite.
* Synchronization does not yet exist.
* Sprint 14B will later reconcile SQLite with PostgreSQL.

## Repository Architecture & Abstraction
To ensure a clean separation of concerns and allow for future synchronization features, we enforce the following data layer flow:
```text
Flutter UI  ──>  Riverpod  ──>  Offline Repository Interfaces  ──>  SQLite Repository Implementations  ──>  SQLite
```
* **Strict Abstraction**: The Flutter UI and state controllers must never communicate directly with SQLite.
* **Synchronization Readiness**: This interface abstraction is essential because Sprint 14B will later extend the repositories with synchronization behavior without changing the UI or Riverpod layers.

## Deliverables & Responsibilities
- **SQLite Initialization**: Configure the local database using sqflite, setting up database creation and lifecycle management.
- **Local Database Schema**: Define tables matching semesters, subjects, lecture templates, lecture instances, holidays, settings, todos, notes, review queues, and activity logs.
- **Offline Repository Layer**: Implement repositories implementing the offline interfaces for SQLite queries.
- **Atomic Workspace Bootstrap**: Design the first-time download process to pull all remote database records from the backend and populate the SQLite database.
- **Lightweight Bootstrap Metadata**: The application must persist enough bootstrap state to determine whether the initial workspace download has already completed. This state is *not* synchronization metadata.
- **CRUD Operations**: Read and write all application data exclusively through SQLite during normal usage.
- **App Startup**: Boot the application by immediately reading data from SQLite on startup.
- **UI Behavior**: Ensure the interface behaves identically whether the device is online or offline.

## Bootstrap Lifecycle
To ensure the backend is only queried once for initial provisioning:
```text
[First Login]
Login  ──>  Workspace Initialize  ──>  Download complete workspace  ──>  Populate SQLite  ──>  Store bootstrap metadata  ──>  Normal application usage

[Future App Launches]
Launch  ──>  Read SQLite immediately  ──>  Do NOT perform a complete bootstrap again
```
* **Single-Bootstrap Policy**: The bootstrap process runs only on first-time login/registration or during an explicit database reset. It must not run on subsequent app launches or normal session restorations.

## UUID Consistency Rules
- SQLite must preserve exactly the same UUIDs generated/used by PostgreSQL.
- Existing backend UUIDs must never be replaced with local database identifiers.
- Local SQLite tables must never use auto-incrementing integer IDs.
- Primary keys and identifiers must remain identical across:
  ```text
  PostgreSQL  <──>  FastAPI  <──>  SQLite  <──>  Flutter DTOs
  ```

## User Isolation Rules
- SQLite database data must be strictly user-scoped.
- User A's local database must never be visible to User B.
- Logging out must clear or safely isolate local user data (e.g. deleting or locking the local database file).
- Logging in with another account must bootstrap only that specific user's workspace.

## Atomic Workspace Bootstrap Integrity
- The initial workspace bootstrap must behave as an atomic process.
- If any stage of the download or database populate fails (e.g. semesters and subjects are imported but lecture templates fail), the bootstrap must fail safely without leaving a partial, corrupted local workspace state. The application must revert or mark the bootstrap state as incomplete to prompt a retry.

## Explicitly Excluded
The following features are strictly excluded from Sprint 14A:
- Upload synchronization (no pending updates queued or pushed to backend)
- Download synchronization (no background updates fetched from PostgreSQL)
- Conflict resolution (no automatic or manual merging of data)
- Retry engine and connectivity listeners
- Background workers and queue processing
- Synchronization metadata (such as pending operations, local mutation timestamps, etc.)

---

# Sprint 14B — Synchronization Engine

## Goal
Synchronize the local SQLite database with the PostgreSQL database on the backend while preserving the offline-first architecture established in Sprint 14A. 

## Deliverables & Responsibilities
- **Sync Metadata Tables**: Store local metadata tracking pending changes, local mutation timestamps, and last sync status details.
- **Upload Queue**: Track and process pending local mutations (inserts, updates, deletes) sequentially to replicate them on PostgreSQL.
- **Download Reconciler**: Retrieve and merge changes from PostgreSQL since the last sync timestamp.
- **Background Sync**: Implement background workers and retry logic for failed requests.
- **Conflict Resolution**: Establish conflict detection rules and strategies (e.g., client-wins, server-wins, manual merges).
- **Connectivity Monitoring**: Integrate listeners to automatically trigger synchronization once network connection is recovered.
- **UI Indicators**: Provide manual sync actions and status icons to show connection/sync state.

*Note: Sprint 14B assumes that the Sprint 14A Offline Foundation is already fully implemented.*

---

# Sprint 14C — State Management Modernization (Completed)

## Goal
Modernize state management in the Flutter application by migrating to Riverpod, decoupling read (state query) and write (mutation action) operations, and improving layout components to prevent keyboard overlay issues on auth screens.

## Deliverables
- **Riverpod Migration**: Refactor Todo and Timetable screens to `ConsumerStatefulWidget` / `ConsumerWidget` with central providers.
- **CQRS separation of Read & Write**: Decouple state exposure from action triggers to ensure reactive and reload-free UI flows.
- **Form Keyboard UX**: Redesign login and signup forms to prevent components or CTA buttons from hiding behind virtual keyboards, with back buttons placed correctly in the app bar.

*Note: Sprint 14C assumes that the Sprint 14B Synchronization Engine is already fully implemented.*

---

# Deployment & Operations (Production Readiness Milestone)

## Goal
Remediate the infrastructure gaps identified in Audit 11 and deploy the feature-complete backend to production (FastAPI on Railway and PostgreSQL on Supabase). Secure the client-server connection and conduct a full end-to-end operational verification before proceeding to WhatsApp or AI integrations.

The backend core REST architecture is now frozen as feature-complete for MVP Version 1. Future work will extend the platform rather than redesigning it.

## Deliverables & Tasks
- **Audit 11 Remediation:** Resolve port binding, security headers, reverse-proxy forwarding, fail-fast variable validations, and OpenAPI schema protections.
- **Supabase PostgreSQL Provisioning:** Setup the production Supabase database.
- **FastAPI Railway Deployment:** Configure, build, and deploy backend service with automated migrations.
- **Flutter Production Build:** Point API constants and Supabase credentials to production without hardcoded fallbacks using compile-time variables (`--dart-define`).
- **Smoke Testing:** Execute the 18-step Post-Deployment Smoke Test suite to verify user isolation, authentication, SQLite creation, and synchronization pipelines.

---

# Sprint 15 — WhatsApp Integration

## Deliverables
- Meta Cloud API
- Webhooks
- Command parser
- Review Queue integration
- No AI

---

# Sprint 16 — AI Integration

## Deliverables
- Natural Language Understanding
- OCR
- RAG
- Context Engine
- Decision Assistant

---

# Sprint 17 — Finance Module

Finance Module implementation begins only after the core application is stable.

This module will be documented separately.

---

# MVP Implementation Rule

Before implementing Authentication, SQLite Sync, WhatsApp or AI, the application must be fully usable using the existing FastAPI backend.

This means:

Flutter
↓
Dio
↓
FastAPI
↓
PostgreSQL

without any authentication layer.

The MVP should support all existing backend functionality through REST APIs.

The goal is to validate business logic and user experience before introducing additional complexity.

---

# Implementation Priority Rule

Unless explicitly instructed otherwise, always implement features assuming the application is operating in MVP mode.

MVP Mode consists of:

Flutter
↓
FastAPI
↓
PostgreSQL

No Authentication
No SQLite
No WhatsApp
No AI

Every new feature should first be implemented and verified in MVP mode before integration with advanced infrastructure.

Authentication, SQLite, WhatsApp and AI should be treated as extension layers that wrap existing functionality rather than replacing it.