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
