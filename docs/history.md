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