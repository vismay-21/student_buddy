# Student Buddy - Phase 1 Redesign Implementation Plan (Updated)

This plan details the restructuring and implementation of the Phase 1 Flutter UI skeleton based on user feedback. We will focus entirely on a production-ready visual experience and navigation structure with hardcoded dummy data, avoiding any backend, SQLite, Riverpod, or AI integrations.

## Proposed Folder Structure
We will clean up the existing disorganized files in `lib` and establish the following structure:
```text
lib/
  main.dart
  core/
    theme/
      app_theme.dart (Consistent modern dark-slate and blue design system with sleek gradients)
    widgets/ (Reusable components)
      subject_card.dart
      summary_card.dart
      attendance_card.dart
      finance_card.dart
      notification_card.dart
      empty_state_card.dart
      app_drawer.dart (Side drawer panel containing Assignments, Notes, Review Queue)
    utils/
      dummy_data.dart (Centralized dummy data for all modules)
      app_state.dart (Global reactive states for mock behavior, e.g., active semester, finance module status, using ValueNotifier)
  screens/
    splash/
      splash_screen.dart (Intro animation and logo transition)
    auth/
      login_screen.dart (WhatsApp/Phone login UI)
      otp_screen.dart (WhatsApp OTP input verification UI)
    navigation_shell.dart (Handles bottom navigation & displays the top-right app drawer button)
    overview/
      overview_screen.dart (Dashboard landing page containing all summary cards)
    timetable/
      timetable_screen.dart (Weekly schedules, day selectors, class items)
    attendance/
      attendance_screen.dart (Circular progress widgets, goal & skip indicators, status buttons)
    finance/
      finance_screen.dart (Account balances, monthly flows, recent transactions, analytic charts)
    settings/
      settings_screen.dart (Notification options, toggles for digests & modules, default accounts, Semester Selection button)
      semester_selection_screen.dart (Card-based semester selector accessed from Settings)
    assignments/
      assignments_screen.dart (Pending, upcoming, and completed task segments, accessed via drawer)
    notes/
      notes_screen.dart (Semester -> Subject -> Unit -> File hierarchy viewer, accessed via drawer)
    review_queue/
      review_queue_screen.dart (Cards for validating ambiguous data with Approve/Edit/Delete actions, accessed via drawer)
```

## User Review Required
We will delete the following legacy or redundant files:
- `lib/data/database_helper.dart` (unused database logic)
- `lib/services/timetable_service.dart` (unused legacy service)
- `lib/models/class_session.dart` (legacy model)
- `lib/models/subject.dart` (legacy model)
- `lib/screens/attendance_screen.dart` (replaced by organized screen folder)
- `lib/screens/finance_screen.dart` (replaced)
- `lib/screens/overview_screen.dart` (replaced)
- `lib/screens/timetable_screen.dart` (replaced)
- `test/widget_test.dart` (default test code, to be deleted as requested)

## Navigation Architecture
1. **Onboarding Flow**: Splash Screen -> Login Screen -> OTP Screen -> Main Bottom Navigation Shell.
2. **Bottom Navigation (Main Screens)**:
   - Overview
   - Timetable
   - Attendance
   - Finance (removes dynamically if disabled in Settings)
   - Settings
3. **Top-Right App Drawer (Sidebar)**:
   - From any main screen, clicking the 3-line icon in the top right will open the drawer.
   - The drawer contains navigation items to:
     - Assignments
     - Notes
     - Review Queue
4. **Semester Selection**:
   - Access via Settings (opens Semester Selection dialog or sub-screen to switch the active semester).

## Sub-Phase Breakdown

### Phase 1A: Authentication + Navigation + Overview
1. Create `app_theme.dart` (rich aesthetics: glassmorphism, rounded shapes, deep dark teal/indigo and accent neon colors).
2. Create `dummy_data.dart` and `app_state.dart`.
3. Implement `SplashScreen` transitioning to `LoginScreen`.
4. Implement `LoginScreen` and `OtpScreen` (6-digit PIN verification UI).
5. Implement `AppDrawer` (right-side drawer containing Assignments, Notes, Review Queue links).
6. Implement `NavigationShell` (handles bottom navigation with dynamic 4 vs 5 tabs, and App Bar showing the screen title on the left and the 3-line drawer button on the top right).
7. Implement `OverviewScreen` showing Dashboard summary cards:
   - Today's Lectures
   - Attendance Summary
   - Upcoming Assignments
   - Today's Expenses
   - Notifications
   - Safe Skip Card
   - Quick action shortcuts

### Phase 1B: Timetable + Attendance + Finance
1. Implement `TimetableScreen`:
   - Day indicator on top-left, Date on top-right.
   - Day selector (Mon-Sun) placed horizontally just above the bottom navigation panel.
   - Class lecture cards (time, room, teacher, color stripe).
   - Floating Action Button to mock "Add Class".
2. Implement `AttendanceScreen`:
   - Target attendance & trend summaries.
   - CustomPainter circular progress rings representing current vs target.
   - Quick buttons: Clear, Off, Missed, Attended.
3. Implement `FinanceScreen`:
   - Account balance cards page-swiping.
   - Recent Transactions card list.
   - Monthly summary cards.
   - Action dialog modals for Add Income, Add Expense, Transfer.

### Phase 1C: Assignments + Notes + Review Queue + Settings
1. Implement `AssignmentsScreen` (accessed via AppDrawer).
2. Implement `NotesScreen` (semester -> subject -> unit visual directory, accessed via AppDrawer).
3. Implement `ReviewQueueScreen` (approve, edit, delete ambiguous items, accessed via AppDrawer).
4. Implement `SettingsScreen`:
   - Switches for Digests, Notifications, and Finance Module.
   - Dialog/Sub-Screen for active Semester Selection.

## Verification Plan
1. We will verify compile and build success using `flutter analyze`.
2. We will run the app locally and test navigation visually.
