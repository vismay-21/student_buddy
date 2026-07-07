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
* **Authentication**: Supabase Auth (Phone/WhatsApp OTP authentication)
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

*Recommended folder structure (may evolve in future phases).*

```text
student_buddy/
├── android/
├── ios/
├── windows/
├── macos/
├── linux/
├── web/
├── backend/                  # FastAPI backend module
│   ├── app/                  # FastAPI application package
│   │   ├── api/              # API Routers for health check, settings, academic, notes, and todos modules
│   │   │   ├── v1/
│   │   │   │   ├── academic/
│   │   │   │   │   ├── semesters.py            # Semester REST endpoints
│   │   │   │   │   ├── subjects.py             # Subject REST endpoints
│   │   │   │   │   ├── lecture_templates.py    # Lecture Template REST endpoints
│   │   │   │   │   ├── lecture_instances.py    # Lecture Instance REST endpoints
│   │   │   │   │   ├── attendance_settings.py  # Attendance Settings REST endpoints
│   │   │   │   │   └── holidays.py             # Holiday REST endpoints
│   │   │   │   │   └── __init__.py
│   │   │   │   ├── settings/
│   │   │   │   │   ├── app_settings.py         # App Settings REST endpoints
│   │   │   │   │   └── __init__.py
│   │   │   │   ├── todo/
│   │   │   │   │   ├── todos.py                # Todo REST endpoints
│   │   │   │   │   └── __init__.py
│   │   │   │   ├── notes/
│   │   │   │   │   ├── notes.py                # Notes REST endpoints
│   │   │   │   │   └── __init__.py
│   │   │   │   ├── activity_logs/
│   │   │   │   │   └── __init__.py             # Activity logs endpoint placeholders
│   │   │   │   ├── review_queue/
│   │   │   │   │   ├── review_queue.py         # Review queue REST endpoints
│   │   │   │   │   └── __init__.py
│   │   │   │   ├── health.py                   # Health check endpoint
│   │   │   │   └── __init__.py
│   │   │   └── __init__.py
│   │   ├── core/             # Configuration, database connection, exception handling, and logging
│   │   │   ├── config.py                       # Global settings loader
│   │   │   ├── constants.py                    # Static global constants
│   │   │   ├── database.py                     # Database connection pool setup
│   │   │   ├── exceptions.py                   # Custom exceptions and handlers
│   │   │   ├── logging.py                      # Structured logging configuration
│   │   │   ├── security.py                     # Password/token security helpers
│   │   │   └── __init__.py
│   │   ├── dependencies/     # FastAPI Dependency injection providers
│   │   │   ├── database.py                     # Database session injector
│   │   │   └── __init__.py
│   │   ├── models/           # Database SQLAlchemy models
│   │   │   ├── academic/
│   │   │   │   ├── semester.py                 # Semester model
│   │   │   │   ├── subject.py                  # Subject model
│   │   │   │   ├── lecture_template.py         # LectureTemplate model
│   │   │   │   ├── lecture_instance.py         # LectureInstance model
│   │   │   │   ├── attendance_settings.py      # AttendanceSettings model
│   │   │   │   ├── holiday.py                  # Holiday model
│   │   │   │   └── __init__.py
│   │   │   ├── settings/
│   │   │   │   ├── app_settings.py             # AppSettings singleton model
│   │   │   │   └── __init__.py
│   │   │   ├── todo/
│   │   │   │   ├── todo.py                     # Todo model
│   │   │   │   └── __init__.py
│   │   │   ├── notes/
│   │   │   │   ├── notes_subject.py            # NotesSubject model
│   │   │   │   ├── notes_section.py            # NotesSection model
│   │   │   │   ├── notes_resource.py           # NotesResource model
│   │   │   │   └── __init__.py
│   │   │   ├── activity_logs/
│   │   │   │   └── __init__.py                 # Activity logs models placeholder
│   │   │   ├── review_queue/
│   │   │   │   ├── review_queue.py             # Review queue model
│   │   │   │   └── __init__.py
│   │   │   └── __init__.py
│   │   ├── schemas/          # Pydantic validation models
│   │   │   ├── academic/
│   │   │   │   ├── semester.py                 # Semester validation schemas
│   │   │   │   ├── subject.py                  # Subject validation schemas
│   │   │   │   ├── lecture_template.py         # LectureTemplate validation schemas
│   │   │   │   ├── lecture_instance.py         # LectureInstance validation schemas
│   │   │   │   ├── attendance_settings.py      # AttendanceSettings validation schemas
│   │   │   │   ├── holiday.py                  # Holiday validation schemas
│   │   │   │   └── __init__.py
│   │   │   ├── settings/
│   │   │   │   ├── app_settings.py             # AppSettings validation schemas
│   │   │   │   └── __init__.py
│   │   │   ├── todo/
│   │   │   │   ├── todo.py                     # Todo validation schemas
│   │   │   │   └── __init__.py
│   │   │   ├── notes/
│   │   │   │   ├── notes_subject.py            # NotesSubject validation schemas
│   │   │   │   ├── notes_section.py            # NotesSection validation schemas
│   │   │   │   ├── notes_resource.py           # NotesResource validation schemas
│   │   │   │   └── __init__.py
│   │   │   ├── activity_logs/
│   │   │   │   └── __init__.py                 # Activity logs schemas placeholder
│   │   │   ├── review_queue/
│   │   │   │   ├── review_queue.py             # Review queue validation schemas
│   │   │   │   └── __init__.py
│   │   │   ├── common.py                       # Global standard API response schemas
│   │   │   └── __init__.py
│   │   ├── repositories/     # Database queries and operations (CRUD)
│   │   │   ├── academic/
│   │   │   │   ├── semester.py                 # Semester DB query operations
│   │   │   │   ├── subject.py                  # Subject DB query operations
│   │   │   │   ├── lecture_template.py         # LectureTemplate DB query operations
│   │   │   │   ├── lecture_instance.py         # LectureInstance DB query operations
│   │   │   │   ├── attendance_settings.py      # AttendanceSettings DB query operations
│   │   │   │   ├── holiday.py                  # Holiday DB query operations
│   │   │   │   └── __init__.py
│   │   │   ├── settings/
│   │   │   │   ├── app_settings.py             # AppSettings DB query operations
│   │   │   │   └── __init__.py
│   │   │   ├── todo/
│   │   │   │   ├── todo.py                     # Todo DB query operations
│   │   │   │   └── __init__.py
│   │   │   ├── notes/
│   │   │   │   ├── notes_subject.py            # NotesSubject DB query operations
│   │   │   │   ├── notes_section.py            # NotesSection DB query operations
│   │   │   │   ├── notes_resource.py           # NotesResource DB query operations
│   │   │   │   └── __init__.py
│   │   │   ├── activity_logs/
│   │   │   │   └── __init__.py                 # Activity logs repository placeholder
│   │   │   ├── review_queue/
│   │   │   │   ├── review_queue.py             # Review queue DB query operations
│   │   │   │   └── __init__.py
│   │   │   └── __init__.py
│   │   ├── services/         # Business logic and transaction rules orchestrations
│   │   │   ├── academic/
│   │   │   │   ├── semester.py                 # Semester business logic
│   │   │   │   ├── subject.py                  # Subject business logic & notes sync
│   │   │   │   ├── lecture_template.py         # LectureTemplate business logic
│   │   │   │   ├── lecture_instance.py         # LectureInstance business logic
│   │   │   │   ├── attendance_settings.py      # AttendanceSettings business logic
│   │   │   │   ├── attendance_statistics.py    # Ratios and safe skip logic
│   │   │   │   ├── holiday.py                  # Holiday transactional updates
│   │   │   │   └── __init__.py
│   │   │   ├── settings/
│   │   │   │   ├── app_settings.py             # AppSettings business logic
│   │   │   │   └── __init__.py
│   │   │   ├── todo/
│   │   │   │   ├── todo.py                     # Todo business logic and status state transitions
│   │   │   │   └── __init__.py
│   │   │   ├── notes/
│   │   │   │   ├── notes.py                    # Notes service orchestrator
│   │   │   │   └── __init__.py
│   │   │   ├── activity_logs/
│   │   │   │   └── __init__.py                 # Activity logs service placeholder
│   │   │   ├── review_queue/
│   │   │   │   ├── review_queue.py             # Review queue business logic & dispatcher
│   │   │   │   ├── resolvers/                  # Entity-specific resolver classes
│   │   │   │   │   ├── base.py                 # BaseResolver interface
│   │   │   │   │   ├── todo.py                 # TodoResolver - applies TodoUpdate changes
│   │   │   │   │   ├── lecture_instance.py     # LectureInstanceResolver - applies attendance/status changes
│   │   │   │   │   ├── finance.py              # FinanceResolver - frozen no-op placeholder
│   │   │   │   │   ├── registry.py             # RESOLVERS map: EntityType -> resolver class
│   │   │   │   │   └── __init__.py
│   │   │   │   └── __init__.py
│   │   │   └── __init__.py
│   │   ├── utils/            # Helper utilities and shared formulas
│   │   │   ├── attendance_calculator.py        # Core attendance mathematical formulas
│   │   │   └── __init__.py
│   │   ├── main.py           # FastAPI entrypoint, router registers, exception handler registers
│   │   └── __init__.py
│   ├── alembic/              # Alembic database migration tool configurations
│   │   ├── versions/         # Alembic database migration version scripts
│   │   │   ├── 192b4793464e_create_semester_and_attendance_settings_.py
│   │   │   ├── 1a9ff58b8423_create_subjects_and_notes_subjects_.py
│   │   │   ├── 2db1602c28b4_create_lecture_template_instance_.py
│   │   │   ├── ca2a9e095c10_create_app_settings_table.py
│   │   │   ├── 6e718cd5065a_create_todos_table.py
│   │   │   └── e4ffe7e8e71b_create_notes_tables.py
│   │   ├── env.py            # Migration target registration env
│   │   └── script.py.mako    # Alembic revision template script
│   ├── tests/                # Unit and integration test suites
│   │   ├── academic/
│   │   │   ├── test_semesters.py               # Semester test cases
│   │   │   ├── test_subjects.py                # Subject CRUD and notes sync test cases
│   │   │   ├── test_lecture_templates.py       # LectureTemplate validation test cases
│   │   │   ├── test_lecture_instances.py       # LectureInstance CRUD test cases
│   │   │   ├── test_attendance_settings.py     # AttendanceSettings constraints tests
│   │   │   └── test_holidays.py                # Holiday transaction rollback tests
│   │   ├── settings/
│   │   │   └── test_app_settings.py            # AppSettings theme/path normalization tests
│   │   ├── todo/
│   │   │   └── test_todos.py                   # Todo status-transition & sorting tests
│   │   ├── notes/
│   │   │   └── test_notes.py                   # Notes CRUD, validators, hierarchy and search tests
│   │   ├── test_health.py                      # Health endpoint verification
│   │   ├── conftest.py                         # Test database session fixtures and cleanup setups
│   │   └── __init__.py
│   ├── requirements.txt      # Python dependencies list
│   ├── README.md             # Development documentation setup
│   └── .env.example          # Environment variables template

├── docs/                     # Documentation files
│   ├── database/             # Database design documents
│   │   ├── 04_entity_relationship_diagram.md
│   │   ├── 1_database_schema.md
│   │   ├── 2_database_business_flow.md
│   │   └── 3_database_sync_strategy.md
│   ├── STUDENT BUDDY DEVELOPMENT ROADMAP DCOUMENT DRD.md
│   ├── STUDENT BUDDY MASTER REQUIREMENTS DOCUMENT MRD.txt
│   ├── backend_development_plan.md
│   ├── context.md            # This file (Project Memory)
│   └── history.md            # Project decisions & implementation history log
├── lib/                      # Flutter source directory
│   ├── core/
│   │   ├── models/
│   │   │   └── subject_template.dart   # Template model for pre-filling recurring classes
│   │   ├── theme/
│   │   │   └── app_theme.dart          # Light and Dark theme specifications
│   │   ├── utils/
│   │   │   ├── app_state.dart
│   │   │   └── dummy_data.dart
│   │   ├── network/                    # API Networking Layer
│   │   │   ├── api_constants.dart      # Base URLs and API route endpoints
│   │   │   ├── dio_client.dart         # Singleton Dio client instance
│   │   │   └── interceptors.dart       # Error interceptors and ApiException parsing
│   │   └── widgets/
│   │       ├── app_snackbar.dart                  # Premium global floating SnackBar notification helper
│   │       ├── expandable_section.dart            # Reusable collapsible dashboard section widget
│   │       └── attendance_ring_label.dart         # Custom percentage fraction indicator widget
│   ├── screens/
│   │   ├── attendance/
│   │   │   ├── widgets/
│   │   │   │   ├── attendance_calendar_legend.dart    # Colored dot visual indicator key for the monthly calendar view
│   │   │   │   ├── attendance_analytics_card.dart     # Consolidated card displaying monthly day summary and lecture statistics
│   │   │   │   ├── attendance_overview_card.dart      # Dashboard header element showing general attendance percentages
│   │   │   │   └── lecture_card.dart                  # Reusable unified card displaying timetable layout and attendance metrics
│   │   │   ├── attendance_screen.dart        # Container hosting sub-navigation tabs (History, Subjects, Settings)
│   │   │   ├── attendance_settings_tab.dart  # Preferences pane configuring criteria modes, percentages, semester ranges, and holidays
│   │   │   ├── day_history_screen.dart       # Dedicated logging details screen for a specific selected date
│   │   │   ├── history_tab.dart              # Month-view pageable calendar covering past school days
│   │   │   ├── subject_history_screen.dart   # Dedicated history log and action list for a specific academic course
│   │   │   └── subjects_tab.dart             # Analytics dashboard list showing targets, rates, and recommendations
│   │   ├── auth/
│   │   │   ├── login_screen.dart             # Authentication gateway using phone/WhatsApp input
│   │   │   └── otp_screen.dart               # Verification page to confirm the user OTP code
│   │   ├── finance/
│   │   │   └── finance_screen.dart           # Wallet manager showing card layouts, transaction records, and budgets
│   │   ├── navigation_shell.dart             # Core layout scaffolding handling app navigation, tab routing, and top-right header actions
│   │   ├── notes/
│   │   │   ├── add_resource_screen.dart      # Dedicated screen to add/edit resources with dynamic subjects, units, types, and placeholders
│   │   │   ├── notes_config.dart             # Storage config and architecture placeholders detailing Supabase/local download caches
│   │   │   ├── notes_screen.dart             # Class materials organizer grouping resources by Semester, Subject, and Unit with a FAB
│   │   │   └── resource_card.dart            # Custom component displaying a resource item with download status and edit buttons
│   │   ├── overview/
│   │   │   └── overview_screen.dart          # Main dashboard summary showing lectures, attendance warnings, tasks, and financial updates
│   │   ├── review_queue/
│   │   │   ├── review_queue_screen.dart      # Interface resolving OCR timetable parser conflicts and low-confidence logs
│   │   │   └── review_queue_edit_screen.dart # Dedicated full-screen form-based editor for resolving low confidence items
│   │   ├── settings/
│   │   │   ├── semester_selection_screen.dart # Preference selector updating the active school semester
│   │   │   └── settings_screen.dart          # Global toggles for theme selector, active modules, and notification settings
│   │   ├── splash/
│   │   │   └── splash_screen.dart            # Initial loading screen verifying configuration and theme choices
│   │   ├── timetable/
│   │   │   ├── add_class_screen.dart         # Dedicated screen to add class schedules with templates and clock pickers
│   │   │   └── timetable_screen.dart         # Interactive weekly calendar detailing daily classroom routines
│   │   └── todo/
│   │       ├── add_todo_screen.dart          # Screen for creating new tasks with title, due dates, priority, and category
│   │       └── todo_screen.dart              # Screen listing, sorting, and managing due tasks and reminders
│   ├── data/                                 # Clean Architecture Data Access Layer
│   │   ├── api/
│   │   │   └── semester_api.dart             # API wrapper for Semester endpoints
│   │   ├── dto/
│   │   │   └── semester/
│   │   │       └── semester_dto.dart         # DTO serialization and deserialization classes
│   │   └── repositories/
│   │       └── semester_repository.dart      # Clean interface mapping endpoints to state
│   └── main.dart
├── pubspec.yaml
└── README.md
```

---

## 9. Current Backend Status

We are currently preparing for **Authentication (Sprint 13)**, having completed the **Business Logic & Runtime Calculation Audit (Sprint 12.5)**.


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
    * Renamed settings from "Target" to "Criteria", implemented 3 criteria modes (Overall, Subject-Wise, Subject-Wise Custom) with a per-subject configuration dialog, and added Default Days Off chips.
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
    * Reordered `HistoryTab` layout, merging the Calendar Month View and the Color Legend into the same outer card container (height: 395, page change animation: 500ms), separated by a Divider.
    * Implemented semester-wide stats aggregation and custom stats popup dialog showing detailed day and lecture statistics when tapping the Overall Attendance Card.
    * Redesigned `AppSnackbar` to be extremely lightweight: reduced heights, padding, font sizes, corner radius, and lowered floating margins (bottom: 8 when nav bar is present, 16 when not) to stay cleanly above navigation.
    * Standardized the bottom offset of the FloatingActionButton on the Timetable screen (padding: 60) to align with the main To Do FAB spacing.
    * Tuned main dashboard spacing (reduced heights of vertical separators to 16).

* **What was intentionally NOT implemented (postponed/frozen)**:
  * **Finance Module (FROZEN)**: All Finance module development is officially frozen. It is now disabled by default on clean installs, and the toggle state is persisted via `SharedPreferences`.
  * Riverpod state management implementation (postponed to Sprint 14)

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
  * Automated seed generation for default configuration in database migrations and clean test suite sessions.

* **What was implemented (Sprint 8 - Todo Module)**:
  * Documented and enforced that todos are completely independent of semesters, subjects, attendance, notes, and academic modules.
  * Designed `todos` database schema supporting categories, priorities, statuses, and custom created_by sources.
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

* **What was implemented (Sprint 12.5 - Business Logic & Runtime Calculation Audit)**:
  - Audited and verified backend services (Academic, Todo, Notes, Review Queue, Activity Logs) for schema consistency and non-persistent derived data philosophy (e.g. dynamic calculations of attendance rates, overdue counts, entity summaries).
  - Validated business logic boundaries (e.g., blocking marking holidays or cancelled classes as present/absent) and transactional integrity (nested savepoints and rollback rules).
  - Verified frontend integration state, confirming full replacement of static mockup/dummy data with live database repository calls.
  - Ensured 100% backend unit and integration test pass rate (160 tests).

* **What was intentionally NOT implemented (postponed)**:
  * Authentication & Supabase integration (postponed to Sprint 13)
  * SQLite synchronization engine (postponed to Sprint 14)
  * WhatsApp bot webhook and Meta Cloud API integration (postponed to Sprint 15)
  * AI engine and OCR timetable parser (postponed to Sprint 16)

---

## 10. Future Development Roadmap

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
* **Sprint 12.5**: Business Logic & Runtime Calculation Audit (Completed)
* **Sprint 13**: Authentication
* **Sprint 14**: SQLite Synchronization Engine
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
* **Phase 1 Boundaries**: Riverpod is intentionally postponed in Phase 1 to maintain focus on standard Flutter UI skeletal layouts.
* **State Isolation**: State must be kept local to individual screens (e.g. within stateful wrapper pages) to avoid nested global `ValueNotifier` trees.
* **ValueNotifier Restrictions**: Standard `ValueNotifier` can only be used for simple, isolated UI events. All core calculations, models, and operations must not depend on `ValueNotifier` chains.
* **Riverpod Migration Preparation**: State logic (such as attendance calculations, holiday maps) should be organized into notifier-like structures inside the screen states, facilitating clean extraction to `StateNotifier` or `Notifier` classes in Phase 2+.

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


