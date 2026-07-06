# Student Buddy Database Schema
Version: 1.0 (Pre-Finance Module)

---

# 1. Introduction

This document defines the complete database schema for the Student Buddy application (excluding the Finance module). It serves as the primary reference for backend development, database implementation, API design, synchronization logic, and future maintenance.

The schema has been designed around the following principles:

- Normalized relational database design
- Offline-first architecture
- PostgreSQL as the cloud database
- SQLite as the local offline database
- WhatsApp Bot integration
- AI-ready architecture
- Modular and scalable design

The Finance module has intentionally been excluded from this version and will be documented separately once finalized.

---

# 2. Database Design Principles

## 2.1 Normalization

The database follows normalization principles to eliminate unnecessary duplication and maintain consistency.

Data is stored only once wherever possible, and calculated values are generally computed at runtime instead of being permanently stored.

---

## 2.2 Single Responsibility

Each table is responsible for only one entity.

Examples:

- Subjects store only academic subjects.
- Notes Repository stores only notes.
- Review Queue stores only unresolved user decisions.
- Activity Logs store only immutable history.

Modules remain independent wherever possible.

---

## 2.3 Offline First

The application is designed to work without internet connectivity.

SQLite stores the local copy of the database.

Supabase PostgreSQL acts as the cloud database used for synchronization.

Synchronization strategy is documented separately.

---

## 2.4 AI Ready

The schema has been designed keeping future AI integration in mind.

Two dedicated tables support AI functionality:

- Review Queue
- Activity Logs

These allow AI agents to understand user behavior and request manual confirmation whenever required.

---

## 2.5 Runtime Calculations

Values that can be derived from existing data are intentionally not stored.

Examples include:

- Attendance Percentage
- Safe Skip Calculation
- Remaining Lectures
- Overdue To-Do Status

These values are calculated dynamically whenever required.

---

## 2.6 Append-Only History

Activity history is never modified.

Instead of updating previous records, new activity entries are created.

This provides:

- Complete audit history
- AI learning context
- Easier debugging
- Better analytics

---

# 3. Database Modules

The database is divided into the following logical modules.

## Global Module

- app_settings
- activity_logs

---

## Academic Module

- semesters
- subjects
- lecture_templates
- lecture_instances
- attendance_settings
- holidays

---

## To-Do Module

- todos

---

## Notes Repository Module

- notes_subjects
- notes_sections
- notes_resources

---

## AI Module

- review_queue

---

## Finance Module (Future)

The following tables will be designed later.

- finance_accounts
- finance_categories
- finance_transactions
- finance_settings
- finance_budgets (optional)

---

# 4. Global Module

The Global Module contains tables that affect the entire application rather than any individual feature.

---

# 4.1 app_settings

## Purpose

Stores global application settings.

Exactly one record exists in this table.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| settings_id | SMALLINT (PK) |
| active_semester_id | UUID (FK) |
| theme_mode | ENUM |
| finance_enabled | BOOLEAN |
| morning_digest_enabled | BOOLEAN |
| night_digest_enabled | BOOLEAN |
| attendance_prompt_enabled | BOOLEAN |
| notes_download_directory | TEXT |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Enum

#### theme_mode

```
light
dark
system
```

---

### Constraints

Primary Key

```
settings_id
```

Check Constraint

```
settings_id = 1
```

Foreign Key

```
active_semester_id

REFERENCES semesters(semester_id)

ON DELETE RESTRICT
```

---

### Business Rules

- Only one row exists in this table.
- The active semester is determined using `active_semester_id`.
- Finance Module is disabled by default.
- Theme Mode defaults to `system`.
- All global application preferences are stored here.
- Deleting the active semester is prevented until another semester is selected.

---

# 4.2 activity_logs

## Purpose

Stores an immutable audit trail of all meaningful application events.

The table acts as:

- Activity Timeline
- AI Context Memory
- Debug Log
- Audit Trail
- User Behaviour History

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| activity_id | UUID (PK) |
| actor_type | ENUM |
| entity_type | ENUM |
| entity_id | UUID |
| action_type | ENUM |
| activity_message | TEXT |
| created_at | TIMESTAMPTZ |

---

### Enums

#### actor_type

```
user
bot
review_queue
system
```

---

#### entity_type

```
semester
subject
attendance
holiday
todo
notes
review_queue
finance
settings
```

---

#### action_type

```
created
updated
deleted
completed
resolved
downloaded
uploaded
marked_present
marked_absent
marked_holiday
```

---

### Constraints

Primary Key

```
activity_id
```

No Foreign Keys are enforced because the table uses polymorphic references through `entity_type` and `entity_id`.

---

### Business Rules

- Every meaningful application action creates one activity log.
- Activity Logs are append-only.
- Existing records are never modified.
- Existing records are never deleted.
- Activity Logs reference existing entities using (`entity_type`, `entity_id`).
- This table provides context for future AI features.
- This table powers the Activity Timeline screen.
- Used for debugging, analytics, and auditing.

---


# 5. Academic Module

The Academic Module manages the semester structure, timetable, attendance, and university holidays.

This module consists of six tables:

- semesters
- subjects
- lecture_templates
- lecture_instances
- attendance_settings
- holidays

---

# 5.1 semesters

## Purpose

Stores all academic semesters created by the user.

The currently active semester is determined by the `app_settings` table.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| semester_id | UUID (PK) |
| semester_number | INTEGER |
| start_date | DATE |
| end_date | DATE |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Constraints

Primary Key

```
semester_id
```

Unique Constraint

```
semester_number
```

Check Constraint

```
semester_number > 0
```

---

### Business Rules

- Semester numbers are unique.
- Semester numbers are used internally throughout the application.
- Active semester is determined using `app_settings.active_semester_id`.
- Users may create or delete semesters.
- Deleting a semester deletes all semester-specific academic and notes data through cascading relationships.

---

# 5.2 subjects

## Purpose

Stores all academic subjects belonging to a semester.

Subjects are used by the Timetable and Attendance modules.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| subject_id | UUID (PK) |
| semester_id | UUID (FK) |
| subject_name | VARCHAR(100) |
| faculty_name | VARCHAR(100) |
| theme_color | VARCHAR(7) |
| attendance_goal | SMALLINT |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Constraints

Primary Key

```
subject_id
```

Foreign Key

```
semester_id

REFERENCES semesters(semester_id)

ON DELETE CASCADE
```

Unique Constraint

```
(semester_id, subject_name)
```

Check Constraint

```
attendance_goal BETWEEN 1 AND 100
```

---

### Business Rules

- Every subject belongs to exactly one semester.
- Subject names are editable.
- Faculty name is optional.
- Theme color is stored as a HEX value.
- Attendance goal is stored per subject.
- Room information is intentionally not stored in this table.
- Whenever an academic subject is created, a Notes Subject with the same name is automatically created inside the Notes Repository.
- Notes Subjects are created through application logic and are not linked using foreign keys.

---

# 5.3 lecture_templates

## Purpose

Stores the recurring weekly timetable.

Each template represents one recurring lecture.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| lecture_template_id | UUID (PK) |
| subject_id | UUID (FK) |
| day_of_week | SMALLINT |
| start_time | TIME |
| end_time | TIME |
| room | VARCHAR(50) |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Constraints

Primary Key

```
lecture_template_id
```

Foreign Key

```
subject_id

REFERENCES subjects(subject_id)

ON DELETE CASCADE
```

Unique Constraint

```
(subject_id, day_of_week, start_time)
```

Check Constraints

```
day_of_week BETWEEN 1 AND 7
```

```
start_time < end_time
```

---

### Business Rules

- Represents recurring lectures.
- Each recurring lecture belongs to exactly one subject.
- Room information is stored here because it generally remains constant for recurring lectures.
- Attendance information is never stored in this table.

---

# 5.4 lecture_instances

## Purpose

Stores every lecture occurrence generated for a semester.

Attendance is recorded directly in this table.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| lecture_instance_id | UUID (PK) |
| lecture_template_id | UUID (FK) |
| lecture_date | DATE |
| lecture_status | ENUM |
| attendance_status | ENUM |
| marked_by | ENUM |
| marked_at | TIMESTAMPTZ |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Enums

#### lecture_status

```
scheduled
holiday
cancelled
```

---

#### attendance_status

```
unmarked
present
absent
```

---

#### marked_by

```
user
bot
review_queue
```

---

### Constraints

Primary Key

```
lecture_instance_id
```

Foreign Key

```
lecture_template_id

REFERENCES lecture_templates(lecture_template_id)

ON DELETE CASCADE
```

---

### Business Rules

- Lecture instances are automatically generated for the entire semester.
- Attendance is stored directly in this table.
- Only lectures with `lecture_status = scheduled` are included in attendance calculations.
- Holidays update the lecture status to `holiday`.
- Cancelled lectures update the lecture status to `cancelled`.

---

# 5.5 attendance_settings

## Purpose

Stores attendance calculation preferences for each semester.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| attendance_settings_id | UUID (PK) |
| semester_id | UUID (FK) |
| criteria_mode | ENUM |
| overall_attendance_goal | SMALLINT |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Enum

#### criteria_mode

```
overall
subject
custom
```

---

### Constraints

Primary Key

```
attendance_settings_id
```

Foreign Key

```
semester_id

REFERENCES semesters(semester_id)

ON DELETE CASCADE
```

Unique Constraint

```
semester_id
```

Check Constraint

```
overall_attendance_goal BETWEEN 1 AND 100
OR overall_attendance_goal IS NULL
```

---

### Business Rules

- Each semester has exactly one attendance settings record.
- Overall Mode calculates attendance using all scheduled lectures.
- Subject Mode applies one attendance goal to every subject.
- Custom Mode uses the attendance goal stored in the `subjects` table.
- Overall attendance goal is ignored when Custom Mode is selected.
- In Custom Mode, overall_attendance_goal is ignored because each subject uses its own attendance_goal.

---

# 5.6 holidays

## Purpose

Stores university and manually added holidays.

Holiday records automatically affect lecture instances occurring on the same date.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| holiday_id | UUID (PK) |
| semester_id | UUID (FK) |
| holiday_date | DATE |
| holiday_name | VARCHAR(100) |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Constraints

Primary Key

```
holiday_id
```

Foreign Key

```
semester_id

REFERENCES semesters(semester_id)

ON DELETE CASCADE
```

Unique Constraint

```
(semester_id, holiday_date)
```

---

### Business Rules

- Holidays may be added manually or imported using OCR.
- OCR is only a method of data entry and is not stored in the database.
- Adding a holiday updates all lecture instances on that date by setting `lecture_status = holiday`.
- Removing a holiday restores the affected lecture instances to `lecture_status = scheduled`.
- Holiday lectures are excluded from attendance calculations, safe skip calculations, remaining lecture calculations, and attendance analytics.

---


# 6. To-Do Module

The To-Do Module manages reminders and personal tasks.

Unlike the Academic Module, To-Do items are global and are not associated with any semester.

---

# 6.1 todos

## Purpose

Stores reminder tasks created either by the user, WhatsApp Bot, or Review Queue.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| todo_id | UUID (PK) |
| title | VARCHAR(255) |
| category | ENUM |
| priority | ENUM |
| due_datetime | TIMESTAMPTZ |
| status | ENUM |
| created_by | ENUM |
| completed_at | TIMESTAMPTZ |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Enums

#### category

```
academic
personal
work
health
other
```

---

#### priority

```
low
medium
high
```

---

#### status

```
pending
completed
```

---

#### created_by

```
user
bot
review_queue
```

---

### Constraints

Primary Key

```
todo_id
```

---

### Business Rules

- To-Do items are global and independent of semesters.
- Category defaults to `other`.
- Priority defaults to `medium`.
- Due date is optional.
- Overdue status is calculated dynamically.
- Completed tasks store the completion timestamp.
- Tasks may be permanently deleted.

---

# 7. Notes Repository Module

The Notes Repository stores user documents in a structured hierarchy.

Hierarchy:

```
Semester
    ↓
Notes Subject
    ↓
Notes Section
    ↓
Resource
```

Files themselves are stored in Supabase Storage.

Only their metadata is stored in PostgreSQL.

---

# 7.1 notes_subjects

## Purpose

Represents top-level folders inside the Notes Repository.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| notes_subject_id | UUID (PK) |
| semester_id | UUID (FK) |
| notes_subject_name | VARCHAR(100) |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Constraints

Primary Key

```
notes_subject_id
```

Foreign Key

```
semester_id

REFERENCES semesters(semester_id)

ON DELETE CASCADE
```

Unique Constraint

```
(semester_id, notes_subject_name)
```

---

### Business Rules

- Every Notes Subject belongs to one semester.
- Represents the top-level folders shown in the Notes Repository.
- Creating an academic subject automatically creates a Notes Subject with the same name.
- There is no foreign key relationship between Academic Subjects and Notes Subjects.
- Synchronization is handled entirely through application logic.
- Deleting an academic subject prompts the user whether the corresponding Notes Subject should also be deleted.

---

# 7.2 notes_sections

## Purpose

Represents folders inside a Notes Subject.

Examples:

- Unit 1
- Unit 2
- PYQs
- Assignments
- Lab Work

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| section_id | UUID (PK) |
| notes_subject_id | UUID (FK) |
| section_name | VARCHAR(100) |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Constraints

Primary Key

```
section_id
```

Foreign Key

```
notes_subject_id

REFERENCES notes_subjects(notes_subject_id)

ON DELETE CASCADE
```

Unique Constraint

```
(notes_subject_id, section_name)
```

---

### Business Rules

- Every section belongs to one Notes Subject.
- A Notes Subject can contain unlimited sections.
- Section names are editable.
- Deleting a section deletes all associated resources.

---

# 7.3 notes_resources

## Purpose

Stores metadata of uploaded resources.

Actual files are stored in Supabase Storage.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| resource_id | UUID (PK) |
| section_id | UUID (FK) |
| resource_name | VARCHAR(255) |
| file_name | VARCHAR(255) |
| file_extension | VARCHAR(20) |
| mime_type | VARCHAR(100) |
| file_size_bytes | BIGINT |
| storage_path | TEXT |
| uploaded_via | ENUM |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

---

### Enum

#### uploaded_via

```
app
whatsapp
```

---

### Constraints

Primary Key

```
resource_id
```

Foreign Key

```
section_id

REFERENCES notes_sections(section_id)

ON DELETE CASCADE
```

Unique Constraint

```
(section_id, file_name)
```

---

### Business Rules

- Every resource belongs to one Notes Section.
- Stores only metadata.
- Actual files are stored in Supabase Storage.
- Resources may be uploaded through the mobile application or the WhatsApp Bot.
- Device-specific information (download status, local file path, etc.) is intentionally not stored in the database.
- Deleting a resource removes its metadata from the database.
- The application is responsible for deleting the corresponding file from cloud storage.

---

# 8. Review Queue Module

The Review Queue stores unresolved decisions that require user intervention before the application can consider an operation complete.

The Review Queue never owns application data.

Instead, it references existing records using a polymorphic association.

---

# 8.1 review_queue

## Purpose

Stores unresolved decisions requiring manual verification by the user.

The Review Queue acts as a decision queue rather than a data storage table.

---

### Columns

| Column | PostgreSQL Type |
|----------|----------------|
| review_id | UUID (PK, Index) |
| review_type | ENUM |
| entity_type | ENUM |
| entity_id | UUID (Index) |
| review_message | TEXT |
| review_status | ENUM (Index) |
| resolved_by | ENUM (default: `user`) |
| created_at | TIMESTAMPTZ (Index) |
| resolved_at | TIMESTAMPTZ (nullable) |

---

### Enums

#### review_type

```
missing_information
confirmation_required
manual_review
```

---

#### entity_type

```
attendance
todo
finance
```

---

#### review_status

```
pending
resolved
```

---

#### resolved_by

```
user
system
admin
```

---

### Constraints

Primary Key

```
review_id
```

No Foreign Keys are enforced because the table uses a polymorphic reference through `entity_type` and `entity_id`.

---

### Indexes

| Column | Purpose |
|---|---|
| review_id | Primary key lookup |
| entity_id | Fast polymorphic entity lookup |
| review_status | Filter pending vs. resolved queue |
| created_at | Optimal ordering of pending queue (newest first) |

---

### Architectural Contract

> [!IMPORTANT]
> `entity_type` + `entity_id` **must always reference a valid, existing entity** at the time the review item is created. The service layer is responsible for verifying the entity exists before inserting a review item. No database-level foreign key is possible because the reference is polymorphic.
>
> **Review Queue never owns business data.** It only coordinates human verification of decisions made by automated systems (WhatsApp Bot, OCR, AI). All business data lives in the original entity tables (`todos`, `lecture_instances`, etc.).
>
> When a review item is resolved, the original entity is updated first, and the review status is then set to `resolved` atomically within a single transaction. If the entity update fails, the review status remains `pending`.

---

### Business Rules

- Review Queue never stores application data.
- Review Queue only references existing records.
- Every review item belongs to exactly one entity.
- The referenced entity is determined using (`entity_type`, `entity_id`).
- Attendance, To-Do and future Finance modules may create review items.
- Resolved review items are retained for historical reference.
- Review Queue serves as a manual decision layer between AI automation and the user.
- `resolved_by` records who performed the resolution: `user` (default), `system` (automated), or `admin` (administrative override).

---

# 9. Activity Logs Module

The Activity Logs module records every meaningful action performed inside the application.

The table acts as the application's immutable history.

---

# 9.1 activity_logs

## Purpose

Stores an append-only history of meaningful application events.

Used for:

- Activity Timeline
- Debugging
- AI Context
- User Behaviour Analysis
- Audit History

---

### Columns

| Column | PostgreSQL Type | Description |
|----------|----------------|-------------|
| activity_id | UUID (PK) | Unique identifier for the activity log |
| actor_type | ENUM | Type of actor performing the action (`activity_actor_type`) |
| entity_type | ENUM | Polymorphic type of the entity involved (`activity_entity_type`) |
| entity_id | UUID | Polymorphic ID of the entity involved |
| action_type | ENUM | Action performed on the entity (`activity_action_type`) |
| activity_message | TEXT | Human-readable log message describing the activity |
| correlation_id | UUID | Optional correlation ID to trace related events (e.g., WhatsApp bot interaction -> review queue -> update -> log) |
| created_at | TIMESTAMPTZ | Timestamp when the activity was logged |

---

### Indexes

| Column | Purpose |
|---|---|
| activity_id | Primary key lookup |
| actor_type | Filter timeline by actor (user vs. bot/system) |
| entity_type | Filter timeline by entity type |
| entity_id | Retrieve audit trail for a specific entity |
| action_type | Filter logs by action |
| correlation_id | Correlate events belonging to a single request/message flow |
| created_at | Fast ordering of activity timeline (newest first) |

---

### Enums

#### actor_type

```
user
bot
review_queue
system
```

---

#### entity_type

```
semester
subject
attendance
holiday
todo
notes
review_queue
finance
settings
```

---

#### action_type

```
created
updated
deleted
completed
resolved
downloaded
uploaded
marked_present
marked_absent
marked_holiday
```

---

### Constraints

Primary Key

```
activity_id
```

No Foreign Keys are enforced because the table uses polymorphic references through `entity_type` and `entity_id`.

---

### Business Rules

- Every meaningful application action creates one activity log.
- Activity Logs are append-only.
- Existing records are never updated.
- Existing records are never deleted.
- Activity Logs reference application entities using (`entity_type`, `entity_id`).
- Activity Logs provide context for future AI features.
- Activity Logs power the Activity Timeline screen.
- Used for analytics, debugging and auditing.

---

# 10. Global Business Rules

The following rules apply across multiple modules of the application.

---

## 10.1 Semester Management

- Every academic subject belongs to exactly one semester.
- Every Notes Subject belongs to exactly one semester.
- Every holiday belongs to exactly one semester.
- Every semester has exactly one attendance settings record.
- Active semester is determined only by the `app_settings` table.

---

## 10.2 Attendance

- Attendance percentages are calculated dynamically.
- Safe Skip calculations are calculated dynamically.
- Remaining lecture calculations are calculated dynamically.
- Only lectures with `lecture_status = scheduled` are included in attendance calculations.
- Holiday and cancelled lectures are excluded from attendance calculations.

---

## 10.3 Notes Repository

- Creating an Academic Subject automatically creates a Notes Subject having the same name.
- This synchronization is handled through application logic.
- No foreign key relationship exists between Academic Subjects and Notes Subjects.

---

## 10.4 Activity Logs

- Every significant operation performed by the application generates an Activity Log.
- Activity Logs are immutable.

---

## 10.5 Review Queue

- Review Queue stores references rather than data.
- User decisions update the original entity.
- Review Queue items are retained after resolution for historical reference.

---

## 10.6 Runtime Calculations

The following values are intentionally not stored in the database.

They are calculated whenever required.

- Attendance Percentage
- Overall Attendance Percentage
- Subject Attendance Percentage
- Safe Skip Count
- Remaining Lectures
- Monthly Attendance Analytics
- Overdue To-Do Status

---

# 11. Deferred Finance Module

The Finance Module has intentionally been excluded from this version of the database schema.

The following tables will be documented separately.

- finance_accounts
- finance_categories
- finance_transactions
- finance_settings
- finance_budgets (optional)

The existing schema has been designed such that the Finance Module can be integrated without requiring modifications to the current database structure.

---

# End of Database Schema Document