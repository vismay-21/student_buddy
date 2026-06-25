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

# Phase 2 - Authentication

**Estimated Duration:** 1 Day

### Goal

Implement user authentication.

### Technology

Supabase Auth

### Flow

```text
Splash Screen

↓

Login Screen

↓

OTP Verification

↓

Dashboard
```

### Deliverable

Users can:

* Login
* Logout
* Maintain session

Still no backend.

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

# Phase 6 - Connect Flutter and FastAPI

**Estimated Duration:** 3-4 Days

### Goal

Replace dummy data with real backend data.

Current:

```text
Flutter

↓

Hardcoded data
```

Replace with:

```text
Flutter

↓

FastAPI

↓

Supabase
```

### Deliverable

App displays real data.

---

# Phase 7 - Add SQLite Offline Support

**Estimated Duration:** 3 Days

### Goal

Enable offline functionality.

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

Supabase
```

Rules:

```text
Internet Available

↓

Cloud Data

Internet Unavailable

↓

SQLite Data
```

When internet returns:

```text
Auto Sync

↓

Update SQLite

↓

Update Cloud
```

### Deliverable

App works without internet.

---

# Phase 8 - Implement Riverpod

**Estimated Duration:** 3 Days

### Goal

Enable centralized state management.

### Providers

* AuthProvider
* SemesterProvider
* AttendanceProvider
* TimetableProvider
* FinanceProvider
* AssignmentProvider
* NotesProvider
* ReviewQueueProvider
* SettingsProvider

### Deliverable

UI automatically updates when data changes.

---

# Phase 9 - WhatsApp Integration

**Estimated Duration:** 4-5 Days

### Goal

Connect Meta Cloud API.

### Initial Commands

Attendance:

```text
Present

Absent

Cancelled
```

Finance:

```text
Spent 250 on lunch
```

Assignments:

```text
Maths assignment due Friday
```

Notes:

```text
Send CN Unit 2 notes
```

### Important Rule

Do NOT use AI yet.

Initially implement command-based processing.

### Deliverable

WhatsApp ↔ FastAPI communication works.

---

# Phase 10 - Notification Engine

**Estimated Duration:** 2-3 Days

### Goal

Implement automated notifications.

### Technology

APScheduler

### Features

* Morning Digest
* Before Lecture Reminder
* After Lecture Reminder
* Assignment Reminder
* Night Digest

### Important Rule

No AI.

Pure scheduling logic.

### Deliverable

Automated notifications working.

---

# Phase 11 - AI Integration

**Estimated Duration:** 5-7 Days

### Goal

Add AI only where necessary.

### Responsibilities

Natural Language Understanding

Examples:

```text
Spent ₹250 on lunch

Present in DBMS

DBMS assignment due Friday

Send CN Unit 2 notes
```

AI converts natural language into structured data.

### AI Features

1. Context Engine

Prioritize information.

2. Semester Drift Detection

Detect patterns.

3. Cognitive Load Balancer

Identify heavy academic weeks.

4. Decision Assistant

Examples:

```text
Should I attend today's lecture?

Should I finish this assignment today?
```

### Important Rule

AI should NEVER perform deterministic calculations.

### Deliverable

AI genuinely adds value.

---

# Phase 12 - OCR Integration

**Estimated Duration:** 3-5 Days

### Goal

Implement image understanding.

### Features

Timetable OCR

Academic Calendar OCR

### Flow

```text
Image

↓

Gemini Vision

↓

Review Queue

↓

Database
```

### Deliverable

Students upload once per semester instead of manually entering everything.

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

0. Environment Setup

1. Flutter UI Skeleton

2. Authentication

3. FastAPI Setup

4. Database Design

5. Backend CRUD

6. Flutter ↔ FastAPI Integration

7. SQLite Offline Support

8. Riverpod State Management

9. WhatsApp Integration

10. Notification Engine

11. AI Integration

12. OCR Integration

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

