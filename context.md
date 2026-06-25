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
├── backend/                  # Future FastAPI backend
├── docs/                     # Documentation files
├── lib/                      # Flutter source directory
├── main.dart
├── core/
│   ├── models/
│   │   └── subject_template.dart   # Template model for pre-filling recurring classes
│   ├── theme/
│   │   └── app_theme.dart          # Light and Dark theme specifications
│   ├── utils/
│   │   ├── app_state.dart
│   │   └── dummy_data.dart
│   └── widgets/
└── screens/
    ├── attendance/
    │   ├── widgets/
    │   │   ├── attendance_calendar_legend.dart    # Colored dot visual indicator key for the monthly calendar view
    │   │   ├── attendance_day_summary_card.dart   # Summary card showing class logging totals for the active month
    │   │   ├── attendance_overview_card.dart      # Dashboard header element showing general attendance percentages and warnings
    │   │   ├── attendance_subject_card.dart       # Detailed course indicator showing targets, log actions, and class metrics
    │   ├── attendance_screen.dart        # Container hosting sub-navigation tabs (Today, History, Subjects, Settings)
    │   ├── attendance_settings_tab.dart  # Preferences pane configuring criteria modes, percentages, semester ranges, and holidays
    │   ├── day_history_screen.dart       # Dedicated logging details screen for a specific selected date
    │   ├── history_tab.dart              # Month-view pageable calendar covering past school days
    │   ├── subject_history_screen.dart   # Dedicated history log and action list for a specific academic course
    │   ├── subjects_tab.dart             # Analytics dashboard list showing targets, rates, and recommendations for all subjects
    │   └── today_tab.dart                # Current day class logging card layout and bulk whole-day logging actions
    ├── auth/
    │   ├── login_screen.dart             # Authentication gateway using phone/WhatsApp input
    │   └── otp_screen.dart               # Verification page to confirm the user OTP code
    ├── finance/
    │   └── finance_screen.dart           # Wallet manager showing card layouts, transaction records, and budgets
    ├── navigation_shell.dart             # Core layout scaffolding handling app navigation, tab routing, and top-right header actions
    ├── notes/
    │   ├── add_resource_screen.dart      # Dedicated screen to add/edit resources with dynamic subjects, units, types, and placeholders
    │   ├── notes_config.dart             # Storage config and architecture placeholders detailing Supabase/local download caches
    │   ├── notes_screen.dart             # Class materials organizer grouping resources by Semester, Subject, and Unit with a FAB
    │   └── resource_card.dart            # Custom component displaying a resource item with download status and edit buttons
    ├── overview/
    │   └── overview_screen.dart          # Main dashboard summary showing lectures, attendance warnings, tasks, and financial updates
    ├── review_queue/
    │   └── review_queue_screen.dart      # Interface resolving OCR timetable parser conflicts and low-confidence logs
    ├── settings/
    │   ├── semester_selection_screen.dart # Preference selector updating the active school semester
    │   └── settings_screen.dart          # Global toggles for theme selector, active modules, and notification settings
    ├── splash/
    │   └── splash_screen.dart            # Initial loading screen verifying configuration and theme choices
    ├── timetable/
    │   ├── add_class_screen.dart         # Dedicated screen to add class schedules with templates and clock pickers
    │   └── timetable_screen.dart         # Interactive weekly calendar detailing daily classroom routines
    ├── todo/
    │   ├── add_todo_screen.dart          # Screen for creating new tasks with title, due dates, priority, and category
    │   └── todo_screen.dart              # Screen listing, sorting, and managing due tasks and reminders
├── pubspec.yaml
├── STUDENT BUDDY DEVELOPMENT.md        # Development phase details & roadmap
├── STUDENT BUDDY MASTER REQUIREMENTS.txt # Master product requirements documentation
├── context.md                          # This file (Project Memory)
└── history.md                          # Project decisions & implementation history log
```

---

## 9. Current Development Phase

We are currently refining the **UI Skeleton (Phase 1)**.

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
    * Replaced the simple attendance screen with a 4-tab sub-navigation shell (Today, History, Subjects, Settings) with a reduced height of 52px.
    * Replaced the "Mark Whole Day" button sequence on the Today tab with a reversed sequence `[Clear]`, `[Day Off]`, `[Missed]`, `[Attended]` along with matching icons.
    * Reordered the History tab to place Monthly Day Summary and Monthly Lecture Stats (re-laid out into a 5-column single-row alignment containing attendance percentages) at the top of the screen.
    * Converted calendar Month page swiping to horizontal.
    * Made Subject Cards in the Subjects tab clickable, navigating to a new, fully interactive `SubjectHistoryScreen` showing dynamic calculations and a class history log.
    * Renamed settings from "Target" to "Criteria", implemented 3 criteria modes (Overall, Subject-Wise, Subject-Wise Custom) with a per-subject configuration dialog, and added Default Days Off chips.

* **What was intentionally NOT implemented (postponed to future phases)**:
  * Backend code
  * Supabase integration & authentication APIs
  * Riverpod state management implementation (pure Flutter components/state used for now)
  * FastAPI server endpoints
  * AI integrations (NLU, Vision, Context engines)
  * OCR engine and document parser
  * WhatsApp webhook and Meta Cloud API integration
  * Active background schedulers and Push notifications
  * Core business logic functions (calculations, file storage uploads, direct API communication)

---

## 10. Future Development Roadmap

* **Phase 2**: Supabase Authentication (OTP Login & User State integration)
* **Phase 3**: Backend setup + PostgreSQL Database Design & CRUD
* **Phase 4**: WhatsApp Bot Webhook & Meta Cloud API Integration
* **Phase 5**: AI Engine, Gemini NLP Parsing, and OCR Timetable Extraction
* **Phase 6**: Production Deployment (FastAPI, PostgreSQL database, and Cloud instances)

---

## 11. Important Notes For Future AI Sessions

* **Never remove functionality**: Do not delete screens, features, or modules unless the user explicitly requests it.
* **Never simplify the project by removing modules**: The balance between Academic and Finance must remain intact.
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

