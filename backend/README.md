# Student Buddy Backend

Sleek, production-ready, async FastAPI backend for Student Buddy.

## Tech Stack
- **Framework:** FastAPI
- **ORM:** SQLAlchemy 2.x (Async)
- **Database:** PostgreSQL (Supabase / local)
- **Migrations:** Alembic
- **Validation:** Pydantic v2
- **Testing:** pytest + pytest-asyncio

## Getting Started

### Prerequisites
- Python 3.12+
- PostgreSQL database

### Installation

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create a virtual environment and activate it:
   ```bash# Student Buddy - End of Phase Context Preservation

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
├── backend/                  # FastAPI backend skeleton
│   ├── app/                  # FastAPI application package
│   │   ├── api/              # Routers (health check, and placeholders)
│   │   ├── core/             # Configuration, database, exception handler, logging
│   │   ├── dependencies/     # Dependency injection providers
│   │   ├── models/           # Database SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas (common responses)
│   │   ├── repositories/     # Database CRUD repositories
│   │   ├── services/         # Business logic services
│   │   ├── utils/            # Helper utilities
│   │   └── main.py           # Application entry point
│   ├── alembic/              # Database migration tool configuration
│   ├── tests/                # Test package (conftest, health test)
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
│   └── main.dart
├── pubspec.yaml
└── README.md
```

---

## 9. Current Development Phase

We are currently developing the **FastAPI Backend (Sprint 0 — Backend Foundation)**.

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

### 9.2. Backend (Sprint 0 — Backend Foundation)

* **What was implemented**:
  * Established the complete FastAPI project skeleton with folder structure matching the architectural specification.
  * Configured Pydantic settings loading from environmental files (`.env`), async database engine, and session maker in SQLAlchemy 2.x.
  * Structured unified python console logging format and custom application exception hierarchy with global FastAPI interceptors.
  * Designed standard API response formats (`ApiResponse` and `ApiErrorResponse`) and registered a testable health check router (`/api/v1/health`).
  * Created empty Python package folders with `__init__.py` markers for all academic, settings, todo, notes, review queue, and log modules.

* **What was intentionally NOT implemented (postponed)**:
  * Database Models, Repositories, Services, and REST CRUD API endpoints (begins in Sprint 1 — Semester Module)
  * Supabase integration & authentication APIs (postponed to Sprint 12)
  * SQLite synchronization engine (postponed to Sprint 13)
  * WhatsApp bot webhook and Meta Cloud API integration (postponed to Sprint 15)
  * AI engine and OCR timetable parser (postponed to Sprint 16)

---

## 10. Future Development Roadmap

* **Sprint 0**: Backend Foundation (Completed)
* **Sprint 1**: Semester Module
* **Sprint 2**: Subject Module
* **Sprint 3**: Lecture Template Module
* **Sprint 4**: Lecture Instance Module
* **Sprint 5**: Attendance Settings Module
* **Sprint 6**: Holiday Module
* **Sprint 7**: App Settings Module
* **Sprint 8**: Todo Module
* **Sprint 9**: Notes Repository Module
* **Sprint 10**: Review Queue Module
* **Sprint 11**: Activity Logs Module
* **Sprint 12**: Authentication
* **Sprint 13**: SQLite Synchronization Engine
* **Sprint 14**: Flutter Data Layer Integration
* **Sprint 15**: WhatsApp Bot Integration
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


   python -m venv venv
   source venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Create `.env` file from example:
   ```bash
   cp .env.example .env
   ```
   Modify `DATABASE_URL` in `.env` to point to your PostgreSQL instance.

### Running the App

Run local development server:
```bash
uvicorn app.main:app --reload
```

### Running Tests

Run backend tests:
```bash
python -m pytest
```
