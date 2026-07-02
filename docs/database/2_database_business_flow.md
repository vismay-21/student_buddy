# Student Buddy Database Business Flow
Version: 1.0 (Pre-Finance Module)

---

# 1. Introduction

This document defines the business flow of the Student Buddy database.

Unlike the Database Schema document, which describes how data is stored, this document explains how data moves through the system whenever a user performs an action.

Its primary purpose is to provide a single source of truth for backend development, synchronization logic, API implementation and future AI integration.

The Finance Module has intentionally been excluded from this version and will be documented separately once finalized.

---

# 2. Design Philosophy

The business flow follows a few important principles.

---

## 2.1 Database Owns Data

Every entity has exactly one owner.

Examples:

- Attendance belongs to Lecture Instances.
- Timetable belongs to Lecture Templates.
- Notes belong to the Notes Repository.
- Review Queue never owns application data.
- Activity Logs never own application data.

No information should be duplicated between tables.

---

## 2.2 Application Performs Calculations

The database stores only raw information.

Derived values are calculated whenever required.

Examples include:

- Attendance Percentage
- Safe Skip
- Remaining Lectures
- Monthly Analytics
- Overdue Tasks

These values are intentionally never stored inside the database.

---

## 2.3 Immutable History

Application history is append-only.

Instead of modifying historical records, new Activity Logs are created.

This provides:

- Complete audit history
- AI learning context
- Better debugging
- User activity timeline

---

## 2.4 Review Before Automation

Whenever the application cannot confidently determine required information, it should never make irreversible decisions automatically.

Instead:

1. Create or update the primary record using safe defaults whenever possible.
2. Create a Review Queue item.
3. Allow the user to resolve the issue manually.

This keeps automation predictable while maintaining user control.

---

## 2.5 Offline First

The application must continue functioning without an internet connection.

Database operations are first performed on the local SQLite database.

Synchronization with Supabase PostgreSQL occurs later according to the synchronization strategy documented separately.

Business logic must remain identical regardless of whether the application is online or offline.

---

# 3. General Database Flow Principles

The following sequence applies to almost every database operation inside the application.

```
User Action
      │
      ▼
Input Validation
      │
      ▼
Database Operation
      │
      ▼
Automatic Business Rules
      │
      ▼
Activity Log Creation
      │
      ▼
UI Refresh
```

Depending on the operation, Review Queue generation may occur before the Activity Log is created.

---

## General Flow Steps

### Step 1 — User Action

The operation begins through one of the following sources:

- Mobile Application
- WhatsApp Bot
- Review Queue
- Internal System Process

---

### Step 2 — Validation

Before modifying the database, the application validates:

- Required fields
- Parent entity existence
- Duplicate constraints
- Business rule constraints

If validation fails, the operation stops and no database changes occur.

---

### Step 3 — Database Modification

The required table is updated.

This may involve:

- Insert
- Update
- Delete

Every operation modifies only the table responsible for owning the data.

---

### Step 4 — Automatic Business Rules

Certain operations automatically trigger additional actions.

Examples:

- Creating a Subject automatically creates a Notes Subject.
- Creating a Holiday updates affected Lecture Instances.
- Resolving a Review Queue item updates the referenced entity.

These actions are part of the business logic and occur automatically after the primary database operation.

---

### Step 5 — Activity Logging

Every meaningful operation generates exactly one Activity Log entry.

Activity Logs are append-only and are never modified after creation.

---

### Step 6 — UI Refresh

Once the database operation completes successfully, the user interface refreshes using the latest data.

Any calculated values (attendance percentage, analytics, safe skip, etc.) are recalculated during this stage.

---

# 4. Application Startup Flow

This flow is executed whenever the application starts.

Its purpose is to initialize the application state using the locally available database.

Synchronization with the cloud database is handled separately and is not part of this flow.

---

## Startup Flow

```
Application Launch
        │
        ▼
Load Application Settings
        │
        ▼
Determine Active Semester
        │
        ▼
Load Today's Timetable
        │
        ▼
Load Today's Attendance State
        │
        ▼
Load Pending To-Do Items
        │
        ▼
Load Pending Review Queue Items
        │
        ▼
Calculate Dashboard Summaries
        │
        ▼
Display Overview Screen
```

---

## Step 1 — Load Application Settings

Read the single record from `app_settings`.

Load:

- Theme
- Active Semester
- Finance Module State
- Notification Preferences
- Notes Download Directory

---

## Step 2 — Determine Active Semester

Using `active_semester_id`, determine which semester's academic data should be loaded.

All academic queries use this semester unless the user explicitly switches to another semester.

---

## Step 3 — Load Today's Timetable

Retrieve today's Lecture Instances using:

- Active Semester
- Current Date

Only lectures scheduled for the current day are loaded.

---

## Step 4 — Load Attendance State

Retrieve today's attendance status directly from `lecture_instances`.

Attendance percentages are not loaded because they are calculated dynamically.

---

## Step 5 — Load Pending To-Do Items

Retrieve all pending To-Do items.

Completed tasks remain available in their respective view but are not included in pending summaries.

---

## Step 6 — Load Pending Review Queue

Retrieve all unresolved Review Queue items.

If any exist, the Overview screen displays the Review Queue card.

If none exist, the card remains hidden.

---

## Step 7 — Calculate Dashboard Data

The Overview screen calculates:

- Overall Attendance Percentage
- Subject Attendance Percentages
- Safe Skip Status
- Today's Lecture Summary
- Pending To-Do Count

These values are calculated from existing database records and are never permanently stored.

---

## Step 8 — Display Overview Screen

The application displays the dashboard using the most recent local data.

If cloud synchronization occurs later, only the affected components refresh.

---


# 5. Academic Module Business Flow

The Academic Module manages the complete academic lifecycle including semesters, subjects, timetable, attendance and holidays.

---

# 5.1 Semester Management

A semester acts as the parent entity for all academic data.

---

## Create Semester

### Purpose

Creates a new semester that will contain subjects, timetable, attendance records, holidays and notes.

---

### Flow

```
User Creates Semester
        │
        ▼
Validate Semester Number
        │
        ▼
Create Semester
        │
        ▼
Create Attendance Settings
        │
        ▼
Create Activity Log
        │
        ▼
Operation Complete
```

---

### Database Operations

Insert into:

- semesters
- attendance_settings

Insert Activity Log.

---

### Automatic Business Rules

- Semester Number must be unique.
- Attendance Settings are automatically created.
- No lecture instances are generated yet because no timetable exists.
- No Notes Subjects are created because no academic subjects exist.

---

## Edit Semester

### Purpose

Updates semester information.

---

### Flow

```
User Updates Semester
        │
        ▼
Validate Data
        │
        ▼
Update Semester
        │
        ▼
Create Activity Log
        │
        ▼
Operation Complete
```

---

### Database Operations

Update:

- semesters

Insert:

- activity_logs

---

### Automatic Business Rules

- Semester Number uniqueness must remain valid.
- Existing academic records remain unchanged.

---

## Delete Semester

### Purpose

Deletes an existing semester.

---

### Flow

```
User Requests Deletion
        │
        ▼
Confirmation Dialog
        │
        ▼
Delete Semester
        │
        ▼
Cascade Delete
        │
        ▼
Create Activity Log
```

---

### Database Operations

Delete:

- semesters

Automatically cascades to:

- subjects
- lecture_templates
- lecture_instances
- attendance_settings
- holidays
- notes_subjects
- notes_sections
- notes_resources

Insert:

- activity_logs

---

### Automatic Business Rules

- Active semester cannot be deleted until another semester becomes active.
- Cascade behaviour is handled through foreign key relationships.

---

## Change Active Semester

### Purpose

Changes the semester currently used by the application.

---

### Flow

```
User Selects Semester
        │
        ▼
Update App Settings
        │
        ▼
Reload Academic Module
        │
        ▼
Create Activity Log
```

---

### Database Operations

Update:

- app_settings

Insert:

- activity_logs

---

### Automatic Business Rules

- Only one semester can be active at any time.
- Academic modules reload using the newly selected semester.

---

# 5.2 Subject Management

Subjects represent the academic courses belonging to a semester.

---

## Create Subject

### Purpose

Creates a new academic subject.

---

### Flow

```
User Creates Subject
        │
        ▼
Validate Data
        │
        ▼
Insert Subject
        │
        ▼
Automatically Create Notes Subject
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert:

- subjects
- notes_subjects

Insert:

- activity_logs

---

### Automatic Business Rules

- Notes Subject has the same name as the Academic Subject.
- Notes Subject belongs to the same semester.
- Notes Subject is created through application logic.
- No foreign key exists between both tables.

---

## Edit Subject

### Purpose

Updates subject information.

---

### Flow

```
User Updates Subject
        │
        ▼
Validate Data
        │
        ▼
Update Subject
        │
        ▼
Update Matching Notes Subject
        │
        ▼
Create Activity Log
```

---

### Database Operations

Update:

- subjects
- notes_subjects

Insert:

- activity_logs

---

### Automatic Business Rules

- If the Academic Subject name changes, the corresponding Notes Subject name is also updated.
- Synchronization is handled by application logic.

---

## Delete Subject

### Purpose

Deletes an academic subject.

---

### Flow

```
User Requests Deletion
        │
        ▼
Confirmation Dialog
        │
        ▼
Delete Subject
        │
        ▼
Prompt For Notes Subject
        │
        ▼
Create Activity Log
```

---

### Database Operations

Delete:

- subjects

Optional Delete:

- notes_subjects

Insert:

- activity_logs

---

### Automatic Business Rules

- Deleting the subject removes timetable templates.
- Lecture instances belonging to the subject are automatically removed.
- User decides whether the matching Notes Subject should also be deleted.

---

# 5.3 Timetable Management

The timetable consists of recurring lecture templates.

Lecture Instances are generated from these templates.

---

## Create Lecture Template

### Purpose

Creates a recurring lecture.

---

### Flow

```
User Creates Lecture
        │
        ▼
Validate Data
        │
        ▼
Insert Lecture Template
        │
        ▼
Generate Lecture Instances
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert:

- lecture_templates

Insert:

- lecture_instances

Insert:

- activity_logs

---

### Automatic Business Rules

- Lecture Instances are generated only within the semester duration.
- Generation excludes dates marked as holidays.
- Generated Lecture Instances initially have:

```
lecture_status = scheduled
attendance_status = unmarked
```

---

## Edit Lecture Template

### Purpose

Updates a recurring lecture.

---

### Flow

```
User Updates Lecture
        │
        ▼
Update Template
        │
        ▼
Update Future Lecture Instances
        │
        ▼
Create Activity Log
```

---

### Database Operations

Update:

- lecture_templates

Update:

- future lecture_instances

Insert:

- activity_logs

---

### Automatic Business Rules

- Past Lecture Instances remain unchanged.
- Only future scheduled lectures inherit timetable modifications.

---

## Delete Lecture Template

### Purpose

Removes a recurring lecture.

---

### Flow

```
Delete Template
        │
        ▼
Delete Future Lecture Instances
        │
        ▼
Create Activity Log
```

---

### Database Operations

Delete:

- lecture_templates

Delete:

- future lecture_instances

Insert:

- activity_logs

---

### Automatic Business Rules

- Past lecture instances remain unchanged to preserve attendance history.
- Only future lecture instances are removed.

---

# 5.4 Attendance Management

Attendance is stored directly inside Lecture Instances.

No separate attendance table exists.

---

## Mark Attendance

### Purpose

Records attendance for a lecture.

---

### Flow

```
User Marks Attendance
        │
        ▼
Update Lecture Instance
        │
       ▼
Resolve Review Queue Item
(if present)
        │
        ▼
Create Activity Log
```

---

### Database Operations

Update:

- lecture_instances

Optional Update:

- review_queue

Insert:

- activity_logs

---

### Automatic Business Rules

- Attendance percentage is recalculated dynamically.
- Safe Skip is recalculated dynamically.
- Dashboard statistics refresh automatically.

---

## Mark Whole Day

### Purpose

Marks every lecture of a day together.

---

### Flow

```
User Marks Whole Day
        │
        ▼
Update Lecture Instances
        │
        ▼
Resolve Related Reviews
        │
        ▼
Create Activity Log
```

---

### Database Operations

Bulk Update:

- lecture_instances

Bulk Update:

- review_queue

Insert:

- activity_logs

---

### Automatic Business Rules

- Only scheduled lectures are modified.
- Holiday and cancelled lectures remain unchanged.

---

# 5.5 Holiday Management

Holidays remove lectures from attendance calculations.

---

## Create Holiday

### Purpose

Adds a university holiday.

---

### Flow

```
Holiday Added
        │
        ▼
Insert Holiday
        │
        ▼
Update Lecture Instances
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert:

- holidays

Update:

- lecture_instances

Insert:

- activity_logs

---

### Automatic Business Rules

- Matching Lecture Instances become:

```
lecture_status = holiday
```

- Holiday lectures are excluded from attendance calculations.

---

## Delete Holiday

### Purpose

Removes a holiday.

---

### Flow

```
Delete Holiday
        │
        ▼
Restore Lecture Status
        │
        ▼
Create Activity Log
```

---

### Database Operations

Delete:

- holidays

Update:

- lecture_instances

Insert:

- activity_logs

---

### Automatic Business Rules

- Matching Lecture Instances return to:

```
lecture_status = scheduled
```

- Attendance calculations automatically include these lectures again.

---

# End of Part 2

The next section continues with:

- To-Do Module
- Notes Repository
- Review Queue



# 6. To-Do Module Business Flow

The To-Do Module manages reminder tasks.

Unlike academic data, To-Do items are global and are independent of semesters.

---

# 6.1 Create To-Do

## Purpose

Creates a new reminder task.

---

### Flow

```
User Creates To-Do
        │
        ▼
Validate Input
        │
        ▼
Insert To-Do
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert into:

- todos
- activity_logs

---

### Automatic Business Rules

- If no category is selected, category defaults to `other`.
- If no priority is selected, priority defaults to `medium`.
- Due date is optional.

---

# 6.2 Edit To-Do

## Purpose

Updates an existing reminder.

---

### Flow

```
User Updates To-Do
        │
        ▼
Validate Input
        │
        ▼
Update To-Do
        │
        ▼
Resolve Review Queue Item
(if present)
        │
        ▼
Create Activity Log
```

---

### Database Operations

Update:

- todos

Optional Update:

- review_queue

Insert:

- activity_logs

---

### Automatic Business Rules

- Editing a task may resolve an associated Review Queue item.
- Overdue status is recalculated dynamically.

---

# 6.3 Complete To-Do

## Purpose

Marks a reminder as completed.

---

### Flow

```
Complete Task
        │
        ▼
Update Status
        │
        ▼
Store Completion Time
        │
        ▼
Create Activity Log
```

---

### Database Operations

Update:

- todos

Insert:

- activity_logs

---

### Automatic Business Rules

- Completion timestamp is recorded.
- Completed tasks remain stored.

---

# 6.4 Delete To-Do

## Purpose

Permanently removes a reminder.

---

### Flow

```
Delete Task
        │
        ▼
Confirmation
        │
        ▼
Delete Task
        │
        ▼
Create Activity Log
```

---

### Database Operations

Delete:

- todos

Insert:

- activity_logs

---

### Automatic Business Rules

- Deletion is permanent.
- Activity history remains available.

---

# 7. Notes Repository Business Flow

The Notes Repository stores user files using a three-level hierarchy.

```
Semester
      │
      ▼
Notes Subject
      │
      ▼
Notes Section
      │
      ▼
Notes Resource
```

Only metadata is stored in the database.

Actual files are stored separately.

---

# 7.1 Create Notes Subject

## Purpose

Creates a top-level Notes folder.

---

### Flow

```
Create Notes Subject
        │
        ▼
Validate Name
        │
        ▼
Insert Notes Subject
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert:

- notes_subjects

Insert:

- activity_logs

---

### Automatic Business Rules

- Academic Subjects automatically create Notes Subjects.
- Users may also create custom Notes Subjects.

---

# 7.2 Create Notes Section

## Purpose

Creates a section inside a Notes Subject.

---

### Flow

```
Create Section
        │
        ▼
Validate Name
        │
        ▼
Insert Section
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert:

- notes_sections

Insert:

- activity_logs

---

### Automatic Business Rules

- Duplicate section names are not allowed within the same Notes Subject.

---

# 7.3 Upload Resource

## Purpose

Stores a file inside the Notes Repository.

---

### Flow

```
User Selects File
        │
        ▼
Upload File
        │
        ▼
Store Resource Metadata
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert:

- notes_resources

Insert:

- activity_logs

---

### Automatic Business Rules

- Only metadata is stored in the database.
- Physical files are stored separately.
- Upload may originate from the mobile application or the WhatsApp Bot.

---

# 7.4 Download Resource

## Purpose

Downloads a resource.

---

### Flow

```
User Downloads File
        │
        ▼
Retrieve Resource Metadata
        │
        ▼
Download File
        │
        ▼
Create Activity Log
```

---

### Database Operations

Read:

- notes_resources

Insert:

- activity_logs

---

### Automatic Business Rules

- Download location is determined using `app_settings`.
- Download status is intentionally not stored.

---

# 7.5 Delete Resource

## Purpose

Deletes a stored resource.

---

### Flow

```
Delete Resource
        │
        ▼
Delete Metadata
        │
        ▼
Delete Physical File
        │
        ▼
Create Activity Log
```

---

### Database Operations

Delete:

- notes_resources

Insert:

- activity_logs

---

### Automatic Business Rules

- Metadata is removed from the database.
- The application deletes the corresponding physical file.

---

# 8. Review Queue Business Flow

The Review Queue handles situations requiring manual user confirmation.

---

# 8.1 Create Review Item

## Purpose

Creates a Review Queue entry.

---

### Flow

```
Application Detects Ambiguity
        │
        ▼
Create Review Queue Item
        │
        ▼
Create Activity Log
```

---

### Database Operations

Insert:

- review_queue

Insert:

- activity_logs

---

### Automatic Business Rules

- Review Queue always references an existing entity.
- The referenced entity may already exist or may be updated later after user confirmation.
- Review items remain pending until resolved.

---

# 8.2 Resolve Review Item

## Purpose

Marks a Review Queue item as resolved.

---

### Flow

```
User Resolves Review
        │
        ▼
Update Original Entity
        │
        ▼
Update Review Status
        │
        ▼
Create Activity Log
```

---

### Database Operations

Update:

- Original Entity

Update:

- review_queue

Insert:

- activity_logs

---

### Automatic Business Rules

- Original entity is updated first.
- Review Queue status changes to `resolved`.
- Resolved items remain stored for historical reference.

---


# 9. Activity Timeline Business Flow

The Activity Timeline provides a chronological history of meaningful actions performed inside the application.

Unlike operational tables, Activity Logs are append-only and are never modified after creation.

---

# 9.1 Activity Log Creation

## Purpose

Records significant application events.

---

### Flow

```
Meaningful Operation
        │
        ▼
Determine Activity Details
        │
        ▼
Insert Activity Log
        │
        ▼
Operation Complete
```

---

### Database Operations

Insert:

- activity_logs

---

### Automatic Business Rules

- Every meaningful application action generates exactly one Activity Log.
- Activity Logs are append-only.
- Existing Activity Logs are never updated.
- Existing Activity Logs are never deleted.
- Activity Logs always reference an existing application entity.

---

# 9.2 Activity Timeline Display

## Purpose

Displays application history to the user.

---

### Flow

```
User Opens Activity Timeline
        │
        ▼
Retrieve Activity Logs
        │
        ▼
Sort By Timestamp
        │
        ▼
Display Timeline
```

---

### Database Operations

Read:

- activity_logs

---

### Automatic Business Rules

- Timeline is ordered chronologically.
- No data modification occurs.
- Timeline displays historical information only.

---

# 10. WhatsApp Bot Business Flow

The WhatsApp Bot acts as an alternative interaction layer for Student Buddy.

It performs the same logical operations as the mobile application while following the same business rules.

The bot never bypasses the application's validation or business logic.

---

# 10.1 Receive User Request

## Purpose

Receives a message from the user.

---

### Flow

```
User Sends Message
        │
        ▼
Interpret Intent
        │
        ▼
Validate Request
        │
        ▼
Execute Business Flow
```

---

### Automatic Business Rules

- The Bot never writes directly to the database.
- Every operation follows the same business flow as the mobile application.
- Validation rules remain identical across both interfaces.

---

# 10.2 Attendance Reminder

## Purpose

Collect attendance for scheduled lectures.

---

### Flow

```
Scheduled Lecture Ends
        │
        ▼
Send Attendance Prompt
        │
        ▼
Receive User Response
        │
        ▼
Update Lecture Instance
        │
        ▼
Create Activity Log
```

---

### Automatic Business Rules

- Attendance is stored in `lecture_instances`.
- If the user does not respond, attendance remains `unmarked`.
- Unmarked attendance may later create a Review Queue item.

---

# 10.3 To-Do Creation

## Purpose

Creates reminders through WhatsApp.

---

### Flow

```
Receive Reminder Request
        │
        ▼
Interpret Information
        │
        ▼
Create To-Do
        │
        ▼
Create Review Queue Item
(Optional)
        │
        ▼
Create Activity Log
```

---

### Automatic Business Rules

- Safe defaults are used whenever possible.
- Missing information requiring user confirmation creates a Review Queue item.
- The To-Do remains usable immediately.

---

# 10.4 Notes Upload

## Purpose

Stores documents sent through WhatsApp.

---

### Flow

```
Receive File
        │
        ▼
Determine Notes Location
        │
        ▼
Upload File
        │
        ▼
Store Metadata
        │
        ▼
Create Activity Log
```

---

### Automatic Business Rules

- Uploaded files follow the same Notes Repository hierarchy.
- File metadata is stored in the database.
- Physical files are stored separately.

---

# 11. Global Business Rules

The following rules apply throughout the entire application.

---

## 11.1 Single Source of Truth

Every entity has exactly one owning table.

Examples:

- Attendance → lecture_instances
- Timetable → lecture_templates
- To-Do → todos
- Notes → notes_resources
- Review Queue → review_queue
- Activity History → activity_logs

Duplicate storage of the same information should be avoided.

---

## 11.2 Runtime Calculations

The following values are never stored.

They are always calculated from existing data.

- Attendance Percentage
- Subject Attendance Percentage
- Overall Attendance Percentage
- Safe Skip
- Remaining Lectures
- Monthly Attendance Analytics
- Overdue Tasks

---

## 11.3 Review Queue

Review Queue stores only unresolved decisions.

It never becomes the owner of application data.

Resolved Review Queue items remain available for historical reference.

---

## 11.4 Activity Timeline

Activity Logs form the application's permanent history.

The Activity Timeline is generated directly from Activity Logs.

---

## 11.5 Offline First

All business logic remains identical whether the application is online or offline.

Synchronization with the cloud database is documented separately.

---

## 11.6 Automatic Operations

The following operations occur automatically.

- Creating a Subject creates a matching Notes Subject.
- Creating a Holiday updates Lecture Instances.
- Removing a Holiday restores affected Lecture Instances.
- Creating or updating significant records generates an Activity Log.
- Resolving Review Queue items updates the referenced entity.

---

## 11.7 Data Ownership

Business rules should always modify the owning table.

Examples:

- Attendance modifications update `lecture_instances`.
- Notes uploads update `notes_resources`.
- To-Do edits update `todos`.

Related tables may be updated automatically when required by business rules.

---

# 12. Deferred Finance Module

The Finance Module has intentionally been excluded from this version of the Business Flow document.

It will be documented separately after the Finance module is finalized.

Future flows will include:

- Account Management
- Category Management
- Income
- Expense
- Transfer
- Budget Management
- Finance Review Queue
- Finance Activity Logs

---

# End of Database Business Flow Document