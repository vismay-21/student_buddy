# Student Buddy - Decisions & Implementation History

This log tracks architectural decisions, feature implementations, and refinement changes made to Student Buddy.

---

## 2026-06-23 (Phase 1: UI Skeleton Redesign & Centralization)

### Decisions
1. **Complete Flutter UI Skeleton**: Focus on standardizing the front-end layout and navigation using mock state controllers and centralized mock datasets, keeping it completely separated from any backend or storage layer.
2. **Centralized Mock State Management**: Introduce a global, reactive mock state model (`AppState` using `ValueNotifier`) to facilitate mock configurations (active semester, feature toggles, etc.) dynamically across views.
3. **Harmonious Visual Design**: Implement a Dark Indigo/Teal theme system (`AppTheme` in `lib/core/theme/app_theme.dart`) relying on glassmorphism visual styling, rounded card structures, and soft custom gradients.

### Implementation Details
* **Onboarding & Auth Flow**:
  * Splash Screen featuring dynamic loading indicator and logo placement.
  * Phone/WhatsApp Number login screen.
  * 6-digit OTP verification screen mock-redirecting to dashboard shell.
* **Core Navigation**:
  * `NavigationShell` managing 4 bottom navigation tabs (Overview, Timetable, Attendance, Settings) or 5 tabs (Overview, Timetable, Attendance, Finance, Settings) depending on the active state of the Finance toggle.
  * Right-side Drawer panel offering shortcuts to Assignments, Notes Repository, and Review Queue screen views.
* **Primary Features UI**:
  * `OverviewScreen`: Consolidated summaries for lectures, attendance warnings, assignments due, recent transactions, and custom digests.
  * `TimetableScreen`: Day-by-day weekly class schedules, room/teacher details, and floating action button to create class.
  * `AttendanceScreen`: Circular goal tracking progress rings, safe skip calculations, and attendance logger buttons.
  * `FinanceScreen`: Swipable credit cards for accounts, transaction lists, income/expense flows, transfers, and categories.
  * `SettingsScreen`: Interactive toggles for notifications, default accounts, and categories.
  * `SemesterSelectionScreen`: Dynamic semester listing and card-switching.
* **Side-Drawer Views**:
  * `AssignmentsScreen`: Completion filtering tabs and task priority cards.
  * `NotesScreen`: Nested visual accordion hierarchy (Semester → Subject → Unit → PDF/Docx files).
  * `ReviewQueueScreen`: Approve, edit, or remove low-confidence OCR or chatbot inputs.

---

## 2026-06-24 (Phase 1 Refinements & Bug Fixes)

### Decisions & Fixes
1. **Support Dark & Light Themes**: Expand `AppTheme` to define complete, dedicated `lightTheme` configurations alongside the existing `darkTheme`. Bind active theme settings directly to a `themeMode` ValueNotifier state toggle inside `AppState` to swap styles on-the-fly.
2. **Dedicated Timetable Add Class Screen**:
   * Migrate the class creation process from a basic modal popup to a dedicated screen (`AddClassScreen`).
   * Introduce a **Subject Template System** (`SubjectTemplate` model) that records previously added subjects to pre-populate details (Room, Faculty, Theme Color) when adding repeating classes.
3. **Resolve Clock Dialog Crash & Match Reference Proportions**:
   * **Crash Fix**: Removed the keyboard entry toggle entirely by setting `initialEntryMode` to `TimePickerEntryMode.dialOnly` inside the `showTimePicker` builder. Also overrode the dialog's `inputDecorationTheme` with a compact, dense OutlineInputBorder configuration inside `showTimePicker`'s theme builder overlay as a safety fallback.
   * **Reference Proportions**: Added `TimePickerThemeData` configurations mimicking the reference app layout ratios (rounded rectangular shapes with `borderRadius: 12` for hour/minute selectors, `borderRadius: 8` for AM/PM toggles, larger bold fonts, and custom color parameters to display background boxes on inactive hour/minute selectors). Enlarged the clock dial diameter and button ratios by scaling the dialog component by 1.15x using `Transform.scale`.
4. **Day Selector Animations**: Enhance the bottom day selection buttons inside `TimetableScreen` using `AnimatedContainer` and `AnimatedDefaultTextStyle` for smooth transitions.
5. **Card Ending Time Readability**: Correct ending time styling and contrast on lecture cards. Expand time display area width to `60` to accommodate varied formats. Resolved a compilation issue where `FontWeight.extrabold` was referenced by changing it to standard `FontWeight.w800`.
6. **Time Selector Touch Targets**: Replace the narrow `GestureDetector` in `AddClassScreen`'s time cards with an `InkWell` component wrapping a full-width container with padding to ensure reliable touch recognition.
7. **Timetable Module Final Code Check**:
   * Verified all imports, controllers, disposal overrides, and compilation states across `timetable_screen.dart` and `add_class_screen.dart`.
   * Confirmed zero warnings/errors in the final compile. The timetable module is frozen and complete.

### Upcoming Session Focus
* Transitioning to the **Attendance Module** to refine progress overlays, target tracking calculations, and log screens.

---

### Session: 2026-06-24 - Attendance Module Redesign (Phase 1 UI)

1. **Attendance Screen Redesign**:
   * Removed single-page subject listing. Introduced a 4-tab sub-navigation shell inside `AttendanceScreen` (Today, History, Subjects, Settings).
   * Swapped views reactively using a custom container matching the glassmorphism theme.
2. **Unified State Management**:
   * Designed local, notifier-like state maps in `_AttendanceScreenState` storing date-wise logs (`_dateActions`), target configuration, semester dates, and holidays.
   * Computed dynamic calculations on the fly for attended/total ratios, skip statuses, and target planner advice.
3. **Sub-Navigation Tabs Implementation**:
   * **Today Tab**: Interactive logging of today's classes from the timetable with a "Whole Day Actions" panel for batch modifications.
   * **History Tab**: Monthly scrolling calendar displaying color-coded status dots (Green, Red, Orange, Purple, Grey) for days, accompanied by Month Day and Lecture summaries and selective log-modifier checklists.
   * **Subjects Tab**: Read-only semester subjects dashboard with custom progress indicators and advice planner widgets.
   * **Settings Tab**: Configuration tools for Target modes (Subject-Wise vs Overall), Target %, Semester Durations, and manual Holiday logging (with OCR import layout).
4. **Riverpod Readiness**:
   * Restructured all modules to run on pure callbacks and properties, ready to swap to a Riverpod Provider without altering components.
5. **Layout Tweaks (Feedback Updates)**:
   * Reversed the "Mark Whole Day" button sequence to: `[Clear]`, `[Day Off]`, `[Missed]`, `[Attended]`.
   * Added corresponding icons to each "Mark Whole Day" button matched by text labels inside a scaling FittedBox container.
   * Removed the redundant "TODAY'S LECTURES" title header from the Today tab view.
   * Reduced the height of the bottom sub-navigation tab bar to 52 for a more compact and elegant layout.

---

### Session: 2026-06-24 - Attendance Module Enhancements (Layout, Navigation & Criteria Customization)

* **History Tab Rearrangement**:
  * Moved the Monthly Day Summary and Monthly Lecture Stats cards to the top of the History screen.
  * Consolidated the Monthly Lecture Stats layout to present all 5 metrics (`Total`, `Attended`, `Missed`, `Off`, and `Attendance %`) side-by-side in a single row.
  * Configured the Month Calendar swiping direction to `Axis.horizontal` for horizontal month-changing.
* **Subjects Tab Navigation**:
  * Made subject cards interactive. Tapping a card navigates to `SubjectHistoryScreen`.
  * Built `SubjectHistoryScreen` with a custom stats header card (including a progress ring showing the criteria and a calculated advice text) and a reverse-chronological list of semester classes where users can manually log attendances.
* **Settings Tab Criteria Modifications**:
  * Renamed all occurrences of "Target" to "Criteria" across the UI.
  * Set the Criteria slider divisions to `10` to enable jumps/increments of 5%.
  * Added 3 Criteria Mode options: `Overall Average`, `Subject-Wise`, and `Subject-Wise Custom`.
  * Built a custom subject-criteria configurator dialog that displays when `Subject-Wise Custom` is selected, letting users configure percentage criteria for each subject individually.
  * Added a `Default Days Off` setting supporting `None`, `Sunday Only`, and `Saturday & Sunday` which automatically registers those days as off in statistics calculations.
* **Verification & Compile Cleanliness**:
  * Ran static analysis showing 0 compile errors. The Attendance Module layout, settings, and navigation redesign are fully complete.

---

### Session: 2026-06-24 - History Date Modals and Space Optimizations

* **DayHistoryScreen Implementation**:
  * Created `DayHistoryScreen` inside `day_history_screen.dart` to show a dedicated logs detail view for any calendar day.
  * Tapping any calendar date cell in the `HistoryTab` now opens `DayHistoryScreen` showing the list of scheduled lectures and quick-toggle action cards.
  * Removed the bottom scrolling logs list from the main `HistoryTab` view to eliminate scrolling and let all monthly stats fit on the screen.
* **Settings Tab Professional Layout**:
  * Replaced the previous choice chips for Criteria Mode selection with a sleek, custom Segmented Control containing `Overall`, `Subject-Wise`, and `Custom` segments on a single line.
  * Removed the redundant "Select Default Days Off" text label from the default days off card, presenting only the choice chips to maximize vertical screen efficiency.
* **Verification & Compilation Cleanliness**:
  * Ran static analysis showing 0 compile errors or warnings in the newly added files.

---

### Session: 2026-06-24 - Attendance UI Refinements (Row Merging, DBMS Default, and Chevrons)

* **Semester Duration Row Merging**:
  * Merged Semester Start Date and Semester End Date selectors into a single row inside a unified card, separated by a vertical divider, saving massive vertical screen height.
* **Custom Subject Criteria Dynamic Slider Defaulting**:
  * Configured all custom criteria to dynamically default to the slider criteria percentage (e.g. 95%), treating all subjects equally without hardcoding.
* **Day History Bulk Actions**:
  * Implemented a "Mark Whole Day" button bar panel inside `DayHistoryScreen` matching the Today tab layout to quickly clear or log all classes for that selected date in bulk.
* **Calendar Swipe & Chevron Navigation**:
  * Configured `BouncingScrollPhysics` for PageView.builder to ensure horizontal month dragging is extremely light and responsive.
  * Added left/right chevron buttons in the calendar header for instant month changes.

---

### Session: 2026-06-24 - Navigation Architecture Refactor

* **Rename Assignments to To Do**:
  * Renamed folders (`assignments/` -> `todo/`), files (`assignments_screen.dart` -> `todo_screen.dart`), classes (`AssignmentsScreen` -> `TodoScreen`), models (`AssignmentMock` -> `TodoMock`), mock variables (`assignments` -> `todoItems`), and descriptions across the codebase to unified "To Do" naming.
* **Drawer Removal**:
  * Deleted `lib/core/widgets/app_drawer.dart` completely.
  * Removed hamburger menu references, keys, and icon buttons.
* **AppBar Top-Right Actions**:
  * Replaced active semester pill and hamburger icon in `NavigationShell` AppBar with two compact, custom-styled action items: Notes (📁 Notes) and Settings (⚙️ Settings).
  * Clicking them opens the respective screen as a pushed page.
* **Bottom Navigation Restructuring**:
  * Reordered bottom navigation items to: `To Do` | `Overview` | `Timetable` | `Attendance` | `Finance` (optional/dynamic).
  * Removed Settings from the bottom bar.
  * Set default active tab to `1` (Overview tab).
* **Settings Screen Refactoring**:
  * Wrapped `SettingsScreen` in a Scaffold with its own AppBar featuring back chevron navigation.
  * Cleaned up and removed all Finance category/account setup sections.
  * Added new Activity Timeline and About cards.
* **Review Queue Widget Integration**:
  * Removed Review Queue from primary navigation and side drawer.
  * Embedded a conditional warning card (`_buildReviewQueueCard`) into the `OverviewScreen` dashboard column which displays `X items need your review [Review Now]` only when pending reviews > 0.
* **To Do Screen Double Header Fix**:
  * Removed nested Scaffold and nested AppBar in `TodoScreen`. Rendered the TabBar and TabBarView directly inside a Column layout, resolving double title display.
* **Top-Right Actions Size Tweaks**:
  * Slightly increased the dimensions of the top-right Notes and Settings action buttons: updated icon sizes from 18 to 22, and font sizes from 10 to 12.
* **Verification & Compilation Cleanliness**:
  * Ran static analysis showing 0 compile errors. All navigation files are fully refactored and cleaned.

---

### Session: 2026-06-24 - To Do Module (Add Task Screen)

* **Add To Do Screen Creation**:
  * Created `AddTodoScreen` inside `add_todo_screen.dart` featuring input fields for Title, Description, and inline selectors for Due Date (DatePicker) and Due Time (TimePicker).
  * Optimized vertical spacing by reducing margins, padding, and input heights to fit all form elements on a single page, eliminating the need to scroll when inputting tasks.
  * Made Due Date fully optional: updated saving validation logic to fallback to "No due date" if none is selected, added clear buttons for Date/Time picker fields, and restricted time picking unless date is selected first.
* **Priority & Category Selectors**:
  * Integrated Priority selectors styled after existing colors (Low: Green/Accent, Medium: Orange/Warning, High: Red/Danger).
  * Shifted the Priority selector card above the Due Schedule card.
  * Added choice chips for categories (Academic, Personal, Event, Project, Finance, Other).
  * Added a dynamic text field when "Other" is selected under Categories, enabling users to enter a custom category name.
  * Added a dedicated **"Add" button** on the top-right of the Category card to add custom categories.
  * Configured category chips as standard **ChoiceChips**. To prevent accidental deletions, the close button was removed, and categories (except "Other") can now be safely deleted by **holding down/long-pressing** them, which shows a confirmation dialog.
* **Simplified Form Layout (Description Field Removal)**:
  * Completely removed the Description field and controller to simplify the task creation/editing experience, preventing clutter.
* **Due Schedule Enhancements**:
  * Moved the "Clear" button to the top-right header of the "Due Schedule" card. This resolves tap collisions inside the date/time inkwells and allows clean reset of the due date/time settings.
* **Future-Proof Placeholder Fields**:
  * Designed a collapsible "Advanced (Future Features)" panel with disabled placeholders: a switch for "Repeat Task" and a locked dropdown showing "Manual" for task originators (Manual, WhatsApp, AI, OCR).
* **Floating Action Button Integration**:
  * Wrapped the main `TodoScreen` in a local Scaffold without an AppBar to cleanly present a Floating Action Button in the bottom right corner without creating double titles.
  * Clicking the FAB navigates to the `AddTodoScreen` and inserts any returned tasks into the in-memory pending list.
* **Task Editing Mode**:
  * Configured `AddTodoScreen` to support editing when initialized with an optional `todoToEdit` parameter.
  * Wrapped the details portion of each task item card in `TodoScreen` with an `InkWell` to navigate to edit mode, allowing users to modify properties (Title, Priority, Due Date, Time, and Category) and submit the changes back to the main list.
* **Verification & Compilation Cleanliness**:
  * Ran static analysis showing 0 compile errors or warnings in the newly added screens.

---

### Session: 2026-06-24 - Notes Repository Enhancements

* **Add Resource Screen Creation**:
  - Replaced the terminology of "Add File" with "Add Resource" to encompass future file formats (PDF, PPT, DOCX, ZIP, Links, etc.).
  - Created a dedicated `AddResourceScreen` inside `add_resource_screen.dart` with dropdown fields for Semester, Subject, Unit/Subsection, and an upload button placeholder.
  - Semester defaults to the active semester (read from `AppState.instance.activeSemester.value` or passed via navigation) and manual creation is blocked.
  - **Dropdown Pre-selection Logic**: Updated Subject and Subsection fields so that they are left unselected (showing hints like `Select Subject` and `Select Unit / Subsection`) when adding a resource via the FAB, prompting the user to make a choice. Added validation checks requiring selections.
  - Implemented popups via **"+ Create New Subject"** and **"+ Create New Subsection"** buttons, which dynamically update dropdown values and save custom entries into state.
  - **Automated Type Detection**: Removed the Resource Type dropdown selector completely. The type is now automatically extracted from the resource name extension (e.g. `.pdf` -> `PDF`), defaulting to `Other` if no extension is matched.
  - Included a placeholder upload button text showing `"Select Resource (Coming Soon)"`.
* **Floating Action Button**:
  - Embedded a custom Floating Action Button (+) in `NotesScreen` matching the existing theme to navigate to the resource creation form.
* **Editing Existing Resources**:
  - Extracted individual resource list tiles into a modular component `ResourceCard` inside `resource_card.dart`.
  - Added an edit button next to the download button in `ResourceCard`. Clicking the edit button navigates to `AddResourceScreen` in edit mode (pre-populating all values).
  - In edit mode, added actions to "Save Changes", "Delete Resource" (with a deletion confirmation dialog), or "Cancel".
* **Semester Selection and Filtering**:
  - Synced the top semester selection dropdown on `NotesScreen` with a `ValueListenableBuilder` listening to `AppState.instance.activeSemester`.
  - Selecting a semester immediately filters and shows resources matching the active semester.
  - Pre-seeded different semesters with different mock data sets to ensure switching semesters works dynamically.
* **Future Storage Architecture**:
  - Created `notes_config.dart` holding a placeholder setting for the default download folder path (`Downloads/StudentBuddy/`).
  - Added detailed documentation and architecture block comments detailing future integration with Supabase Storage and lazy loading local file caching.
* **Verification & Compilation Cleanliness**:
  - Ran static analysis confirming 0 compile errors in the Notes module.

---

## 2026-06-29 (Major UI/UX Refactor: Timetable, Attendance, & Overview Architecture)

### Decisions
1. **Centralize Attendance State**: Consolidate all logging states, holiday declarations, date action overlays, default day off parameters, and overall metric calculations directly inside a single reactive instance (`AppState` via `ValueNotifier` and helper mutation handlers).
2. **Eliminate Tab Duplication**: Remove the redundant Today tab from `AttendanceScreen`, reducing sub-tabs to History, Subjects, and Settings.
3. **Consolidate Lecture Cards**: Delete specialized attendance cards (`AttendanceSubjectCard`) in favor of a single unified `LectureCard` that renders in read-only mode for the timetable and edit/log mode for attendance records.
4. **Interactive Dashboard**: Convert `OverviewScreen` into a stateful panel reacting live to attendance settings changes, presenting a "Mark Whole Day" bulk editor, and listing scheduled lectures with inline logging.

### Implementation Details
* **Centralized State Calculations (`AppState`)**:
  - Implemented dynamic average attendance computation, criteria status checker, and custom subject threshold overrides.
  - Added methods `setLectureAction`, `setWholeDayAction`, and `addHoliday` updating state reactively.
* **Unified UI Components**:
  - `LectureCard`: Features dual rendering modes. Timetable reads details statically; Attendance mode shows a circular percentage progress indicator, criteria warning status messages, and selective logging toggle keys.
  - `AttendanceOverviewCard`: Integrated at the top of the `HistoryTab` (above calendar) to give immediate overview and warnings.
* **Screen Refactoring**:
  - `AttendanceScreen`: Reduced to a clean 3-tab layout (History, Subjects, Settings). Updates automatically on state notifiers.
  - `TimetableScreen`: Replaced calendar date strings with static recurring weekdays, rendering read-only `LectureCard` components.
  - `SubjectsTab`: Re-implemented beautiful, inline, and lightweight custom progress ring indicators, resolving dependency on the deleted card component.
  - `DayHistoryScreen` & `SubjectHistoryScreen`: Migrated to the new `LectureCard` to log individual lectures directly.
  - `OverviewScreen`: Re-architected as a stateful screen that displays today's lectures via `LectureCard` and offers a "Mark Whole Day" quick-action panel. Positioned the Review Queue warning card at the very top of the screen (visible only if there are items to review). Removed the obsolete Academic Status (including overall attendance status and To Do summary), Upcoming Events, Quick Shortcuts, and safe skip widgets to achieve a clean, focused dashboard workspace.
* **Verification**:
  - Ran full static analysis showing 0 compile errors and 0 warnings.

---

## 2026-06-29 (Session: UI/UX Polish, Review Queue Forms & SnackBar Integration)

### Decisions
1. **Premium Floating SnackBar Architecture**: Create a single unified, floating custom snackbar (`lib/core/widgets/app_snackbar.dart`) to replace default snackbars and eliminate UI boilerplate.
2. **Space Optimization & Row Consolidation**: Merge historical attendance metrics cards into a side-by-side single row display in `HistoryTab` to eliminate vertical scrolling and keep the calendar immediately visible on load.
3. **Review Queue Form-Based Refactoring**: Remove "Delete" capability from the Review Queue and design specialized input forms for low-confidence data (Finance, OCR Timetable, WhatsApp Cancellation).

### Implementation Details
* **AppSnackbar & Wide Integration**:
  - Built custom floating SnackBar helper class with rounded aesthetics and success/warning/error/info styling.
  - Replaced standard ScaffoldMessenger SnackBar calls in 10 screen files.
* **Overview Dashboard Headers**:
  - Updated main dashboard header to "TODAY'S CLASSES" and added "MARK WHOLE DAY" bulk header.
* **Lecture Card & Progress Ring Polish**:
  - Reduced vertical footprint of `LectureCard` by 20-25% and updated progress ring sizes to 44x44 and stroke width to 3.
  - Rewrote percentage rendering inside circular progress indicators to display the current attendance / target ratio (e.g. `X/Y%`).
* **Attendance Analytics Consolidation**:
  - Created `AttendanceAnalyticsCard` displaying both "DAYS SUMMARY" and "LECTURE STATS" side-by-side.
  - Replaced two separate summary cards in `HistoryTab` with the new analytics card.
  - Removed duplicate overall status card from the top of `SubjectsTab`.
* **Review Queue Screen Refactoring**:
  - Deleted the "Delete" action button.
  - Implemented instant default properties on "Approve" (Category = Other, Account = UPI) with custom SnackBar announcements.
* **Review Queue Edit Screen**:
  - Created `lib/screens/review_queue/review_queue_edit_screen.dart` with dedicated forms and validators for each item type.
  - Wired navigation to dynamically refresh pending review counts on returning to the dashboard.
* **Verification**:
  - Ran full static analysis confirming 0 compile errors.

---

## 2026-06-29 (Session: Collapsible Sections, Fraction Rings & Semester Dialog Metrics)

### Decisions
1. **Dashboard Section Collapse**: Build a reusable, smooth height-expansion widget (`ExpandableSection`) supporting optional frames. The card frame wraps both the header and child content to create styled accordions.
2. **Attendance Ring Layout Overhaul**: Redesign the progress ring text to present current vs target criteria as a clean vertical fraction (`AttendanceRingLabel`) perfectly centered, increasing the numbers/percent sizes, and simplify card metadata rows.
3. **Comprehensive Semester Metrics Dialog & Calendar Legend**: Reorder widgets on the history tab and merge the calendar and color legend inside the same card (height: 395) separated by a Divider to save vertical space.
4. **Lightweight Floating Pill SnackBar**: Shrink overall dimensions of `AppSnackbar` and lower margins to `bottom: 8` when a bottom navigation bar is present.

### Implementation Details
* **Collapsible Dashboards (`ExpandableSection`)**:
  - Implemented `lib/core/widgets/expandable_section.dart` with a `showFrame` outer card outline wrapping both the toggle header and children.
  - Wrapped `OverviewScreen` Today's Classes and Finance Summary in `ExpandableSection(showFrame: true)` to group elements elegantly.
* **Redesigned Percentage Ring Labels (`AttendanceRingLabel`)**:
  - Developed `lib/core/widgets/attendance_ring_label.dart` centering the fraction block inside the ring. Increased the calling font size to `13` on both `LectureCard` and `SubjectsTab` to make numbers and percentage signs larger.
* **Lecture Card Metadata & Button Optimization**:
  - Merged the status guidance text (font size: 13) and action buttons into a single row inside `LectureCard` to reduce card height.
  - Increased the button sizing (vertical padding to 6, icon size to 15, and text to 10).
  - Polished typography inside `LectureCard`: set time column width to 44, subject name font size to 15.5, room text size to 13, and ensured start time uses a uniform primary text color.
  - Standardized specific safe-skip messages: `"can skip X lectures"`, `"can't skip next lecture"`, and `"need to attend next X lectures"`.
* **History Tab Reordering & Calendar Legend Merge**:
  - Embedded the monthly `AttendanceCalendarLegend(transparentBackground: true)` inside the calendar card at the bottom, separated by a Divider, reducing the overall card container height to `395` to lift the analytics card up, and setting transition speeds to `500ms`.
* **SnackBar Dimensions Optimization**:
  - Adjusted margins to `bottom: 8` (or `16` on pushed pages) to center and place the notification pill neatly above the bottom navigation bar without hovering too high.
* **Timetable FAB Alignment**:
  - Reduced the bottom padding of the FloatingActionButton on `timetable_screen.dart` to `60` so that it sits at the same offset relative to the weekday sub-navigation bar as the To Do FAB does relative to the main bottom bar.
* **Verification**:
  - Verified static compilation cleanliness using `flutter analyze`.

---

## 2026-06-29 (Session: Finance Module Freeze & Toggle Persistence)

### Decisions
1. **Official Finance Freeze**: All Finance module features and logic are officially frozen. Future development priorities will shift completely to the Academic workflow and backend implementation.
2. **Disabled by Default**: Fresh installations of the application will start with the Finance module disabled (turned OFF) by default.
3. **Persist the Toggle**: Save the "Enable Finance Module" settings switch state to local storage to maintain the state across hot restarts, app restarts, and app terminations.
4. **App Initialization Hook**: Restore the persisted Finance module state during app startup before building any widgets to prevent UI flickering.

### Implementation Details
* **Dependency Addition**:
  - Added `shared_preferences: ^2.2.0` package to `pubspec.yaml` and installed it via `flutter pub get`.
* **State & Persistence Layer**:
  - Updated `lib/core/utils/app_state.dart` to default `isFinanceEnabled` to `false`.
  - Added `init()` method to `AppState` to fetch the persisted boolean value from `SharedPreferences` (defaulting to `false`) and set up an automatic listener on `isFinanceEnabled` to save any state changes immediately.
* **App startup**:
  - Adjusted the `main()` function in `lib/main.dart` to be asynchronous, ensuring `WidgetsFlutterBinding.ensureInitialized()` is called and `await AppState.instance.init()` completes before `runApp` executes.
* **Verification**:
  - Ran `flutter analyze` ensuring 0 compile errors or new warnings.

---

## 2026-07-02 (Phase 2: Sprint 0 — Backend Foundation)

### Decisions
1. **Initialize Backend Structure**: Build a clean and modular FastAPI architecture mirroring the exact layer pattern: API -> Service -> Repository -> SQLAlchemy 2.x -> PostgreSQL.
2. **Standard API Protocol**: Define a uniform response payload format (`ApiResponse` and `ApiErrorResponse`) across all routers. Any validation failure, resource conflicts, or missing records must resolve into standard JSON structures.
3. **Structured Logging and Exception Hierarchy**: Set up standard, clean console logging and register application-wide global error interceptors for handling `AppException` and `RequestValidationError`.
4. **Asynchronous Alembic Environment**: Configure Alembic migration engine to run dynamically and asynchronously utilizing SQLAlchemy async engines and environment parameters.

### Implementation Details
* **Core Foundation & Config**:
  - Configured `Settings` with Pydantic settings loading env values from `.env`.
  - Set up async engines and session makers in `core/database.py`.
  - Registered `get_db` async generator for dependency injection.
* **API Routers & Schemas**:
  - Implemented health check endpoint under `GET /api/v1/health` returning status and version info.
  - Setup core FastAPI application in `main.py` configuring CORS, logging, exception handlers, and API prefix tags.
* **Migrations and Folder skeleton**:
  - Initialized Alembic configuration in `alembic.ini` and async configuration in `alembic/env.py`.
  - Created directories and `__init__.py` markers for all 6 target modules (academic, settings, todo, notes, review_queue, activity_logs) across api, models, schemas, repositories, and services layers.
* **Testing Suite**:
  - Created `tests/conftest.py` setting up `pytest-asyncio` strictly-configured HTTP client fixtures.
  - Added endpoint tests under `tests/test_health.py`.
* **Verification**:
  - Verified all tests passed successfully and verified manual health routing.

---

## 2026-07-03 (Phase 2: Sprint 0 — Backend Foundation Refinements)

### Decisions
1. **Centralize Core Constants**: Move application-wide constants (such as versioning, pagination configurations, timezone defaults, and security algorithms) out of Settings class/routers and into `app/core/constants.py` to decouple dynamic env configurations from static properties.
2. **Standardize Environment Template**: Fully document all future expected env variables (`DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_KEY`, `JWT_SECRET`, `ENVIRONMENT`, etc.) in `.env.example`.
3. **Structured File Logging Design**: Prepare `setup_logging` with a logical switch to support file routing (`logs/backend.log`) in future production deployments without modifying core logger registrations.

### Implementation Details
* **Constants Extraction**:
  - Populated `backend/app/core/constants.py` with `BACKEND_VERSION`, `API_V1_PREFIX`, `DEFAULT_PAGE_SIZE`, `MAX_PAGE_SIZE`, `TIMEZONE`, and `JWT_ALGORITHM`.
  - Refactored `backend/app/core/config.py` to remove `API_V1_PREFIX`.
  - Refactored `backend/app/main.py` and `backend/app/api/v1/health.py` to import and reference constants.
* **Environment Configuration**:
  - Overwrote `backend/.env.example` with standard mock keys and descriptions for Supabase, database connections, environment settings, and JWT configurations.
* **Logging System**:
  - Restructured `backend/app/core/logging.py` to include `enable_file_logging: bool = False` argument and integrated `RotatingFileHandler` initialization setup.
* **Verification**:
  - Ran pytest suite successfully (1 test passed).
  - Manually ran uvicorn server and verified dynamic health check response.

### Deferred Decisions
* **File Logging Enablement**: Real-time writing to `logs/backend.log` is deferred until a persistent volume is configured in deployment.
* **Supabase Integration**: Initializing Supabase client config variables is deferred until Sprint 12.

---

## 2026-07-03 (Phase 2: Sprint 1 — Semester Module)

### Decisions
1. **Scope Restriction**: Keep Sprint 1 strictly focused on the Semester Module.
2. **Attendance Settings Table Only**: Create the `attendance_settings` database model and migration as it is created automatically whenever a semester is created (business rule), but postpone full implementation (services, API routers, and tests) to Sprint 5.
3. **App Settings Removal**: Do not implement `app_settings` in Sprint 1; deferred entirely to Sprint 7.
4. **Deferred Activity Log Integrations**: Do not create `ActivityLog` tables or repositories yet. Insert clearly marked `# TODO` placeholders in the semester service methods to link log creation in Sprint 11.
5. **Eager Loading Efficacy**: Force eager loading via `selectinload(Semester.attendance_settings)` in repo queries to avoid ORM lazy load errors in async execution.
6. **Async Testing Isolation**: Use connection-level transaction rollbacks per test (mocking `session.commit` to `session.flush` during test execution) and clean the tables before running the test suite to guarantee consistent, isolated test runs without side effects. Recreate and dispose of the SQLAlchemy engine pool before/after each test function to prevent event loop mismatch errors with `asyncpg`.

### Implementation Details
* **Database Models & Migrations**:
  - Defined `Semester` and `AttendanceSettings` models inside `app/models/academic/`.
  - Registered models in alembic env and generated migration script `192b4793464e`. Executed migration to apply schema to PostgreSQL.
* **Schemas & DTOs**:
  - Implemented `SemesterCreate`, `SemesterUpdate`, and `SemesterResponse` with validations in `app/schemas/academic/semester.py`.
  - Implemented `AttendanceSettingsResponse` in `app/schemas/academic/attendance_settings.py`.
  - Upgraded Pydantic models to V2 standard `ConfigDict(from_attributes=True)` to prevent deprecation warnings.
* **Repositories & Services**:
  - Built `SemesterRepository` with full CRUD queries (handling `selectinload` for attendance settings relationships) and `AttendanceSettingsRepository` with create-only method.
  - Built `SemesterService` containing semester unique checks, date consistency validation, auto-creation of default attendance settings (mode overall, target 75%), and marked placeholders for Sprint 11 activity audits.
* **REST API Endpoints**:
  - Created `app/api/v1/academic/semesters.py` and registered router in `main.py`.
  - Added CRUD API endpoints wrapping responses in standard `ApiResponse` envelope.
* **Pytest Testing Suite**:
  - Built comprehensive tests in `tests/academic/test_semesters.py` achieving 100% code coverage.
  - Setup transaction-based rollback database session fixture and engine pool disposal in `tests/conftest.py`.
* **Verification**:
  - Ran pytest suite successfully (11 tests passed in under 1s).

---

## 2026-07-03 (Phase 2: Sprint 1 — Semester Module Refinements)

### Decisions
1. **Centralize Magic Numbers**: Extract the hardcoded default attendance goal (`75`) into `DEFAULT_ATTENDANCE_GOAL` in `app/core/constants.py`. Reference the constant in the service and test suite.
2. **Semester Overlap Validation**: Add a business rule preventing any two semesters from having overlapping date ranges. Adjacent semesters (one ends the day the other starts) are explicitly allowed. Enforce on both create and update operations.
3. **Professional API Documentation**: Annotate every Semester endpoint with `summary`, `description`, and `response_description` for clear Swagger/OpenAPI output.
4. **Confirm Existing Correctness**: Verified that the `CriteriaMode` enum already uses the finalized values (`overall`, `subject`, `custom`) across the model, migration, and schemas. Verified that `semester_number > 0` validation already exists via `Field(..., gt=0)` in Pydantic schemas.

### Implementation Details
* **Constants Extraction**:
  - Added `DEFAULT_ATTENDANCE_GOAL = 75` to `backend/app/core/constants.py`.
  - Updated `SemesterService` to import and use the constant instead of a hardcoded literal.
* **Overlap Validation**:
  - Added `get_overlapping(start_date, end_date, exclude_id)` method to `SemesterRepository` using strict `<` / `>` comparisons so adjacent (touching) ranges are permitted.
  - Integrated overlap checks in `SemesterService.create_semester` and `SemesterService.update_semester` (excluding the current semester on update). Raises `ConflictException` with a descriptive message identifying the conflicting semester.
* **API Documentation**:
  - Added `summary`, `description`, and `response_description` to all five Semester endpoints (list, get, create, update, delete) in `app/api/v1/academic/semesters.py`.
* **Test Suite Expansion**:
  - Added 4 new tests: `test_semester_service_overlapping_create`, `test_semester_service_adjacent_create`, `test_semester_service_overlapping_update`, and `test_api_create_overlapping_semester`.
  - Replaced hardcoded `75` with `DEFAULT_ATTENDANCE_GOAL` constant in assertion checks.
  - Spread API test dates into far-future years to prevent accidental overlap between tests.
* **Verification**:
  - Ran pytest suite successfully (15 tests passed in 1.31s).

### Deferred Decisions
* None.

---

## 2026-07-03 (Phase 2: Sprint 2 — Subject Module)

### Decisions
1. **Model Hierarchy Isolation**: Define `Subject` and `NotesSubject` models in their respective directories (`app/models/academic/` and `app/models/notes/`). Per database business rules, there is no foreign key relation between subjects and notes_subjects; synchronization is maintained via application service logic.
2. **Automated Notes Synchronization**: Any subject creation must automatically trigger the creation of a corresponding `NotesSubject` with the same name and semester. Any subject rename must rename the corresponding `NotesSubject`.
3. **Optional Notes Subject Deletion**: When deleting a subject, the user can conditionally decide whether the corresponding `NotesSubject` should be deleted via the `delete_notes_subject` parameter (default is false to preserve notes by default).
4. **Validation Rules**: Validate HEX theme colors using regex `^#[0-9A-Fa-f]{6}$` in Pydantic. Ensure `attendance_goal` is bounded between 1 and 100 on the model layer (CHECK constraint) and schema layer, defaulting to `DEFAULT_ATTENDANCE_GOAL` (75).
5. **Eager Loading & Alphabetical Listing**: List subjects by semester ordered alphabetically by `subject_name`.
6. **Activity Log placeholders**: Insert `# TODO` placeholders in the Subject service methods for the future Sprint 11 Activity Log integration.

### Implementation Details
* **Database Models & Migrations**:
  - Created `Subject` model in `app/models/academic/subject.py`.
  - Created `NotesSubject` model in `app/models/notes/notes_subject.py`.
  - Registered models in `alembic/env.py` and applied the migration `1a9ff58b8423` to update database tables.
* **Pydantic Schemas**:
  - Designed `SubjectCreate`, `SubjectUpdate`, and `SubjectResponse` with strict validations in `app/schemas/academic/subject.py`.
  - Created `NotesSubjectResponse` in `app/schemas/notes/notes_subject.py`.
* **Repositories & Services**:
  - Implemented `SubjectRepository` and `NotesSubjectRepository` with full CRUD/utility queries.
  - Implemented `SubjectService` to handle parent semester validations, subject name uniqueness validation per semester, and automatic `NotesSubject` synchronization (create, rename, delete).
* **API Endpoints**:
  - Created thin RESTful endpoints under `/api/v1/academic/subjects` and registered the router in `app/main.py`.
  - Enhanced all endpoints with descriptive OpenAPI documentation.
* **Testing**:
  - Truncated `subjects` and `notes_subjects` tables during database cleanups in `tests/conftest.py`.
  - Wrote 12 comprehensive unit and integration tests in `tests/academic/test_subjects.py`.
* **Verification**:
  - Ran pytest suite successfully (all 28 tests passed in 2.18s).

---

## 2026-07-03 (Phase 2: Sprint 3 — Lecture Template Module)

### Decisions
1. **Model Schema Implementation**: Implement the complete `lecture_templates` table schema and a minimal dependency definition for `lecture_instances` (recording dates, status and attendance enums, marked indicators) and `holidays` (semester ID, dates, holiday names) to support the semester generation pipeline.
2. **Automated Semester Lecture Generation**: On creation of a lecture template, the service must automatically generate individual `LectureInstance` entries for every date within the parent semester's range whose day of the week matches the template's, automatically skipping any defined holidays.
3. **Future Instance Synchronization**: If the day of the week on a template is updated:
   - All future scheduled and unmarked instances of the template (`lecture_date > date.today()`) must be deleted.
   - New instances must be generated on the new day of the week from `max(date.today() + timedelta(days=1), semester.start_date)` to the semester's end date, skipping holidays.
   - If the day of the week did not change, keep existing instances intact.
4. **Foreign Key Cascade Deletion**: Deleting a template must cascade delete all associated instances in the database (implemented via PostgreSQL `ON DELETE CASCADE` and SQLAlchemy relationship configuration).
5. **OpenAPI and Logging Integration**: Provide thin API endpoints under `/api/v1/academic/lecture-templates` with full descriptions, and include `# TODO` markers in service routines to log changes in Sprint 11.

### Implementation Details
* **Database Models & Migrations**:
  - Created `LectureTemplate`, `LectureInstance`, and `Holiday` models under `app/models/academic/`.
  - Registered models in alembic env and applied migration `2db1602c28b4`.
* **Pydantic Validation Schemas**:
  - Created `LectureTemplateCreate`, `LectureTemplateUpdate`, and `LectureTemplateResponse` in `app/schemas/academic/lecture_template.py` with custom model-level validators verifying that `start_time` is strictly before `end_time`.
  - Created `LectureInstanceResponse` in `app/schemas/academic/lecture_instance.py`.
* **Repositories & Services**:
  - Implemented repositories for `lecture_templates`, `lecture_instances`, and `holidays`.
  - Built `LectureTemplateService` managing schedule checks, date-by-date semester lecture instance generation, holiday exclusions, and future instance rebuilding.
* **REST API Endpoints**:
  - Added thin CRUD controllers under `/api/v1/academic/lecture-templates` and registered in `main.py`.
* **Testing**:
  - Truncated the new tables in database cleanup fixtures inside `tests/conftest.py`.
  - Wrote 12 comprehensive unit and integration tests inside `tests/academic/test_lecture_templates.py`.
* **Verification**:
  - Ran full pytest suite successfully (all 40 tests passed in 3.13s).

---

## 2026-07-03 (Phase 2: Sprint 3 — Lecture Template Module Refinements)

### Decisions
1. **Holiday Module Boundary Refinement**: Respect sprint boundaries by removing the early-access Holiday repository (`app/repositories/academic/holiday.py`), service methods, and endpoints. Cleaned up Holiday integration tests. Added clear TODO markers pointing to Sprint 6 where holiday filtering will be fully integrated.
2. **Selective Instance Regeneration**: Update instance regeneration rules so changing only the room on a lecture template leaves instances completely intact. Instance recreation is triggered only when scheduling attributes (`day_of_week`, `start_time`, `end_time`) are modified.
3. **Timetable Overlap Validation**: Block the creation or modification of lecture templates if they overlap with another template in the same semester on the same day. Adjacent time slots (one ending when another starts) are allowed.
4. **Transaction Integrity**: Enforce transaction safety by executing updates and instance regeneration within a single savepoint transaction (`db.begin_nested()`). If any part of the regeneration pipeline fails, all template properties and instances are rolled back to their pre-update state.
5. **Expanded Test Coverage**: Build out 9 brand new, comprehensive tests checking conflict validation, boundary generation conditions, leap-year calculations, schedule changes vs. room changes, and transaction rollback properties.

### Implementation Details
* **Holiday Module Clean Up**:
  - Deleted `app/repositories/academic/holiday.py`.
  - Removed HolidayRepository registration/usage from `LectureTemplateService`.
  - Added placeholders/TODO comments for holiday exclusions to be added during Sprint 6.
* **Selective Instance Regeneration**:
  - Refactored `LectureTemplateService.update_template` to check if only non-scheduling attributes like `room` were modified, returning early to avoid triggering instance updates.
* **Timetable Overlap Validation**:
  - Added `check_timetable_overlap(semester_id, day_of_week, start_time, end_time, exclude_template_id)` method to `LectureTemplateRepository`.
  - Integrated overlap check inside `create_template` and `update_template` in `LectureTemplateService`, raising `ConflictException` if conflicts are found.
* **Transaction Integrity**:
  - Wrapped model updates, instance deletions, and new instance creations within a single database savepoint transaction using `async with self.db.begin_nested():` inside `LectureTemplateService.update_template`.
* **Test Suite Expansion**:
  - Replaced the testing suite in `tests/academic/test_lecture_templates.py` to remove holiday integration tests and add comprehensive coverage for conflict validation (`test_timetable_overlap_validation_create`, `test_timetable_overlap_validation_update`), boundary conditions (`test_semester_with_zero_matching_weekdays`, `test_semester_boundary_generation`), leap-year calculations (`test_leap_year_generation`), scheduling vs. room updates (`test_update_only_room_does_not_regenerate`, `test_update_start_time_regenerates`, `test_update_end_time_regenerates`), and transaction integrity (`test_transaction_rollback_on_failed_regeneration`).
* **Verification**:
  - Ran the full pytest suite successfully, with all 46 tests passing in 3.96s.

---

## 2026-07-03 (Phase 2: Sprint 4 — Lecture Instance Module)

### Decisions
1. **Runtime Attendance Calculations**: Dynamic stats (total, present, absent, attendance %, remaining, safe skip) are calculated on the fly in `LectureInstanceService` using the database rows, rather than being persisted.
2. **Attendance Validation Rules**: Validations inside the service layer block marking holiday/cancelled lectures as present or absent. Resets back to unmarked are allowed. Changing status to holiday/cancelled automatically resets attendance status and clears metadata.
3. **Whole-Day Bulk Marking**: The bulk mark whole day API returns counts of updated and skipped (cancelled/holiday) lectures.
4. **Optimized Subject History Queries**: Database-level filtered queries (`get_by_subject`) with eager loading are implemented to fetch subject history efficiently.
5. **Synchronization Placeholder**: Added a Sprint 13 placeholder comment indicating where to mark records as pending synchronization after local updates.

### Implementation Details
* **Pydantic Schemas**:
  - Defined request body `LectureInstanceUpdate`, bulk update schema `LectureInstanceBulkUpdate`, bulk update response `LectureInstanceBulkUpdateResponse`, and dynamic `AttendanceStatsResponse`.
  - Created nested response schema `LectureInstanceDetailResponse` including eager loaded `LectureTemplateNested` and `SubjectResponse` details.
* **Repositories & Services**:
  - Implemented repository methods `get_by_id`, `get_by_date`, `get_by_subject`, and `list_instances` with SQLAlchemy eager loading.
  - Built `LectureInstanceService` implementing validations, bulk operations, and runtime stats calculations.
* **REST API Endpoints**:
  - Implemented thin controllers under `/api/v1/academic/lecture-instances` and registered the router in `main.py`.
* **Testing**:
  - Truncated `lecture_instances` table in database cleanup fixtures.
  - Wrote 19 unit and integration tests inside `tests/academic/test_lecture_instances.py` verifying all edge cases, enforcements, calculations, and bulk marks.
* **Verification**:
  - Ran the full pytest suite successfully, with all 65 tests passing in 5.28s.

---

## 2026-07-03 (Phase 2: Sprint 4 — Lecture Instance Refinements)

### Decisions
1. **Attendance Calculator Extraction**: Extracted all pure, stateless attendance-related mathematical computations (percentage, safe skip count, remaining lectures, and status message text formatting) from `LectureInstanceService` into a dedicated utility helper class `AttendanceCalculator` at `app/utils/attendance_calculator.py`.
2. **AttendanceStatsResponse Future-proofing**: Added an optional, nullable `criteria_mode` field to `AttendanceStatsResponse` to prepare it for Sprint 5 integration, leaving it unpopulated for now with a TODO reminder.

### Implementation Details
* **Attendance Calculator**:
  - Implemented `AttendanceCalculator` class in `backend/app/utils/attendance_calculator.py` with static methods.
  - Refactored `LectureInstanceService._calculate_stats` to delegate calculations to the helper.
* **Schema Updates**:
  - Imported `CriteriaMode` and updated `AttendanceStatsResponse` in `backend/app/schemas/academic/lecture_instance.py` with the new optional field.
* **Verification**:
  - Ran the full pytest suite successfully, with all 65 tests passing in 5.28s.

---

## 2026-07-05 (Phase 2: Sprint 5 — Attendance Settings Module)

### Decisions
1. **Separation of Calculations**: Extracted and migrated all dynamic calculations from `LectureInstanceService` into a dedicated `AttendanceStatisticsService` to cleanly encapsulate the rules for the three criteria modes (Overall, Subject, Custom).
2. **Criteria Mode Implementation**:
   - **Overall Mode**: Overall percentage is computed by division of all attended/scheduled classes. Subject-level stats compare against the semester's overall goal.
   - **Subject Mode**: Subject-level stats compare against the semester's overall goal. Semester stats are calculated as the arithmetic mean of active subject percentages.
   - **Custom Mode**: Subject-level stats compare against each subject's custom goal. Semester stats aggregate individual subject percentages and sums of safe skips/required classes.
3. **Database Immutability**: Enforced that changing attendance settings only influences runtime stat compilation and does not touch or modify historical lecture data.
4. **REST Path Design**: Standardized on a RESTful path configuration using path parameters: `GET /api/v1/academic/attendance-settings/{semester_id}` and `PUT /api/v1/academic/attendance-settings/{semester_id}`.

### Implementation Details
* **Service Layers**:
  - Implemented `AttendanceSettingsService` to process validations, transitions, and partial updates (supporting clearing the overall goal with `None` in custom mode).
  - Implemented `AttendanceStatisticsService` to coordinate multi-mode runtime stats.
  - Refactored `LectureInstanceService` to delegate stats requests to `AttendanceStatisticsService` with an optional backwards-compatible fallback in the constructor.
* **REST Routers**:
  - Created router at `backend/app/api/v1/academic/attendance_settings.py` and registered it in `main.py`.
* **Testing**:
  - Added 13 tests inside `tests/academic/test_attendance_settings.py` ensuring service constraints, boundary checks (empty subjects, unmarked lectures), and API status codes.
* **Verification**:
  - Ran the full pytest suite with 78 tests passing successfully in 7.31s.

---

## 2026-07-05 (Phase 2: Sprint 6 — Holiday Module)

### Decisions
1. **Holiday Restrictive Status Modifiers**: Enforced that holiday mutations (create/update/delete) only affect lecture instances whose current `lecture_status` is `scheduled`. Manually `cancelled` lectures are never modified or overwritten by holiday operations. When removing or moving a holiday, only restore instances that were previously marked `holiday` back to `scheduled`.
2. **Transaction Integrity**: Wrapped all database modifications in a single transaction (using nested savepoints `begin_nested` inside the service operations) to commit changes atomically and rollback all states on any exception.
3. **SQLAlchemy Bulk Update Optimization**: Used bulk updates (`update(LectureInstance)`) to execute status updates database-side in one query rather than loading and iterating through instances in Python memory.
4. **Chronological Calendar Endpoint**: Provided a lightweight calendar route `/api/v1/academic/holidays/calendar/{semester_id}` returning only date and name pairs, ordered chronologically.

### Implementation Details
* **Pydantic Schemas**: Created `HolidayCreate`, `HolidayUpdate`, `HolidayResponse`, and `HolidayCalendarItem` schemas at `app/schemas/academic/holiday.py`.
* **Repository and Service Layer**: Implemented `HolidayRepository` and `HolidayService` at `app/repositories/academic/holiday.py` and `app/services/academic/holiday.py`.
* **LectureTemplate Integration**: Integrated holiday date checking inside `LectureTemplateService` template creation and regeneration logic.
* **REST API Router**: Defined router at `app/api/v1/academic/holidays.py` and registered it in `main.py`.
* **Testing**: Added 16 tests inside `tests/academic/test_holidays.py` covering CRUD, edge cases (holidays on days with no lectures, deleting holiday with no lectures, updating to same/existing holiday dates, cancelled status protection, and chronological calendar output).
* **Verification**: Ran the full pytest suite; all 94 tests passed successfully in 6.26s.

### Refinements
1. **Future-Proof Restoration TODO**: Added a detailed TODO in `HolidayService` planning future restoration logic when external modules are permitted to modify `lecture_status` during an active holiday.
2. **Selective Bulk Update Writes**: Optimized database writes during bulk status changes to `holiday`. Rather than unconditionally resetting attendance fields for all matching lectures, we split status updates:
   - For already unmarked lectures, only `lecture_status` is updated.
   - For marked lectures, both `lecture_status` and attendance fields are reset.
3. **Integration Test Verification**: Added a new integration test verifying that creating a lecture template *after* holiday creation correctly generates instances on the holiday date with `lecture_status = holiday` and `attendance_status = unmarked`.
4. **Documentation**: Documented within `HolidayService` class description: `"Holidays never modify Lecture Templates. They only modify Lecture Instances."`
5. **Verification**: Executed the full backend pytest suite; all 95 tests pass successfully.

---

## 2026-07-05 (Phase 2: Sprint 7 — App Settings Module)

### Decisions
1. **Database Singleton Constraint**: Implemented a check constraint `settings_id = 1` in the database to guarantee that the `app_settings` table contains exactly one row. Removed any service-level automatic recreation of settings, raising a `RuntimeError` instead if the singleton row is unexpectedly missing.
2. **Active Semester Reference and Delete Protection**:
   - Foreign key constraint `active_semester_id` references `semesters.semester_id` with `RESTRICT` on delete.
   - Added validation check to `SemesterService.delete_semester` to prevent deletion of the active semester (raising a `ConflictException` 409).
3. **Data Normalization & Input Validation**:
   - Normalized incoming themes to lowercase: `light`, `dark`, or `system`.
   - Normalized the notes download directory path string using `os.path.normpath` and trimming whitespace before persistence.
   - Validated that the active semester exists before assigning it.

### Implementation Details
* **Pydantic Schemas**:
  - Defined `AppSettingsResponse` and `AppSettingsUpdate` in `app/schemas/settings/app_settings.py` with custom field validators for theme normalization and path normalization.
* **Repository and Service Layer**:
  - Implemented `AppSettingsRepository` to only expose `get_settings()` and `update(settings)`.
  - Implemented `AppSettingsService` to orchestrate validation, retrieve settings, and update settings.
* **REST API Router**:
  - Added router exposing `GET /api/v1/app-settings` and `PUT /api/v1/app-settings`.
* **Testing**:
  - Wrote 10 integration and unit tests covering default seeding verification, casing normalization, directory path normalization, active semester deletion protection, singleton row deletion error handling, and partial updates.
  - Resolved `CASCADE` truncation side-effects in pytest session setup by adding automated re-seeding of `app_settings` singleton row inside `clean_database`.
* **Verification**:
  - All 105 tests across the backend suite completed successfully.

---

## 2026-07-05 (Phase 2: Sprint 8 — Todo Module)

### Decisions
1. **Semester Independence**: Documented and enforced that todos are completely independent of semesters, subjects, attendance, notes, and academic modules.
2. **Simplified Endpoints**: Dropped the dedicated `PUT /todos/{id}/complete` endpoint. Completed/pending states are handled directly via the main update endpoint `PUT /todos/{id}`.
3. **Database-Level Title Search**: Configured the query parameter `q` to execute case-insensitive `ILIKE` pattern matching directly on the database level via the repository.
4. **Custom Sorted Default Ordering**: Defined a clear priority ordering inside the repository:
   - Pending todos first.
   - Priority High -> Medium -> Low.
   - Earliest due date first, with NULL values placed last.
   - Newest created_at timestamp first.
5. **Runtime Computed Overdue Fields**: Added `days_overdue` and `is_overdue` as dynamically calculated properties in the response payload. These values are determined at runtime and not stored in the database.
6. **Due Date Year Validation**: Restrained due dates to a logical window (years between 2000 and 2100) using Pydantic validators.

### Implementation Details
* **SQLAlchemy Database Model**: Created the `Todo` model in `app/models/todo/todo.py` with custom PostgreSQL enums for status, category, priority, and created_by.
* **Pydantic Schemas**: Created Pydantic schemas in `app/schemas/todo/todo.py` including `TodoCreate`, `TodoUpdate`, and `TodoResponse`. Added custom model validators to compute overdue parameters.
* **Repository and Service Layer**:
  - Implemented `TodoRepository` in `app/repositories/todo/todo.py` with custom search and default sorting rules.
  - Implemented `TodoService` in `app/services/todo/todo.py` managing state transitions (setting or clearing `completed_at` timestamp).
* **REST API Router**: Defined router in `app/api/v1/todo/todos.py` exposing full CRUD routes and registered it inside `main.py`.
* **Testing**:
  - Wrote 13 integration and unit tests in `tests/todo/test_todos.py` verifying CRUD, search, priority ordering, state transitions, timezone-aware offsets, and overdue day offsets.
  - Added the `todos` table to the database truncation list inside `tests/conftest.py`.
* **Verification**:
  - All 118 tests across the test suite passed successfully.

---

## 2026-07-05 (Phase 2: Sprint 9 — Notes Repository Module)

### Decisions
1. **Academic Subject Module Synchronization**: Configured `Notes Subjects` to be read-only from the Notes module perspective. They are automatically created, renamed, and deleted by the `Academic Subject` module.
2. **Metadata Uniqueness Constraints**:
   - Unique constraint on Notes Sections: `(notes_subject_id, section_name)`.
   - Unique constraint on Notes Resources: `(section_id, file_name)` and `(section_id, resource_name)`.
3. **MIME Type and Size Validation**: Enforced that `file_size_bytes > 0` and `mime_type` conforms to an allow-list of PDF, Word, PowerPoint, Text, and common Image formats.
4. **Dynamic File Extension**: Removed the redundant `file_extension` database column. The file extension is derived dynamically from `file_name` in the Pydantic response schema.
5. **Alphabetical Hierarchy Retrieval**: Configured `GET /hierarchy/{semester_id}` to eagerly load and sort subjects, sections, and resource lists alphabetically.
6. **Case-Insensitive Joint Search**: Implemented a main resource list endpoint with optional query parameters `q` (for resource name/file name search) and `semester_id`, ordered alphabetically by Semester Number -> Notes Subject Name -> Section Name -> Resource Name.
7. **Future Hook placeholders**: Added explicit Sprint 11 (Activity Logging) and Sprint 12 (Supabase physical file deletion) TODO comments inside resource creation/deletion service actions.
8. **Database Query Performance**: Added database indexes on search-intensive foreign keys and names: `notes_sections(notes_subject_id)`, `notes_resources(section_id)`, `notes_resources(resource_name)`, and `notes_resources(file_name)`.
9. **Resource Pagination Support**: Added `limit` and `offset` pagination to the `GET /api/v1/notes/resources` endpoint, validating that the limit is within `[1, 100]` and offset is `>= 0`, defaulting to return 50 items.
10. **Storage Verification & Deletion Flows**: Documented the future Sprint 12 physical upload verification checks and the transactional file deletion flows using structured TODO blocks in the service layer.

### Implementation Details
* **SQLAlchemy Database Models**:
  - Defined `NotesSection` in `app/models/notes/notes_section.py` and `NotesResource` in `app/models/notes/notes_resource.py` with custom relationships and cascade deletes. Added database indexes to search columns.
* **Pydantic Schemas**:
  - Implemented response and create/update schemas in `app/schemas/notes/`. Added validators checking mime_type and file size constraints, and computed the file extension dynamically.
* **Repository and Service Layer**:
  - Created `NotesSectionRepository` and `NotesResourceRepository` with complete CRUD and joint search queries supporting limit/offset pagination.
  - Implemented `NotesService` to coordinate CRUD, validation, hierarchy sorting, pagination parameters, and storage deletion hooks.
* **API Router**:
  - Registered notes endpoints in `app/api/v1/notes/notes.py` supporting query-validated pagination, and registered the router prefix under `app/main.py`.
* **Testing**:
  - Wrote 6 comprehensive integration and unit tests in `tests/notes/test_notes.py` covering read-only subjects, section and resource CRUD, validation constraints, hierarchy sorting, joint search, and pagination limits, offsets, and range checks.
  - Configured `tests/conftest.py` clean-up to truncate `notes_sections` and `notes_resources`.
* **Verification**:
  - All 124 tests across the entire test suite completed successfully.

---

## 2026-07-05 (Phase 2: Sprint 10 — Review Queue Module)

### Decisions
1. **Polymorphic Entity Resolution**: Configured the `review_queue` table to link to referenced database entities dynamically using `entity_type` (e.g. `todo`, `attendance`, `finance`) and `entity_id` without physical foreign keys.
2. **Transactional Resolution Flow**: Designed the resolve endpoint to update the referenced entity (e.g., Todo status and fields, or LectureInstance attendance and lecture status) and mark the review status as `resolved` (setting `resolved_at` to the current UTC timestamp) within a single database transaction.
3. **Pydantic-Schema Re-validation**: Re-used Pydantic update schemas (`TodoUpdate` and `LectureInstanceUpdate`) to parse and validate incoming `resolution_data` fields inside the Service layer, ensuring consistent data rules (e.g. priority ranges, date constraints).
4. **Attendance Business Boundary Enforcements**: Prevented marking holiday or cancelled lectures as present or absent during resolution, in alignment with core academic rules.
5. **Database-Level Search Indexing**: Added indexes on `review_queue.review_status` and `review_queue.entity_id` to optimize retrieval speeds.
6. **Future Activity Logging Hooks**: Added placeholder TODOs for Sprint 11 Activity Logs creation upon successful review resolutions.

### Implementation Details
* **SQLAlchemy Database Model**: Created `ReviewQueue` model in `app/models/review_queue/review_queue.py` defining columns, enums, and indexes. Exposed the classes in the package initializer.
* **Pydantic Schemas**: Implemented `ReviewQueueBase`, `ReviewQueueCreate`, `ReviewQueueResolve`, and `ReviewQueueResponse` in `app/schemas/review_queue/review_queue.py`.
* **Repository and Service Layer**:
  - Implemented `ReviewQueueRepository` in `app/repositories/review_queue/review_queue.py` querying items sorted by created_at desc (for pending/all) and resolved_at desc (for resolved/history).
  - Implemented `ReviewQueueService` in `app/services/review_queue/review_queue.py` orchestrating validation, entity resolution, status transitions, and transaction commits.
* **REST API Router**: Defined endpoints in `app/api/v1/review_queue/review_queue.py` and registered them under `app/main.py`.
* **Testing**:
  - Added the `review_queue` table to the database truncation list inside `tests/conftest.py`.
  - Wrote 9 comprehensive integration and unit tests in `tests/review_queue/test_review_queue.py` verifying creation validations, sorting orders, item details, successful todo/attendance/finance resolutions, business rule validation failures, and endpoint error handling.
* **Verification**:
  - All 133 tests across the entire test suite completed successfully.

---

## 2026-07-05 (Phase 2: Sprint 10 Refinements — Review Queue Architectural Improvements)

### Decisions
1. **Resolver Pattern**: Extracted all entity-resolution logic out of `ReviewQueueService` into dedicated resolver classes under `app/services/review_queue/resolvers/`. A `RESOLVERS` registry maps `EntityType` → resolver class, allowing future modules (Finance, Notes, OCR, etc.) to be wired in by adding a resolver and a registry entry without modifying `ReviewQueueService`.
2. **ResolvedBy Metadata**: Added `resolved_by` enum (`user`, `system`, `admin`) as a new column on the `review_queue` table with a default of `user`. Exposed through `ReviewQueueResolve` payload and `ReviewQueueResponse`.
3. **Runtime Entity Summary**: Added a runtime-only `entity_summary` field to `ReviewQueueResponse` that is dynamically computed from the resolver's `get_summary()` method and never persisted to PostgreSQL. Examples: `"Study Virtual Memory"` for todos, `"Operating Systems • Tuesday • 10:00"` for lectures.
4. **Pagination**: Added `limit` (1–100, default 50) and `offset` (≥ 0, default 0) query parameters to `GET /api/v1/review-queue`, validated at the API layer via FastAPI `Query()` constraints.
5. **Search**: Added optional `q` query parameter performing case-insensitive `ILIKE` substring search against `review_message` at the repository/database level.
6. **Index on `created_at`**: Added a database index on the `review_queue.created_at` column to optimise ordering of the pending queue (newest first).
7. **Architectural Contract Documentation**: Explicitly documented in `docs/database/1_database_schema.md` that `entity_type + entity_id` must always reference a valid, existing entity, and that the Review Queue never owns business data — it only coordinates human verification.

### Implementation Details
* **Model Layer**: Updated `ReviewQueue` in `app/models/review_queue/review_queue.py` to add `ResolvedBy` enum and `resolved_by` column with `index=True` on `created_at`.
* **Resolver Layer** (new `app/services/review_queue/resolvers/`):
  - `base.py`: `BaseResolver` interface with `resolve()` and `get_summary()` contracts.
  - `todo.py`: `TodoResolver` applying `TodoUpdate`-validated changes and returning the todo title as its summary.
  - `lecture_instance.py`: `LectureInstanceResolver` applying `LectureInstanceUpdate`-validated changes and returning `"{subject} • {day} • {HH:MM}"` as its summary.
  - `finance.py`: `FinanceResolver` no-op placeholder returning `"Finance Record"`.
  - `registry.py`: `RESOLVERS = { EntityType.TODO: TodoResolver, EntityType.ATTENDANCE: LectureInstanceResolver, EntityType.FINANCE: FinanceResolver }`.
* **Schema Layer**: Updated `ReviewQueueResolve` with `resolved_by` field (default `ResolvedBy.USER`). Updated `ReviewQueueResponse` with `resolved_by` and `entity_summary` (runtime-only, default `""`).
* **Repository Layer**: Refactored `list_items()` to accept `limit`, `offset`, and `q` parameters, applying `ILIKE` filtering and SQLAlchemy `limit()/offset()` clauses.
* **Service Layer**: Refactored `ReviewQueueService` to dispatch via `RESOLVERS` registry and populate `entity_summary` on all returned items using `_populate_summary()`.
* **API Router Layer**: Exposed `q`, `limit`, and `offset` as validated `Query()` parameters on `GET /api/v1/review-queue`.
* **Migration**: Generated and applied `6e78de13a647_refine_review_queue` adding the `resolved_by` column (with `server_default='USER'`) and `ix_review_queue_created_at` index.
* **Documentation**: Updated `docs/database/1_database_schema.md` with `resolved_by` enum, index table, and the Architectural Contract block.
* **Testing**: Rewrote and expanded `tests/review_queue/test_review_queue.py` to 31 tests covering:
  - Resolver registry completeness.
  - `get_summary()` for all entity types (including unknown IDs).
  - `resolve()` success and failure paths for Todo and LectureInstance resolvers.
  - Malformed `resolution_data` validation error.
  - `entity_summary` presence on list, detail, and resolve responses.
  - `resolved_by` field written correctly for `user` and `admin`.
  - Pagination `limit` and `offset` bounds and page-disjoint checks.
  - Case-insensitive search match, no-match, and substring correctness.
  - Already-resolved conflict detection.
  - API endpoint `limit`/`offset` out-of-range 422 validation.
* **Verification**:
  - All 155 tests across the entire test suite completed successfully.

---

## 2026-07-05 (Phase 2: Sprint 11 Implementation — Activity Logs Module)

### Decisions
1. **Centralized Logging Hook**: Built `log_activity(...)` helper in `app/services/activity_logs/logger.py` as the unified entry point. Business services only call this helper instead of directly interacting with the repository or service layers.
2. **Best-Effort Execution**: Implemented nested savepoints (`db.begin_nested()`) inside the logger helper so that database/constraint errors in activity logs do not roll back the parent business transaction.
3. **Correlation Tracking**: Added a nullable `correlation_id` (UUID) to the schema to track multi-step transaction chains (e.g. WhatsApp conversation -> Review Queue -> Activity Log).
4. **Bulk Aggregation**: Refactored mass updates (like marking a whole day's attendance) to log a single aggregated summary event instead of writing multiple individual records.
5. **Runtime Entity Summary Resolution**: Introduced dynamic `entity_summary` resolution in `app/services/activity_logs/summary.py` so that human-readable names (subject names, todo titles) are resolved on retrieval instead of storing mutable state.

### Implementation Details
* **Model Layer**: Defined `ActivityLog` in `app/models/activity_logs/activity_log.py` with custom unique PostgreSQL enum names (`activity_actor_type`, `activity_entity_type`, `activity_action_type`) to avoid namespace collisions.
* **Service Layer**:
  - `logger.py`: Centralized `log_activity` helper.
  - `summary.py`: Dynamically fetches entity details via repositories and resolvers (TodoResolver, etc.).
* **API Layer**: Added GET `/api/v1/activity-logs/` (supporting actor_type, correlation_id, date range, pagination, and case-insensitive search `q`) and GET `/api/v1/activity-logs/{id}`.
* **Migration**: Applied `81d4a04d538d_create_activity_logs_table` migration creating the table and indexes.
* **Service Integrations**:
  - `SemesterService`: Logged create, update, delete.
  - `SubjectService`: Logged create, update, delete.
  - `HolidayService`: Logged create, update, delete.
  - `AttendanceSettingsService`: Logged configuration updates.
  - `LectureTemplateService`: Logged creation, updates, and deletes.
  - `LectureInstanceService`: Logged individual attendance/status updates, and a single summary log for bulk whole day updates.
  - `TodoService`: Logged creation, details updates, completion, and deletion.
  - `ReviewQueueService`: Logged creation and resolution events.
* **Testing**: Added `tests/activity_logs/test_activity_logs.py` covering logging success, transaction isolation, summary resolution, listing pagination/search, and get-by-id detail endpoint.
* **Verification**:
  - All 160 tests across the entire test suite completed successfully.

---

## 2026-07-06 (Phase 3: Sprint 12 Implementation — Backend Verification & Flutter API Integration)

### Decisions
1. **MVP API Integration**: Set up clean frontend-backend interaction following the contract `Flutter → Dio → FastAPI → PostgreSQL` without introducing auth or database sync layers yet.
2. **Standardized Error Interceptors**: Configured interceptors to handle standardized error parsing (translating FastAPI validations and HTTP exceptions to structured Dart `ApiException` payloads).
3. **Graceful AppState Bootstrapping**: Refactored `AppState` to fetch semesters dynamically from the backend and select the active semester, defaulting to bootstrapping a clean `Semester 1` if no records exist.
4. **Dynamic Semester Selection**: Removed the hardcoded list of semesters from the UI and added a validated dialog form allowing users to create new Semesters in the PostgreSQL database from the app interface.

### Implementation Details
* **Networking Layer**:
  - Added `dio: ^5.4.0` dependency to `pubspec.yaml`.
  - `lib/core/network/api_constants.dart`: Centralized local uvicorn host address (`http://127.0.0.1:8000/api/v1`) and API paths.
  - `lib/core/network/interceptors.dart`: Structured API logs and parsed custom `ApiException` payloads.
  - `lib/core/network/dio_client.dart`: Exposed pre-configured, singleton `Dio` client wrapper.
* **Semester Module Integration**:
  - `lib/data/dto/semester/semester_dto.dart`: Mapped Pydantic request/response structures to Dart serialization objects (`SemesterDto` and `SemesterCreateRequest`).
  - `lib/data/api/semester_api.dart`: Implemented semester client endpoints (`GET`, `POST` to `/academic/semesters`).
  - `lib/data/repositories/semester_repository.dart`: Exposed clean Repository pattern contract interfaces for fetching and saving semesters.
* **UI Screen Integration**:
  - `lib/core/utils/app_state.dart`: Modified to asynchronously boot/load active semesters on startup and persist selections.
  - `lib/screens/settings/semester_selection_screen.dart`: Connected UI listing and selection to database. Created dialog form with date-pickers to insert new semesters directly via `SemesterRepository`.
* **Verification**:
  - Tested all endpoints manually in Swagger UI (Semester validation, Subject auto-notes sync, Lecture generation).
  - Executed static code analysis (`flutter analyze`), which passed with `Exit code 0` (no errors).

---

## 2026-07-07 (Phase 3: Sprint 12.5 — Business Logic & Runtime Calculation Audit)

### Decisions
1. **Adherence to Non-Persistent Derived Data Principles**: Formally verified that all statistics and metadata that change over time (such as attendance percentages, safe skip counts, required attendance, overdue flags, file extensions, and review/activity log summaries) are computed dynamically at runtime and never persisted in PostgreSQL to avoid data drift.
2. **Best-Effort Activity Logging**: Formally validated that the centralized logger helper uses nested savepoints (`db.begin_nested()`) to write activity logs in isolation, ensuring logging failures never crash primary business transactions.
3. **Resolver-Based Resolution Integrity**: Verified that the Review Queue resolvers dynamically enforce business boundary checks (such as blocking attendance status updates for holiday/cancelled lecture instances) during manual resolution.
4. **Clean Frontend Integration**: Completed migration of the remaining Flutter screens to fetch data exclusively from the backend, completely removing dummy data references and resolving screen layouts.

### Implementation Details
* **Audit Report Compilation**:
  - Created a comprehensive `audit_report.md` document addressing database schemas, dynamic runtime fields, business boundary validation checks, and edge cases across the Academic, To-Do, Notes, Review Queue, and Activity Logs modules.
* **Documentation Update**:
  - Updated `docs/context.md` and `docs/history.md` to record the completion of the business logic audit, preparing the codebase structure for Sprint 13 (Authentication).
* **Verification**:
  - Ran the full backend test suite (`venv/bin/pytest`); all 160 unit and integration tests passed successfully.