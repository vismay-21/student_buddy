# STUDENT BUDDY - DEVELOPMENT ROADMAP (DRD v1.0)

## Development Philosophy

**Golden Rule: Never build one feature completely in a single go.**

Do NOT think:

"Let's build Attendance."

Because Attendance itself depends on:

* UI
* Backend
* Database
* Notifications
* WhatsApp
* AI
* Analytics

Instead, build the entire system layer by layer.

Build horizontally, not vertically.

---

# Phase 0 - Environment Setup

**Estimated Duration:** 1 Day

### Goal

Set up the complete development environment and freeze the project architecture.

### Tasks

Create the project structure:

```text
student_buddy/

mobile_app/

backend/

docs/
```

Install and configure:

* Flutter
* Android Studio
* Python
* FastAPI
* Git
* Supabase account
* Meta Developer account

### Deliverable

The entire development environment is ready.

No coding yet.

---

# Phase 1 - Build Flutter UI Skeleton

**Estimated Duration:** 2-3 Days

### Goal

Build only the application's visual structure.

### Important Rule

Do NOT implement:

* Backend
* Database
* AI
* WhatsApp
* Business logic

Use only hardcoded dummy data.

### Create Screens

* Login
* Overview
* Attendance
* Timetable
* Finance
* Assignments
* Notes
* Review Queue
* Settings

Example dummy data:

```text
DBMS

83%

Can safely skip 1 lecture
```

### Deliverable

The entire app is visually complete and navigable.

---

# Phase 2 - Authentication (Postponed to Phase 7)

> [!NOTE]
> This phase has been postponed to Phase 7 to prioritize building a fully functional MVP connected directly to REST APIs first.

Still no backend at this point in historical sequence.

---

# Phase 3 - FastAPI Setup

**Estimated Duration:** 1 Day

### Goal

Set up the backend skeleton.

### Tasks

Create FastAPI project.

Create health endpoint.

Example:

```python
GET /

returns

Student Buddy Backend Running
```

### Deliverable

Backend server successfully runs.

---

# Phase 4 - Database Design

**Estimated Duration:** 2-3 Days

### Goal

Design the complete database before building features.

### Create Tables

* users
* semesters
* subjects
* class_sessions
* attendance_records
* assignments
* notes
* transactions
* finance_accounts
* categories
* review_queue
* academic_calendar
* notifications
* user_preferences

### Deliverables

* ER Diagram
* Database schema finalized

Do NOT build features yet.

---

# Phase 5 - Backend CRUD Development

**Estimated Duration:** 3-5 Days

### Goal

Create all backend APIs.

Examples:

Attendance:

```text
POST attendance

GET attendance

PUT attendance

DELETE attendance
```

Timetable:

```text
POST lecture

GET lecture

PUT lecture

DELETE lecture
```

Repeat for every module.

### Modules

* Attendance
* Timetable
* Finance
* Assignments
* Notes
* Review Queue
* Academic Calendar
* User Preferences

### Deliverable

Backend can independently manage all data.

No WhatsApp yet.

No AI yet.

---

# Phase 6 - Backend Verification & Flutter API Integration (MVP Mode)

**Estimated Duration:** 3-4 Days

### Goal

Verify the existing backend REST APIs and integrate Flutter with the completed FastAPI backend in MVP Mode.

### MVP Mode Architecture

No authentication, SQLite/offline sync, WhatsApp or AI.

```text
Flutter
↓
FastAPI
↓
PostgreSQL
```

### Tasks

- Run FastAPI locally.
- Verify every API using Swagger.
- Test CRUD operations, validations, business rules.
- Connect Flutter to FastAPI using:
  - Dio
  - Repository Layer
  - DTOs
  - API Clients
- Replace every piece of dummy data in Flutter with backend APIs.

### Deliverable

A completely working, usable Student Buddy application connected directly to REST APIs (without auth or offline sync).

---

# Phase 7 - Authentication

**Estimated Duration:** 1 Day

### Goal

Implement user authentication.

### Technology

Supabase Auth (JWT validation, protected endpoints, user context).

### Deliverable

Users can login, logout, and access protected endpoints with valid JWT sessions.

---

# Phase 8 - SQLite Synchronization Engine

**Estimated Duration:** 3 Days

### Goal

Enable offline-first capability.

### Architecture

```text
Flutter
↓
Repository
↓
SQLite
↓
FastAPI
↓
PostgreSQL
```

### Deliverable

Offline repositories and synchronization engine with conflict resolution and retry logic.

---

# Phase 9 - WhatsApp Integration

**Estimated Duration:** 4-5 Days

### Goal

Connect Meta Cloud API.

### Deliverables

- Webhooks
- Intent parsing & Command parser
- Review Queue integration
- Pure command-based flow, no AI.

---

# Phase 10 - Notification Engine

**Estimated Duration:** 2-3 Days

### Goal

Implement automated notifications.

### Technology

APScheduler

### Deliverable

Automated scheduled morning/night digests, class reminders.

---

# Phase 11 - AI & OCR Integration

**Estimated Duration:** 5-7 Days

### Goal

Implement intelligent automation.

### Deliverables

- Natural Language Understanding (WhatsApp bot message parsing)
- OCR (Timetable & Academic Calendar parsing via Gemini Vision)
- RAG, Context Engine, Decision Assistant

---

# Phase 12 - Finance Module

Finance Module implementation begins only after the core application is stable.

This module will be documented separately.

---

# Features NOT to Build Initially

Keep these in Future Scope:

* AI Study Planner
* Exam Planner
* Resume Tracker
* Voice Support
* Advanced Semester Analytics

---

# Official Development Order

0. Environment Setup (Completed)
1. Flutter UI Skeleton (Completed)
2. FastAPI Setup, Database Design & CRUD (Completed through Sprint 11)
3. Backend Verification & Flutter API Integration (MVP Mode - Current Priority)
4. Authentication (Phase 7)
5. SQLite Synchronization Engine (Phase 8)
6. WhatsApp Integration (Phase 9)
7. Notification Engine (Phase 10)
8. AI & OCR Integration (Phase 11)
9. Finance Module (Phase 12)

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

---

# AI Development Rule (MOST IMPORTANT)

Never give the entire MRD to an AI and say:

"Build Student Buddy."

Instead, always work phase by phase.

Example:

Current Phase: Phase 1

Build only the Flutter UI skeleton.

Do not implement:

* Backend
* AI
* Databases
* WhatsApp
* Business logic

Create reusable components and proper navigation.

Then move to the next phase.

This approach will make AI coding tools significantly more reliable.

END OF DRD v1.0

