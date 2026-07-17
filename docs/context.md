# Student Buddy - End of Phase Context Preservation

This document serves as the long-term memory of **Student Buddy**. It preserves key architectural decisions, core philosophies, product modules, technology stack definitions, folder structures, and phase plans to ensure future AI sessions retain complete context.

---

## 1. Project Vision

Student Buddy is a comprehensive, integrated Student Operating System designed to streamline and simplify a student's academic and financial life. In a world where students are constantly overwhelmed with notifications, deadlines, schedules, and budgets, Student Buddy acts as a centralized brain that manages details so students don't have to.

The primary objective of Student Buddy is to reduce the number of daily micro-decisions and repetitive tasks in a student's life. Rather than forcing students to navigate multiple apps, check disjointed schedules, or manually calculate complex academic metrics, Student Buddy automates these processes, acting as an ambient helper that provides context-aware assistance when and where it is needed most.

The system consists of two primary components working in tandem:
* **WhatsApp Chatbot**: The primary interaction layer, allowing users to log data and retrieve key information on-the-go without opening a dedicated app.
* **Flutter Mobile Application**: The visualization, dashboard, configuration, and analytics layer, allowing users to review their data in detail, customize configurations, and resolve complex items.

---

## 2. Core Philosophy

* **Reduce friction, not add features**: Every feature added must serve the purpose of lowering cognitive load and saving time. Avoid bloating the system with unnecessary tools.
* **Do not use AI everywhere**: Use AI only where ambiguity exists or natural language processing is required. Deterministic logic should be preferred by default.
* **Use deterministic logic whenever possible**: Calculations, scheduling, database queries, and static rules must run on simple, predictable logic.
* **The product's biggest asset is long-term memory, not AI**: The system's value comes from keeping a reliable, structured history of a student's semester to make intelligent, localized decisions.

---

## 3. Product Modules

#### Academic Module (Mandatory)
* **Timetable**: Weekly repeating timetable supporting room numbers, faculty details, and visual schedule builders.
* **Attendance**: Subject-wise tracking with smart suggestions (e.g., safe skip calculations and target path planning).
* **To Do**: Basic task tracker focusing on due-date reminders rather than comprehensive task management.
* **Notes**: Document management categorized by Semester → Subject → Unit, supporting easy retrieval.
* **Academic Calendar**: Holds holidays, exams, and key events, feeding into notifications and attendance metrics.

### Finance Module (Optional)
* **Accounts**: Supports multiple payment structures (Cash, UPI, Savings Accounts).
* **Income**: Tracking salary, pocket money, or stipends.
* **Expenses**: Categorized expense tracking.
* **Transfers**: Moving money between accounts.
* **Budgets**: Monthly budget setting and tracking.

### Support Module
* **Review Queue**: A holding area for low-confidence data (e.g., OCR or ambiguous text logs) awaiting user confirmation.
* **Digests**: Pre-scheduled morning and night summaries sent to WhatsApp.
* **Notifications**: Reminders for upcoming lectures, tasks, and budgets.

### Semester Management
* **Semester-based organization**: All academic data, schedules, and attendance metrics are containerized inside specific semesters.

---

## 4. WhatsApp Philosophy

WhatsApp is the daily, low-friction interaction layer. Users should not have to open the Flutter app for repetitive, daily actions.

* **WhatsApp handles**:
  * Quick attendance logging ("Present", "Absent", "Cancelled" after a class).
  * Quick expense logging ("Spent 250 on lunch").
  * Adding task reminders ("Maths assignment due Friday").
  * Fast notes retrieval ("Send CN Unit 2 notes").
  * Quick queries and question answering.
  * Receiving morning and night digests.

* **The Flutter App handles**:
  * Detailed dashboards and visual overviews.
  * In-depth analytics, trends, and charts.
  * Reports and configurations.
  * The Review Queue (for resolving data entry ambiguities).
  * Main settings and module controls.

---

## 5. AI Philosophy

AI is utilized selectively to handle unstructured data, ambiguity, and complex reasoning, while deterministic systems handle math and scheduling.

* **AI WILL be used for**:
  * **Natural language understanding (NLU)**: Parsing messages like "Spent ₹250 on lunch from UPI" or "Present in DBMS" on WhatsApp.
  * **OCR timetable extraction**: Converting image files/screenshots of timetables and academic calendars into structured data.
  * **Context prioritization**: Deciding which tasks or schedules are urgent and should be highlighted.
  * **Semester drift detection**: Finding patterns like falling attendance or accelerating expenses over time.
  * **Cognitive load balancing**: Warning the user of highly taxing weeks (e.g., multiple submissions and exams overlapping) and suggesting priorities.
  * **Decision assistance**: Providing advice when asked (e.g., "Should I skip DBMS today?").

* **AI WILL NOT be used for**:
  * Attendance percentage calculations.
  * Finance/balance calculations.
  * Budget remaining/spent calculations.
  * Dashboard rendering or UI generation.
  * Triggering scheduled notifications.
  * Predicting attendance rates.

Always prefer deterministic systems first.

---

## 6. Tech Stack Decisions

* **Frontend**: Flutter + Dart
* **State Management**: Riverpod
* **Backend**: Python + FastAPI
* **Authentication**: Supabase Auth (Email/Password authentication) + Decoupled Local Users Table
* **Cloud Database**: Supabase PostgreSQL
* **Local Database**: SQLite (for offline-first support)
* **WhatsApp**: Meta Cloud API
* **AI**: Gemini API (utilizing free tier if available)
* **Vision**: Gemini Vision (utilizing free tier if available)
* **Scheduler**: FastAPI scheduler (transitioning to APScheduler in the backend)
* **Deployment**: To be determined (future phase, e.g., Railway)
* **Architecture**: Offline-first + online synchronization

---

## 7. Architecture Rules

* **One user = one device**: The app is built for personal productivity and is not collaborative.
* **Academic module is mandatory**: This is the core of Student Buddy and cannot be disabled.
* **Finance module is optional**: Users can toggle this module off in settings, hiding all finance-related views.
* **Weekly repeating timetable only**: Schedules repeat on a weekly cycle (Monday-Sunday).
* **Semester-based data organization**: Every major academic entity is attached to a specific semester.
* **App and WhatsApp work together**: Both systems communicate with the same backend database; the product is designed around their synergy.
* **WhatsApp reads from the central database**: WhatsApp chatbot commands query and write to the Supabase database via the FastAPI backend.

---

## 8. Current Folder Structure

Below is the complete file and folder structure of the Student Buddy project down to the leaf nodes (end files), detailing the specific purpose of each file:

```text
student_buddy/
├── android/                             # Android native platform folder
├── ios/                                 # iOS native platform folder
├── windows/                             # Windows native platform folder
├── macos/                               # macOS native platform folder
├── linux/                               # Linux native platform folder
├── web/                                 # Web native platform folder
│
├── docs/                                # Documentation files (Project Memory & System Specs)
│   ├── audit/                           # Phase-by-phase quality and security audit reports
│   │   ├── audit_01_architecture.md
│   │   ├── audit_02_database.md
│   │   ├── audit_03_business_logic.md
│   │   ├── audit_04_api.md
│   │   ├── audit_05_performance.md
│   │   ├── audit_06_security.md
│   │   ├── audit_07_flutter_integration.md
│   │   ├── audit_08_code_quality.md
│   │   ├── audit_09_testing.md
│   │   ├── audit_10_production_readiness.md
│   │   ├── audit_11_deployment_operations.md
│   │   ├── audit_summary.md
│   │   └── implementation_plan_audit_11_deployment_operations.md
│   ├── database/                        # Database design documents
│   │   ├── 04_entity_relationship_diagram.md
│   │   ├── 1_database_schema.md
│   │   ├── 2_database_business_flow.md
│   │   └── 3_database_sync_strategy.md   # Sync protocol and queue coalescing rules
│   ├── 1_STUDENT BUDDY MASTER REQUIREMENTS DOCUMENT MRD.txt
│   ├── 2_STUDENT BUDDY DEVELOPMENT ROADMAP DCOUMENT DRD.md
│   ├── 3_backend_architecture_and_development_plan.md
│   ├── 4_backend_implementation_sprints.md
│   ├── 5_mvp_backend_audit_plan.md
│   ├── context.md                       # This file (Project Memory / Context)
│   └── history.md                       # Project decisions & implementation history log
│
├── test/                                # Frontend unit and integration tests
│   ├── sync_coalesce_test.dart          # Verifies sync coalescing rules (Rules 1-4)
│   ├── sync_lifecycle_test.dart         # Integration tests for upload/download pipelines and error backoffs
│   └── uuid_generator_test.dart         # Validates local client-side UUID generator uniqueness
│
├── lib/                                 # Flutter Frontend codebase
│   ├── main.dart                        # Flutter application entry point, wraps app in ProviderScope
│   ├── core/                            # Shared core configurations and logic utilities
│   │   ├── exceptions/
│   │   │   └── sync_exceptions.dart     # Custom exceptions mapping synchronization and protocol issues
│   │   ├── models/
│   │   │   └── subject_template.dart    # Holds templates for recurring subject slots
│   │   ├── network/                     # Dio HTTP client setup and interceptors
│   │   │   ├── api_constants.dart       # Maps all REST endpoint paths and routes
│   │   │   ├── api_response.dart        # Unified HTTP Response mapping class
│   │   │   ├── base_api.dart            # Base class for API service wrappers
│   │   │   ├── dio_client.dart          # Custom Dio client wrapper configuration
│   │   │   └── interceptors.dart        # Authentication/token injector and network error handler
│   │   ├── providers/                   # Riverpod State Management Providers
│   │   │   ├── app_settings_provider.dart # Manages light/dark theme state & configurations
│   │   │   ├── attendance_provider.dart  # Manages analytics, skipping recommendation state, and holiday checks
│   │   │   ├── auth_provider.dart        # Manages login sessions, authentication requests, and tokens
│   │   │   ├── common_providers.dart     # Holds shared providers (DB Helper, API modules)
│   │   │   ├── notes_provider.dart       # Manages section hierarchies and resource download states
│   │   │   ├── provider_observer.dart    # Debug observer logging Riverpod state transitions
│   │   │   ├── review_queue_provider.dart # Manages unresolved OCR conflicts review state
│   │   │   ├── semester_provider.dart    # Handles active semesters and cascading invalidation updates
│   │   │   ├── subject_provider.dart     # Manages academic courses and subjects list
│   │   │   ├── sync_provider.dart        # Controls live sync states, status cards, and manual sync action
│   │   │   ├── timetable_provider.dart   # Manages weekly class schedule calendar state
│   │   │   └── todo_provider.dart        # Manages task checklists, due dates, and priority lists
│   │   ├── services/                    # Business Service layer coordinating SQLite and remote sync
│   │   │   ├── attendance_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── bootstrap_service.dart    # Manages remote snapshot downloads and offline DB seeding
│   │   │   ├── notes_service.dart
│   │   │   ├── review_queue_service.dart
│   │   │   ├── semester_service.dart
│   │   │   ├── subject_service.dart
│   │   │   ├── sync_service.dart         # Central coordinator for offline operations and synchronization
│   │   │   └── todo_service.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart           # Unified app themes, gradients, and fonts
│   │   ├── utils/
│   │   │   ├── color_helper.dart        # Maps hex strings to Flutter Colors
│   │   │   ├── dummy_data.dart          # Holds placeholder static debug items
│   │   │   └── uuid_generator.dart      # Generates local unique IDs (UUIDv4) offline
│   │   └── widgets/                     # Reusable layout widgets
│   │       ├── app_snackbar.dart        # Central notification banner configuration
│   │       ├── attendance_ring_label.dart # Ring graphic rendering attendance statistics
│   │       └── expandable_section.dart  # Collapsible card widget for dashboard pages
│   │
│   ├── data/                            # Data Access Layer
│   │   ├── local/
│   │   │   └── database_helper.dart     # SQLite helper initializer, migration sets, and sync queue writer
│   │   ├── api/                         # Low-level network endpoints wrappers
│   │   │   ├── activity_log_api.dart
│   │   │   ├── app_settings_api.dart
│   │   │   ├── attendance_settings_api.dart
│   │   │   ├── holiday_api.dart
│   │   │   ├── lecture_instance_api.dart
│   │   │   ├── lecture_template_api.dart
│   │   │   ├── notes_api.dart
│   │   │   ├── review_queue_api.dart
│   │   │   ├── semester_api.dart
│   │   │   ├── subject_api.dart
│   │   │   ├── todo_api.dart
│   │   │   └── user_api.dart
│   │   ├── dto/                         # JSON Serialization/Deserialization models
│   │   │   ├── activity_log/
│   │   │   │   └── activity_log_dto.dart
│   │   │   ├── attendance/
│   │   │   │   └── attendance_settings_dto.dart
│   │   │   ├── holiday/
│   │   │   │   └── holiday_dto.dart
│   │   │   ├── lecture/
│   │   │   │   ├── lecture_instance_dto.dart
│   │   │   │   └── lecture_template_dto.dart
│   │   │   ├── notes/
│   │   │   │   └── notes_dto.dart
│   │   │   ├── review_queue/
│   │   │   │   └── review_queue_dto.dart
│   │   │   ├── semester/
│   │   │   │   └── semester_dto.dart
│   │   │   ├── settings/
│   │   │   │   └── app_settings_dto.dart
│   │   │   ├── subject/
│   │   │   │   └── subject_dto.dart
│   │   │   └── todo/
│   │   │       └── todo_dto.dart
│   │   └── repositories/                # Repository interface definitions and SQLite implementations
│   │       ├── sqlite/                  # Concrete local SQLite database queries
│   │       │   ├── sqlite_activity_log_repository.dart
│   │       │   ├── sqlite_app_settings_repository.dart
│   │       │   ├── sqlite_attendance_settings_repository.dart
│   │       │   ├── sqlite_holiday_repository.dart
│   │       │   ├── sqlite_lecture_instance_repository.dart
│   │       │   ├── sqlite_lecture_template_repository.dart
│   │       │   ├── sqlite_notes_repository.dart
│   │       │   ├── sqlite_review_queue_repository.dart
│   │       │   ├── sqlite_semester_repository.dart   # Runs date cascading updates locally
│   │       │   ├── sqlite_subject_repository.dart
│   │       │   └── sqlite_todo_repository.dart
│   │       ├── activity_log_repository.dart
│   │       ├── app_settings_repository.dart
│   │       ├── attendance_settings_repository.dart
│   │       ├── holiday_repository.dart
│   │       ├── lecture_instance_repository.dart
│   │       ├── lecture_template_repository.dart
│   │       ├── notes_repository.dart
│   │       ├── review_queue_repository.dart
│   │       ├── semester_repository.dart
│   │       ├── subject_repository.dart
│   │       └── todo_repository.dart
│   │
│   └── screens/                         # UI Screens & Layouts
│       ├── navigation_shell.dart        # Main layout frame carrying tabs and side nav
│       ├── attendance/                  # Attendance and analytics tabs
│       │   ├── widgets/
│       │   │   ├── attendance_analytics_card.dart
│       │   │   ├── attendance_calendar_legend.dart
│       │   │   ├── attendance_day_summary_card.dart
│       │   │   ├── attendance_overview_card.dart
│       │   │   └── lecture_card.dart
│       │   ├── attendance_screen.dart
│       │   ├── attendance_settings_tab.dart
│       │   ├── day_history_screen.dart
│       │   ├── history_tab.dart
│       │   ├── subject_history_screen.dart
│       │   └── subjects_tab.dart
│       ├── auth/                        # Registration / Login forms
│       │   ├── forgot_password_screen.dart
│       │   ├── login_screen.dart
│       │   └── signup_screen.dart
│       ├── finance/
│       │   └── finance_screen.dart       # Finance module UI (disabled/frozen by default)
│       ├── notes/                       # Uploaded files and study materials organizer
│       │   ├── add_resource_screen.dart
│       │   ├── notes_config.dart
│       │   ├── notes_screen.dart
│       │   └── resource_card.dart
│       ├── overview/
│       │   └── overview_screen.dart     # Core app dashboard
│       ├── review_queue/                # Timetable import review
│       │   ├── review_queue_edit_screen.dart
│       │   └── review_queue_screen.dart
│       ├── settings/
│       │   ├── semester_selection_screen.dart
│       │   └── settings_screen.dart     # System settings and sync cards
│       ├── splash/
│       │   └── splash_screen.dart       # Verifies local storage setup on launch
│       ├── timetable/                   # Recurring classes grid
│       │   ├── add_class_screen.dart
│       │   └── timetable_screen.dart
│       └── todo/                        # Task manager list
│           ├── add_todo_screen.dart
│           └── todo_screen.dart
│
├── backend/                             # Python FastAPI Backend
│   ├── requirements.txt                 # Python dependencies
│   ├── Dockerfile                       # Production container setup
│   ├── docker-compose.yaml              # Local PostgreSQL + FastAPI orchestration config
│   ├── README.md                        # Backend documentation guide
│   ├── alembic.ini                      # Migration settings
│   ├── alembic/                         # Alembic database migration scripts
│   │   ├── env.py
│   │   ├── script.py.mako
│   │   └── versions/
│   │       ├── 192b4793464e_create_semester_and_attendance_settings_.py
│   │       ├── 1a9ff58b8423_create_subjects_and_notes_subjects_.py
│   │       ├── 2db1602c28b4_create_lecture_template_instance_.py
│   │       ├── ca2a9e095c10_create_app_settings_table.py
│   │       ├── 6e718cd5065a_create_todos_table.py
│   │       └── e4ffe7e8e71b_create_notes_tables.py
│   ├── tests/                           # Python pytest verification suite
│   │   ├── conftest.py                  # Seeding, cleanup, and DB connection overrides
│   │   ├── academic/
│   │   │   ├── test_attendance_settings.py
│   │   │   ├── test_holidays.py
│   │   │   ├── test_lecture_instances.py
│   │   │   ├── test_lecture_templates.py
│   │   │   ├── test_semesters.py
│   │   │   └── test_subjects.py
│   │   ├── activity_logs/
│   │   │   └── test_activity_logs.py
│   │   ├── notes/
│   │   │   └── test_notes.py
│   │   ├── review_queue/
│   │   │   └── test_review_queue.py
│   │   ├── security/
│   │   │   └── test_security.py
│   │   ├── settings/
│   │   │   ├── test_app_settings.py
│   │   │   ├── test_bootstrap.py
│   │   │   └── test_user_service.py
│   │   ├── todo/
│   │   │   └── test_todos.py
│   │   └── test_health.py
│   └── app/                             # Core FastAPI application module
│       ├── main.py                      # Router mapping, CORS configurations, and startup events register
│       ├── api/                         # Router routes configuration
│       │   ├── v1/
│       │   │   ├── academic/
│       │   │   │   ├── attendance_settings.py # Endpoints mapping attendance targets
│       │   │   │   ├── holidays.py            # Endpoints mapping academic holidays
│       │   │   │   ├── lecture_instances.py   # Endpoints marking daily lecture attendance status
│       │   │   │   ├── lecture_templates.py   # Endpoints mapping class schedules
│       │   │   │   ├── semesters.py           # Endpoints managing school semesters
│       │   │   │   └── subjects.py            # Endpoints managing subject lists
│       │   │   ├── activity_logs/
│       │   │   │   └── activity_logs.py       # Endpoints retrieving log timelines
│       │   │   ├── notes/
│       │   │   │   └── notes.py               # Endpoints managing notes upload/download
│       │   │   ├── review_queue/
│       │   │   │   └── review_queue.py        # Endpoints reviewing parser results
│       │   │   ├── settings/
│       │   │   │   └── app_settings.py        # Endpoints retrieving user app preferences
│       │   │   ├── todo/
│       │   │   │   └── todos.py               # Endpoints performing todo CRUD
│       │   │   ├── users/
│       │   │   │   └── users.py               # Endpoints provisioning profile settings & downloads
│       │   │   └── health.py                  # Endpoint verifying DB health
│   │   │   └── __init__.py
│       ├── core/                        # Central system settings and DB engine definitions
│       │   ├── config.py                  # Environment variables parser
│       │   ├── constants.py               # Central version constants (Sync versions, etc.)
│       │   ├── context.py                 # Thread-scoped context variables (e.g. current actor user ID)
│       │   ├── database.py                # SQL Alchemy engine setup
│       │   ├── exceptions.py              # Custom exceptions mapping
│       │   ├── logging.py                 # Logger utilities config
│       │   └── security.py                # JWT validator & Bearer token processor
│       ├── dependencies/                # Injection hooks for handlers
│       │   ├── auth.py                    # Resolves user context from tokens
│       │   └── database.py                # Resolves current active db session
│       ├── models/                      # SQLAlchemy Database models (PostgreSQL structure mapping)
│       │   ├── academic/
│       │   │   ├── attendance_settings.py
│       │   │   ├── holiday.py
│       │   │   ├── lecture_instance.py
│       │   │   ├── lecture_template.py
│       │   │   ├── semester.py
│       │   │   └── subject.py
│       │   ├── activity_logs/
│       │   │   └── activity_log.py
│       │   ├── notes/
│   │   │   ├── notes_resource.py
│   │   │   ├── notes_section.py
│   │   │   └── notes_subject.py
│   │   ├── review_queue/
│   │   │   └── review_queue.py
│   │   ├── settings/
│   │   │   └── app_settings.py
│   │   ├── todo/
│   │   │   └── todo.py
│   │   └── user.py
│   ├── repositories/                # Clean CRUD abstraction files
│   │   ├── academic/
│   │   │   ├── attendance_settings.py
│   │   │   ├── holiday.py
│   │   │   ├── lecture_instance.py
│   │   │   ├── lecture_template.py
│   │   │   ├── semester.py
│   │   │   └── subject.py
│   │   ├── activity_logs/
│   │   │   └── activity_log.py
│   │   ├── notes/
│   │   │   ├── notes_resource.py
│   │   │   ├── notes_section.py
│   │   │   └── notes_subject.py
│   │   ├── review_queue/
│   │   │   └── review_queue.py
│   │   ├── settings/
│   │   │   └── app_settings.py
│   │   └── todo/
│   │       └── todo.py
│   ├── schemas/                     # Pydantic request/response validation schemas
│   │   ├── academic/
│   │   │   ├── attendance_settings.py
│   │   │   ├── holiday.py
│   │   │   ├── lecture_instance.py
│   │   │   ├── lecture_template.py
│   │   │   ├── semester.py
│   │   │   └── subject.py
│   │   ├── activity_logs/
│   │   │   └── activity_log.py
│   │   ├── notes/
│   │   │   ├── notes_resource.py
│   │   │   ├── notes_section.py
│   │   │   └── notes_subject.py
│   │   ├── review_queue/
│   │   │   └── review_queue.py
│   │   ├── settings/
│   │   │   └── app_settings.py
│   │   ├── todo/
│   │   │   └── todo.py
│   │   ├── users/
│   │   │   └── bootstrap.py           # Remote seed database structure mapping
│   │   └── common.py                  # Holds standard API returns format
│   ├── services/                    # Business and Transaction execution logic rules
│   │   ├── academic/
│   │   │   ├── attendance_settings.py
│   │   │   ├── attendance_statistics.py # Skips target recalculations formulas
│   │   │   ├── holiday.py
│   │   │   ├── lecture_instance.py
│   │   │   ├── lecture_template.py
│   │   │   ├── semester.py
│   │   │   └── subject.py
│   │   ├── activity_logs/
│   │   │   ├── activity_log.py
│   │   │   ├── logger.py              # Savepoint activity logging orchestrator
│   │   │   └── summary.py
│   │   ├── auth/
│   │   │   └── authentication_service.py
│   │   ├── notes/
│   │   │   └── notes.py
│   │   ├── review_queue/
│   │   │   ├── review_queue.py
│   │   │   └── resolvers/             # Specific parser item conflict resolvers
│   │   │       ├── base.py
│   │   │       ├── finance.py
│   │   │       ├── lecture_instance.py
│   │   │       ├── registry.py
│   │   │       └── todo.py
│   │   ├── settings/
│   │   │   └── app_settings.py
│   │   ├── todo/
│   │   │   └── todo.py
│   │   └── users/
│   │       └── user.py                # User initialization & bootstrap packaging
│   └── utils/
│       └── attendance_calculator.py   # Core math equations for attendance rates
```
---

## 9. Current Backend Status

We have completed the **SQLite Synchronization Engine (Sprint 14B)**, having successfully built the local SQLite offline data foundation (Sprint 14A).


### 9.1. Frontend / UI (Phase 1 — Locked)

* **What was implemented**:
  * Visually complete Flutter UI skeleton covering all user screens: Splash, Login, OTP, Overview, Timetable, Attendance, Finance, Assignments, Notes, Review Queue, Settings, and Semester Selection.
  * Custom dark and light design system (teal/indigo glassmorphism and accents) in `app_theme.dart`.
  * Reactive Theme Switcher (Dark vs Light mode toggle) in settings bound via `ThemeMode` ValueNotifier.
  * Multi-screen flow navigation: Splash → Login → OTP → Navigation Shell (holding bottom tabs + right-side drawer drawer navigation).
  * Centralized mock states/variables via `ValueNotifier` in `app_state.dart` (such as active semester, active finance module, toggled settings) to simulate live interactions.
  * Centralized dummy data storage in `dummy_data.dart`.
  * Dedicated full-screen `AddClassScreen` replacing the legacy mock dialog, featuring:
    * **Subject Template Auto-Fill**: A dropdown that lets users pick a previously added subject template to auto-populate class details (Room, Faculty, Theme Color) for recurring weekly timetable classes. Includes rounded menu shapes (`borderRadius: 12`) and theme-consistent background colors.
    * **Dial-Mode Clock Time Pickers**: Native system time pickers configured in `dialOnly` mode (which disables keyboard switching and removes the bottom-left keyboard icon). Dialog layout scaled by `1.15x` to enlarge the circular clock diameter and dial numbers. Includes custom styled active/inactive selectors and AM/PM toggles.
    * **Large Click Touch Targets**: Time setting buttons updated to use full-width padded `InkWell` containers to make selection responsive and easy.
    * **Custom Swatch Color Picker**: A color choice popup for card styling.
  * **Day Selector Bar Animations**: Swapped standard container boxes for `AnimatedContainer` and `AnimatedDefaultTextStyle` elements in the weekly day selector strip.
  * **Lecture Card Design Improvements**: Expanded time column width to 60px and updated ending time text style/contrast (using dynamic brightness colors) to guarantee text readability in both Light and Dark mode variations.
  * **Attendance Redesign (Phase 1 UI)**:
    * Replaced the simple attendance screen with a 3-tab sub-navigation shell (History, Subjects, Settings) with a reduced height of 52px, removing the redundant Today tab.
    * Centralized all attendance calculations, logs, and state properties into a reactive `AppState` singleton class.
    * Created a unified, reusable `LectureCard` component replacing local timetable card builders and the custom subject cards, containing read-only weekly rendering and interactive attendance logging.
    * Reordered the History tab to place the overall status card (`AttendanceOverviewCard`) and Monthly Day Summary at the top of the history screen.
    * Converted calendar Month page swiping to horizontal.
    * Made Subject Cards in the Subjects tab clickable, navigating to a new, fully interactive `SubjectHistoryScreen` showing dynamic calculations and a class history log using `LectureCard`.
    * Renamed settings from "Target" to "Criteria", implemented 3 criteria modes (Overall, Subject-Wise, Subject-Wise Custom) with a per-subject configuration dialog, and removed legacy Default Days Off settings in favor of dynamically deriving default days off from the timetable/lecture templates at runtime.
    * Refactored `OverviewScreen` into a stateful panel displaying today's lectures via `LectureCard`, providing a "Mark Whole Day" quick-action bar, positioning the Review Queue warning card at the top of the dashboard (only shown if there are reviews pending), and removing the redundant Academic Status (with its To Do summary), Upcoming Events, Quick Shortcuts, and safe skip widgets to achieve a clean, focused layout.
  * **UI/UX Polish, Review Queue Forms & SnackBar Integration**:
    * Created a unified floating SnackBar component (`AppSnackbar` in `lib/core/widgets/app_snackbar.dart`) and migrated all 10 screen modules to use it.
    * Polished the `LectureCard` vertically to occupy 20-25% less height, and updated progress rings to display current/target ratios (e.g. `X/Y%`).
    * Added clear header labels "TODAY'S CLASSES" and "MARK WHOLE DAY" inside the `OverviewScreen`.
    * Merged the Monthly Day Summary and Monthly Lecture Stats cards inside `HistoryTab` into a single, compact `AttendanceAnalyticsCard` to prevent vertical scrolling and make the calendar immediately visible.
    * Overhauled the Review Queue module: removed the "Delete" action, implemented immediate default assignments for "Approve" with descriptive SnackBar confirmations, and built a dedicated full-screen editor (`ReviewQueueEditScreen`) with fields customized to Finance, OCR, and Class Cancellation review items.
  * **Collapsible Sections, Compact Rings & Clickable Semester Dialogs**:
    * Created a reusable `ExpandableSection` widget supporting an optional glassmorphic outer frame (`showFrame: true`) wrapping both the header and child list to create card-like accordions. Wrapped Today's Classes and Finance Summary dashboard sections inside `ExpandableSection(showFrame: true)`.
    * Developed `AttendanceRingLabel` to display current vs target criteria percentages in a vertical fraction format (`current/target %`) inside progress rings, and centered the fraction text block inside the ring using a balanced Row layout with larger font sizes (13) and wider divider lines.
    * Simplified `LectureCard` by removing duplicate Criteria and Attended metrics, merging the status message (font size: 13) and action buttons into a single row, and animating slightly larger action buttons to expand text only when selected.
    * Polished details inside `LectureCard`: set time column width to 44, subject name font size to 15.5, room text size to 13, and ensured start time uses a uniform primary text color.
    * Formatted safe skip status messages specifically: `"can skip X lectures"`, `"can't skip next lecture"`, and `"need to attend next X lectures"`.
    * Reordered `HistoryTab` layout, merging the Calendar Month View and the Color Legend into the same outer card container (dynamic height with smooth AnimatedContainer transition, page change animation: 500ms), separated by a Divider.
    * Implemented semester-wide stats aggregation and custom stats popup dialog showing detailed day and lecture statistics when tapping the Overall Attendance Card.
    * Redesigned `AppSnackbar` to be extremely lightweight: reduced heights, padding, font sizes, corner radius, and lowered floating margins (bottom: 8 when nav bar is present, 16 when not) to stay cleanly above navigation.
    * Standardized the bottom offset of the FloatingActionButton on the Timetable screen (padding: 60) to align with the main To Do FAB spacing.
    * Tuned main dashboard spacing (reduced heights of vertical separators to 16).
    * **Timetable Class Editing & Deletion**: Integrated an edit pencil icon on `LectureCard` in the Timetable view, pushing the pre-filled `AddClassScreen` for editing, and added a confirmation-alerted "DELETE CLASS" button.
    * **Attendance Calendar Refinements**:
      * Restricted Blue dots (bright dark blue color) strictly to University Holidays.
      * Mapped regular days off (all lectures marked day off) to a Yellow dot, and mixed/partial days off to a Purple dot.
      * Removed calendar dots for dates outside the semester range.
      * Implemented dynamic calendar card height sizing using `AnimatedContainer` that dynamically calculates the required height based on the number of calendar rows in the active month (`128 + rowCount * 48`) to ensure no empty space and zero legend overlap on all devices.
      * Refactored the calendar legend to use a `Wrap` layout with Column items (dots above and names below) to ensure a perfectly aligned single row under restricted width conditions, and updated the Holiday dot to a bright dark blue.
      * Restricted monthly totalDays calculations in history summaries to count only dates that fall inside the active semester range.
      * Unified the "Off" statistics display to "Off/Holiday" across the main dashboard analytics card and the semester details stats dialog.
      * Implemented an action lockout mechanism on University Holidays, disabling bulk day markers and individual lecture card update buttons, with clear disabled/faded styling.
    * **University Holiday Banner**: Integrated `HolidayRepository` in `DayHistoryScreen` to fetch and display the custom name of the holiday at the top of the day logs list when clicking on a holiday date.
    * **Attendance Analytics Modernization & Backend Sync**:
      * Synced all dashboard statistics in `subjects_tab.dart`, `history_tab.dart`, and `overview_screen.dart` with the live PostgreSQL database.
      * Standardized subject metrics text layout to `"Attended: X/Y • Total Lectures: Z"`.
      * Removed redundant criteria target labels and faculty/room rows from Subject Cards on `SubjectsTab`.
      * Streamlined `SubjectHistoryScreen` item layout to show only class times and a 4-button action row instead of full `LectureCard` components.
      * Normalized the `SubjectHistoryScreen` circular progress ring in the summary card to use the custom `_RingPainter` and `AttendanceRingLabel` widget for visual alignment.
      * Added holiday lock guards on bulk actions and individual lecture updates for days marked as holidays, displaying a clear Blue "University Holiday" banner on both the Overview Screen and Day History logs views.
      * Expanded bulk action triggers on the Overview Screen to include all four core actions (Clear, Day Off, Missed, Attended).
      * Aligned all action buttons (bulk action panel on Overview and Day History screens, plus individual lecture card buttons) to a standardized icon size of `15` and Title Case labels.
      * Enhanced decimal precision of attendance percentages on the history screen/dialogs to display two decimal places (e.g. `X.XX%`).
    * **Timetable Screen Improvements**:
      * Made the entire class card tappable (using a Material `InkWell` ripple splash effect) to trigger the class editing/details sheet directly on the Timetable screen, eliminating the visual clutter of having edit buttons on each subject card.
    * **Clean Up**: Removed unused `cancelled` and `future` statuses/cases across all frontend and backend codebase files to ensure clean architectures.


* **What was intentionally NOT implemented (postponed/frozen)**:
  * **Finance Module (FROZEN)**: All Finance module development is officially frozen. It is now disabled by default on clean installs, and the toggle state is persisted via `SharedPreferences`.
  * **Riverpod CQRS Migration (Sprint 14C — Completed)**: All persistent modules (Todo, Timetable, Attendance, Finance, Notes, Review Queue, Settings, Semester Selection, and the root `StudentBuddyApp`) have been fully migrated to the Riverpod CQRS architecture. The legacy `AppState` singleton is no longer referenced anywhere in the active codebase. Every UI screen now follows the reactive `Flutter UI → ReadProvider → ActionProvider → Service → Repository` pattern.

### 9.2. Backend Service Implementations

* **What was implemented (Sprint 0 - Backend Foundation)**:
  * Established the complete FastAPI project skeleton with folder structure matching the architectural specification.
  * Configured Pydantic settings loading from environmental files (`.env`), async database engine, and session maker in SQLAlchemy 2.x.
  * Structured unified python console logging format and custom application exception hierarchy with global FastAPI interceptors.
  * Designed standard API response formats (`ApiResponse` and `ApiErrorResponse`) and registered a testable health check router (`/api/v1/health`).
  * Created empty Python package folders with `__init__.py` markers for all academic, settings, todo, notes, review queue, and log modules.

* **What was implemented (Sprint 1 - Semester Module)**:
  * Created database models for `Semester` and `AttendanceSettings` with appropriate columns, constraints, unique keys, and cascading relationships.
  * Attendance criteria modes: `overall`, `subject`, `custom` (matching finalized database schema).
  * Autogenerated and executed Alembic database migrations to create matching PostgreSQL tables.
  * Developed the Repository Layer containing query methods (`SemesterRepository` including overlap detection, and a create-only stub for `AttendanceSettingsRepository`).
  * Implemented the Service Layer (`SemesterService`) handling date validations, unique checks, **semester date overlap rejection**, default attendance settings creation (criteria mode overall, goal sourced from `DEFAULT_ATTENDANCE_GOAL` constant), and marked TODO placeholders for future Activity Log integrations.
  * Designed RESTful API endpoints under `/api/v1/academic/semesters` supporting all standard CRUD actions wrapped in standard `ApiResponse` envelopes, with professional OpenAPI documentation (summary, description, response descriptions on every endpoint).
  * Configured Pytest testing suite (15 tests) using async isolation (connection-level transaction rollback per test with engine disposal to avoid event loop issues), covering repositories, services, overlap/adjacent validation, and API integration.

* **What was implemented (Sprint 2 - Subject Module)**:
  * Created database SQLAlchemy models for `Subject` and `NotesSubject` tables including unique constraints and cascade foreign keys.
  * Configured Alembic database migrations to create the corresponding database tables.
  * Built Pydantic validation schemas with custom regex for hex theme color codes and boundary verification for `attendance_goal` parameter.
  * Developed repository layers for both `subjects` and `notes_subjects` tables.
  * Implemented `SubjectService` containing all core business logic including validation of the parent semester existence, validation of name uniqueness per semester, automatic creation/rename sync of matching Notes Subject, and conditional deletion.
  * Designed 5 thin RESTful endpoints under `/api/v1/academic/subjects` with structured response schemas and complete OpenAPI descriptions.
  * Added 12 new async tests covering repository unique constraints, service auto-sync functionality, parameter boundaries, and integration routes.

* **What was implemented (Sprint 3 - Lecture Template Module)**:
  * Created database SQLAlchemy models for `LectureTemplate` (schedule unique constraint, day_of_week range 1-7 check, and start_time < end_time check), `LectureInstance` (with statuses and attendance enums), and `Holiday`.
  * Configured and applied Alembic database migration to generate the tables.
  * Designed Pydantic validation schemas for `LectureTemplate` with cross-field time range verification.
  * Created repository layers for `lecture_templates` and `lecture_instances`. Removed early-access `Holiday` repositories, services, and endpoints to keep Sprint boundaries clean.
  * Implemented `LectureTemplateService` encapsulating schedule uniqueness checks and **Semester Lecture Generation** logic.
  * Built automatic synchronization: changing scheduling attributes (`day_of_week`, `start_time`, `end_time`) automatically deletes all future scheduled unmarked instances and regenerates them. Changing non-scheduling attributes like `room` leaves instances intact.
  * Added **Timetable Overlap Validation** to block overlapping lecture templates inside the same semester and day.
  * Secured **Transaction Integrity** by executing updates and instance regenerations within single savepoint transactions (`begin_nested`), rolling back changes to both database rows and in-memory attributes if regeneration fails.
  * Registered REST API router `/api/v1/academic/lecture-templates` in `main.py` with 5 CRUD endpoints and detailed OpenAPI Swagger specifications.
  * Created 18 comprehensive tests in `tests/academic/test_lecture_templates.py` covering repository constraints, conflict check rules, boundary conditions, leap-year calculations, schedule changes vs. room changes, and transaction rollback.

* **What was implemented (Sprint 4 - Lecture Instance Module)**:
  * Created Pydantic validation and nested response schemas for `LectureInstance` and dynamic `AttendanceStatsResponse`.
  * Extended `LectureInstanceRepository` with eager-loaded relationships, filters, chronologically ordered sorting, and optimized `get_by_subject` history retrieval.
  * Implemented `LectureInstanceService` encapsulating runtime attendance calculations (total, present, absent, percentage, remaining, safe skip), enforcing business rules (rejecting markings on holiday/cancelled classes, allowing resets to unmarked), and bulk-marking updates with skipped count.
  * Registered REST API router `/api/v1/academic/lecture-instances` supporting list, today's schedule, details, single updates, bulk updates, and runtime subject/semester stats.
  * Created 19 comprehensive async tests covering constraints, validations, bulk updates, and calculations.

* **What was implemented (Sprint 5 - Attendance Settings Module)**:
  * Developed Pydantic schemas for `AttendanceSettingsUpdate`.
  * Expanded `AttendanceSettingsRepository` with `get_by_semester_id` and `update` persistence methods.
  * Implemented `AttendanceSettingsService` to validate settings updates (value range 1-100, checking mandatory goal for overall/subject mode, and support for clearing goal in custom mode).
  * Extracted calculations into a dedicated `AttendanceStatisticsService` to decouple database fetching from pure calculations and criteria-mode evaluations.
  * Configured criteria mode rules: `Overall Mode` computes overall statistics across all scheduled lectures; `Subject Mode` aggregates subject calculations using the semester's overall goal; `Custom Mode` aggregates subject calculations using each subject's individual target.
  * Registered REST API endpoints with path-parameter layout: `GET /api/v1/academic/attendance-settings/{semester_id}` and `PUT /api/v1/academic/attendance-settings/{semester_id}`.
  * Added 13 unit/integration tests in `tests/academic/test_attendance_settings.py` covering transition permutations, partial updates, edge cases (no subjects, no marked lectures), history immutability, and validation limits.

* **What was implemented (Sprint 6 - Holiday Module)**:
  * Integrated CRUD endpoints for holidays under `/api/v1/academic/holidays`.
  * Added validation rules: date must fall within semester bounds, date must be unique per semester.
  * Implemented Holiday Business Rule: holidays only modify scheduled lecture instances (never cancelled ones) and restore only previously holiday-marked instances back to scheduled status.
  * Ensured transaction safety: all holiday mutations run inside single nested savepoint transactions, rolling back all associated database states on failure.
  * Utilized database-level SQLAlchemy bulk updates to optimize performance.
  * Added a dedicated chronological `/calendar/{semester_id}` endpoint returning only dates and names for calendar rendering.
  * Integrated holiday status checking in `LectureTemplateService` during timetable template creation and regeneration.
  * Documented and enforced that holidays never modify Lecture Templates; they only modify Lecture Instances.

* **What was implemented (Sprint 7 - App Settings Module)**:
  * Designed singleton `app_settings` database schema containing global application preferences (Theme Mode, Finance Toggle, Digests, and Notes download directory path).
  * Enforced singleton database constraint `settings_id = 1` and restricted foreign key cascade deletion for active semesters.
  * Developed repository, service, and API controller layers exposing only GET settings and PUT settings operations.
  * Added custom validation and normalizations: case-insensitive theme parsing ('light', 'dark', 'system') and normalized OS file path strings.
  * Implemented active semester deletion protection (blocking deletion of semester currently selected as active via 409 conflict).
  * Automated seed generation in database migrations and clean test suite sessions.

* **What was implemented (Sprint 8 - Todo Module)**:
  * Documented and enforced that todos are completely independent of semesters, subjects, attendance, notes, and academic modules.
  * Designed `todos` database schema supporting priorities, statuses, and custom created_by sources.
  * Developed repository, service, and API controller layers with full CRUD operations.
  * Implemented default ordering for list_todos (pending first, priority High->Med->Low, earliest due date with nulls last, newest created_at first).
  * Added query parameter case-insensitive title search (`q`) filtered inside the repository.
  * Enforced due date year validation to fall within the range [2000, 2100].
  * Added dynamic response model field `days_overdue` and `is_overdue` (computed at runtime, not persisted in the database).
  * Integrated status state-transitions where completing/reverting a task automatically manages `completed_at` timestamps.

* **What was implemented (Sprint 9 - Notes Repository Module)**:
  * Designed the database schemas for `notes_sections` and `notes_resources` tables with cascade deletion.
  * Configured `uploaded_via` PostgreSQL enum supporting `app`, `whatsapp`, `ocr`, `review_queue`, and `api`.
  * Implemented read-only notes subjects endpoints synchronized automatically from the academic subject module (the subject module remains the single source of truth).
  * Exposed complete CRUD endpoints for Notes Sections and Notes Resources with Pydantic validators checking `file_size_bytes > 0` and `mime_type` against an allow-list of supported document/image types.
  * Derived `file_extension` dynamically from `file_name` to prevent inconsistent metadata.
  * Added hierarchical search `GET /resources` with case-insensitive search (`q`) and optional `semester_id`, ordered by Semester -> Notes Subject -> Section -> Resource Name.
  * Implemented complete alphabetical hierarchy tree retrieval `GET /hierarchy/{semester_id}`.
  * Added future TODO integration placeholders for Activity Logs (Sprint 11) and Storage Deletion (Sprint 12).
  * Optimized database query performance by adding database indexes on `notes_sections.notes_subject_id` and `notes_resources.section_id`, `notes_resources.resource_name`, and `notes_resources.file_name`.
  * Documented future physical storage upload logic checks in `create_resource` and deletion flows in `delete_resource` using structured TODO comments.

* **What was implemented (Sprint 10 - Review Queue Module)**:
  - Created review queue tables and enums in SQL database.
  - Implemented human-in-the-loop review queue architecture resolving ambiguous data updates via service resolvers.

* **What was implemented (Sprint 11 - Activity Logs Module)**:
  - Created central activity logger helper, database schema, and REST API search.
  - Hooked all core business services to record user/admin activities.

* **What was implemented (Sprint 12 - Semester Module Integration)**:
  - Set up Dio client, base constants, and ApiException interceptors on Flutter frontend.
  - Bootstrapped, fetched, and selected academic semesters from local uvicorn host.
  - Completed active semester selector screen and new semester creation form dialog.

* **What was implemented (Sprint 12.5 - MVP Backend Audit & Maintenance)**:
  - Conducted Audit 1 (Architecture Audit) scoring a **94/100** health score. Standardized all backend database models, repositories, services, and tests to use timezone-aware UTC datetime. See detailed report: [docs/audit/audit_01_architecture.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_01_architecture.md).
  - Conducted Audit 2 (Database Audit) scoring a **98/100** post-remediation health score. Implemented database unique constraint on `(lecture_template_id, lecture_date)` and check constraint `start_date < end_date` on `semesters`. Added indexes on holidays and todos. See detailed report: [docs/audit/audit_02_database.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_02_database.md).
  - Conducted Audit 3 (Business Logic Audit) scoring a **98/100** post-remediation health score. Remediated the lecture template update rescheduling conflict and added time inversion checks. Optimized N+1 queries in statistics and semester updates using batch-fetching. See detailed report: [docs/audit/audit_03_business_logic.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_03_business_logic.md).
  - Conducted Audit 4 (API Audit) scoring a **100/100** post-remediation health score. Standardized Activity Logs responses using `ApiResponse` and added optional pagination (`limit`/`offset`) to Todos and Lecture Instances. See detailed report: [docs/audit/audit_04_api.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_04_api.md).
  - Conducted Audit 5 (Performance Audit) scoring a **100/100** post-remediation health score. Added standalone index on `lecture_instances(lecture_date)`, resolved Activity Logs and Review Queue N+1 query patterns using polymorphic batch loading, and consolidated holiday updates. See detailed report: [docs/audit/audit_05_performance.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_05_performance.md).
  - Conducted Audit 6 (Security Audit) scoring a **100/100** post-remediation health score. Remediated insecure wildcard CORS middleware configurations, added future-compatible JWT settings, added backend `.gitignore` rules, and introduced HTTP bearer authentication dependency stubs. See detailed report: [docs/audit/audit_06_security.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_06_security.md).
  - Conducted Audit 7 (Flutter Integration Audit) scoring a **100/100** post-remediation health score. Cleaned up global AppState, removing dead mock methods and state properties, keeping only active fields. Verified repository, DTO mapping, and endpoint consistency. See detailed report: [docs/audit/audit_07_flutter_integration.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_07_flutter_integration.md).
  - Conducted Audit 8 (Code Quality Audit) scoring a **100/100** post-remediation health score. Resolved stale TODOs, implemented settings update activity logging, updated note upload sprint labels, and added context mounted guards in Flutter. See detailed report: [docs/audit/audit_08_code_quality.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_08_code_quality.md).
  - Conducted Audit 9 (Testing Quality Audit) scoring a **100/100** post-remediation health score. Resolved FastAPI/Starlette deprecation warnings, fixed SQLAlchemy connection deassociation warnings, and added boundary tests for leap-year holidays and whitespace searches. See detailed report: [docs/audit/audit_09_testing.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_09_testing.md).
  - Conducted Audit 10 (Production Readiness Audit) scoring a **100/100** post-remediation health score. Configured database connection pooling, dynamically disabled Swagger docs in production environments, overhauled the health check route to verify active database connections, and created a `Dockerfile` and `docker-compose.yaml` to run uvicorn backend and PostgreSQL services locally. See detailed report: [docs/audit/audit_10_production_readiness.md](file:///home/vismay.shah/VISMAY/student_buddy/docs/audit/audit_10_production_readiness.md).
  - Verified 174/174 backend automated tests pass successfully.

* **What was implemented (Sprint 13 - Authentication)**:
  - Integrated Supabase Authentication with the FastAPI backend.
  - Implemented JWT token signature verification using `PyJWT`.
  - Created a decoupled application-level `users` database table to separate identity from profiles/settings.
  - Added workspace initialization endpoint `POST /api/v1/users/me/initialize` to provision default settings and profiles idempotently.
  - Enforced strict repository-level constructor scoping via `user_id` injection to guarantee multi-tenant data isolation.
  - Refactored test configurations to support mocked token validation overrides and automatic seeding/scoping of default test user context.
  - Verified 175/175 backend automated tests pass successfully.

* **What was implemented (Sprint 14A - SQLite Offline Foundation)**:
  - Designed local SQLite schemas mirroring the authoritative PostgreSQL schemas with FOREIGN KEY constraints.
  - Developed user-scoped local databases (`student_buddy_${userId}.db`) to ensure perfect local isolation.
  - Refactored all 11 core data repositories to abstract interfaces with factory constructors returning concrete SQLite implementations.
  - Replicated business logic locally, including cascade deletes, transaction safety, and automatic activity logging.
  - Implemented `BootstrapService` for transactional, atomic seeding of local databases from the backend `/users/me/bootstrap` snapshot.
  - Integrated database checks and seeding into the splash screen (with custom retry and sign-out UI) and login/signup flows.
  - Hooked connection closing to settings logouts and 401 token expiry handlers.
  - Added unit testing for UUID generation and verified zero compiler/static analysis warnings.

* **What was implemented (Sprint 14B - SQLite Synchronization Engine)**:
  - Developed `SyncService` as a centralized sync coordinator with concurrency guarding (Sync Lock).
  - Designed the queue coalescing algorithm (Rules 1-4) maintaining chronological sorting of operations based on original earliest event ID.
  - Implemented the Upload pipeline iterating over the coalesced queue and calling REST endpoints sequentially.
  - Implemented the Download pipeline fetching remote updates via `GET /users/me/bootstrap?since=...`.
  - Enforced Last Write Wins (LWW) conflict resolution logic using local vs remote `updated_at` checks.
  - Built lecture instance duplicate reconciliation logic mapped to unique `(lecture_template_id, lecture_date)` keys.
  - Added automated connectivity monitoring via `connectivity_plus` to auto-trigger synchronization on network reconnect.
  - Designed and integrated the Synchronization settings card UI displaying real-time sync state, timestamps, and pending count, alongside a manual "Sync Now" button.
  - Developed an automated unit testing suite for the coalescing and sorting engine and verified all test assertions pass.
  - Implemented **Sync Protocol Versioning**: Introduced central version constants in the backend (`SYNC_PROTOCOL_VERSION = 1`) and client (`minSupportedSyncVersion = 1`, `maxSupportedSyncVersion = 1`), isolated bootstrap response schema (`backend/app/schemas/users/bootstrap.py`), validated the protocol range in both `BootstrapService` and `SyncService` before SQLite writes, and added professional mismatch warnings in the UI.

* **What was implemented (Sprint 14C - State Management Modernization — Riverpod Integration)**:
  - Migrated the remaining persistent modules (Todo, Timetable, Attendance, Notes, Review Queue, Settings, Semester Selection, and root StudentBuddyApp) to Riverpod CQRS architecture.
  - Fully eliminated `AppState.instance` references from the active codebase.
  - Implemented read providers and write action providers to separate query logic from mutations.

* **What was implemented (Synchronization & Semester Stabilization)**:
  - Implemented cascading updates in the SQLite repository for semester updates, automatically pruning out-of-bounds scheduled lecture instances and generating missing ones based on existing templates.
  - Refactored `SemesterActions` provider to trigger explicit Riverpod downstream invalidation (for attendance settings, timetable schedules, stats, and date-specific lecture lists) to ensure immediate UI updates upon semester dates modification.
  - Hardened `SyncService` to transition the sync status state to `SyncStatus.error` if any operations remain pending (e.g. backoff retry delays) after a sync attempt, showing correct error messages in the offline sync settings.
  - Standardized Activity Logs synchronization, ensuring remote backend logs are merged down during bootstrap and local responsiveness placeholder logs are cleanly deduplicated based on matching entity details.
  - Fixed activity log user ID mapping issues on the backend by explicitly passing `user_id` inside services and fallback retrieval from `request_user_id` context.
  - Added unique `heroTag` specifications to FABs in Notes, Timetable, and Todo screens to prevent duplicate Hero tag errors on view transitions.

* **What was intentionally NOT implemented (postponed)**:
  * WhatsApp bot webhook and Meta Cloud API integration (postponed to Sprint 15)
  * AI engine and OCR timetable parser (postponed to Sprint 16)

---

## 10. Future Development Roadmap

The backend architecture is now considered feature-complete for MVP Version 1. Future work will primarily extend the platform rather than redesign it. The implementation order of the remaining project has been finalized as:

### Remaining Phases
1. **Deployment & Production Validation** (Audit 11 Implementation, Railway deployment, Supabase production database, Flutter production configuration, Production verification, and full Smoke Testing). Only after this is complete and verified will Sprint 15 begin.
2. **WhatsApp Integration** (Sprint 15)
3. **AI Integration** (Sprint 16)
4. **Finance Module** (Sprint 17)
5. **Final Release & Publishing** (Play Store Release)

### Detailed Sprints & Milestones
* **Sprint 0**: Backend Foundation (Completed)
* **Sprint 1**: Semester Module (Completed)
* **Sprint 2**: Subject Module (Completed)
* **Sprint 3**: Lecture Template Module (Completed)
* **Sprint 4**: Lecture Instance Module (Completed)
* **Sprint 5**: Attendance Settings Module (Completed)
* **Sprint 6**: Holiday Module (Completed)
* **Sprint 7**: App Settings Module (Completed)
* **Sprint 8**: Todo Module (Completed)
* **Sprint 9**: Notes Repository Module (Completed)
* **Sprint 10**: Review Queue Module (Completed + Refined)
* **Sprint 11**: Activity Logs Module (Completed)
* **Sprint 12**: Backend Verification & Flutter API Integration (MVP Mode) (Completed)
* **Sprint 12.5**: MVP Backend Audit & Maintenance (Completed)
* **Sprint 13**: Authentication (Completed)
* **Sprint 14A**: SQLite Offline Foundation (Completed)
* **Sprint 14B**: SQLite Synchronization Engine (Completed)
* **Sprint 14C**: State Management Modernization (Riverpod Integration) (Completed)
* **Audit 11 — Deployment & Operations**: Audit and Infrastructure Remediation (Active)
* **Production Deployment**: Deploy PostgreSQL on Supabase, FastAPI on Railway, configure Flutter production variables, and complete comprehensive Smoke Testing.
* **Sprint 15**: WhatsApp Integration
* **Sprint 16**: AI Integration
* **Sprint 17**: Finance Module (Frozen until core is stable)

---

## 11. Important Notes For Future AI Sessions

* **Never remove functionality**: Do not delete screens, features, or modules unless the user explicitly requests it.
* **Never simplify the project by removing modules**: The balance between Academic and Finance must remain intact, although Finance is officially frozen and disabled by default for current phases.
* **Never merge Finance and Academic logic internally**: Keep finance accounts, transactions, and categories isolated from academic classes, assignments, and attendance logs.
* **Finance must remain optional**: Ensure settings toggles completely hide or show finance metrics dynamically throughout the UI without throwing null errors.
* **Always preserve scalability over aesthetics**: Do not let design choices corrupt structured data architectures.
* **Always prioritize reducing student friction**: When creating user flows or chatbot commands, prioritize the method that takes the fewest clicks or keystrokes.

---

## 12. State Management Strategy & Guidelines

* **Core Decision**: Riverpod is the final, official state management solution for Student Buddy.
* **Separation of Concerns (CQRS)**: All state management is split between Read-Only state providers (e.g. `AsyncNotifierProvider`, `FutureProvider`) and Action/Command providers (handling mutations, local database enqueueing, and triggering backend synchronization).
* **Migration Status (Sprint 14C — Complete)**: All persistent modules have been fully migrated to clean Riverpod structures:
  - **Todo**: `todosProvider` (Read) + `todoActionsProvider` (Action)
  - **Timetable**: `allLectureTemplatesProvider` / `todayLecturesProvider` (Read) + `timetableActionsProvider` (Action)
  - **Attendance**: `attendanceSettingsProvider` / `dateLecturesProvider` / `holidaysProvider` (Read) + `attendanceActionsProvider` (Action)
  - **Notes**: `notesHierarchyProvider` / `notesSubjectsProvider` / `notesSectionsProvider` (Read) + `notesActionsProvider` (Action)
  - **Review Queue**: `pendingReviewQueueProvider` (Read) + `reviewQueueActionsProvider` (Action)
  - **Settings & Semester**: `appSettingsProvider` / `themeProvider` / `semestersProvider` / `activeSemesterProvider` (Read) + `semesterActionsProvider` (Action)
  - **Finance**: `financeSettingsProvider` (Read)
  - **Sync**: `syncStateProvider` (Read)
* **AppState Status**: The legacy `AppState` singleton (`lib/core/utils/app_state.dart`) is no longer referenced by any active code. It is dead code and safe to delete.
* **ValueNotifier Restrictions**: Standard `ValueNotifier` is fully eliminated from the UI layer. All state queries and operations watch Riverpod providers to enable reactive, reload-free UI flows.
* **Provider Files**: All providers reside in `lib/core/providers/` following the naming convention `{module}_provider.dart`.

---

## 13. MVP Implementation Rule

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

## 14. Implementation Priority Rule

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


