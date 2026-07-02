# Student Buddy Database Synchronization Strategy
Version: 1.0 (Pre-Finance Module)

---

# 1. Introduction

This document defines the synchronization strategy used by the Student Buddy application.

Unlike the Database Schema document, which defines how data is stored, and the Database Business Flow document, which defines how data moves inside the application, this document explains how data remains synchronized between the local SQLite database and the cloud PostgreSQL database hosted on Supabase.

The synchronization strategy has been designed around an Offline-First architecture, ensuring that the application remains fully functional even when internet connectivity is unavailable.

The Finance Module has intentionally been excluded from this version and will be documented separately after its implementation.

---

# 2. Offline-First Philosophy

Student Buddy follows an Offline-First architecture.

The mobile application should never depend on internet connectivity for normal operation.

All user interactions occur using the local SQLite database.

Internet connectivity is used only for synchronization with the cloud database.

This approach provides:

- Faster application performance
- Reliable operation without internet
- Reduced server dependency
- Better user experience
- Simplified application architecture

---

# 3. Core Architecture

The synchronization architecture consists of four independent components.

```
                ┌──────────────────────┐
                │     Flutter App      │
                └──────────┬───────────┘
                           │
                  Always Read & Write
                           │
                           ▼
                ┌──────────────────────┐
                │        SQLite        │
                └──────────┬───────────┘
                           ▲
                           │
                 Synchronization Engine
                           │
                           ▼
                ┌──────────────────────┐
                │      Supabase        │
                └──────────┬───────────┘
                           ▲
                           │
                     WhatsApp Bot
```

---

The architecture follows one important principle:

> The Flutter application never communicates directly with Supabase.

Instead:

Flutter → SQLite

Synchronization Engine → SQLite ⇄ Supabase

WhatsApp Bot → Supabase

---

# 4. System Components

The synchronization architecture contains four major components.

---

## 4.1 Flutter Application

Responsibilities:

- User Interface
- Local Database Operations
- Reading Data
- Writing Data

The Flutter application communicates only with SQLite.

It never directly modifies the cloud database.

---

## 4.2 SQLite Database

SQLite is the primary database used by the mobile application.

Responsibilities:

- Local Data Storage
- Offline Operation
- Fast Read Operations
- Fast Write Operations

Every user action is immediately stored inside SQLite regardless of internet availability.

SQLite acts as the operational source of truth for the mobile application.

Supabase acts as the operational source of truth for cloud services such as the WhatsApp Bot.

The Synchronization Engine is responsible for maintaining consistency between both databases.

---

## 4.3 Supabase PostgreSQL

Supabase stores the cloud copy of the application database.

Responsibilities:

- Cloud Backup
- Multi-device Synchronization (Future)
- WhatsApp Bot Data Access
- Long-term Data Persistence

Supabase is never accessed directly by the Flutter application.

Supabase acts as the source of truth for all cloud-based services.

---

## 4.4 Synchronization Engine

The Synchronization Engine is responsible for keeping SQLite and Supabase synchronized.

It is the only component allowed to communicate with both databases.

Responsibilities:

- Upload Local Changes
- Download Cloud Changes
- Detect Conflicts
- Resolve Conflicts
- Retry Failed Synchronizations
- Maintain Database Consistency
- Maintain Sync Metadata

Neither Flutter nor the WhatsApp Bot performs synchronization directly.

---

# 5. SQLite First Policy

Student Buddy follows a strict SQLite First Policy.

Every modification made through the mobile application is written to SQLite before any synchronization occurs.

This policy applies only to operations initiated from the mobile application. Cloud-originated operations (such as WhatsApp Bot interactions) are first written to Supabase and later synchronized to SQLite.

This rule applies regardless of internet availability.

Even when internet connectivity exists, the mobile application does not bypass SQLite.

Instead, synchronization occurs later through the Synchronization Engine.

---

## Mobile Application Flow

```
User Action
      │
      ▼
SQLite Update
      │
      ▼
UI Refresh
      │
      ▼
Synchronization Engine
      │
      ▼
Supabase
```

The user interface always reflects the local SQLite database.

---

## WhatsApp Bot Flow

```
WhatsApp Message
        │
        ▼
Supabase Update
        │
        ▼
Synchronization Engine
        │
        ▼
SQLite Update
        │
        ▼
Mobile Application Refresh
```

The WhatsApp Bot never communicates with SQLite.

---

# 6. General Synchronization Principles

The following principles apply throughout the application.

---

## Principle 1

SQLite is always the source of truth for the mobile application.

---

## Principle 2

Supabase is always the source of truth for cloud services.

---

## Principle 3

The Synchronization Engine is the only component allowed to communicate with both databases.

---

## Principle 4

Every database operation must succeed locally before synchronization begins.

---

## Principle 5

Loss of internet connectivity must never interrupt normal application usage.

---

## Principle 6

Synchronization must occur in the background without interrupting the user.

---

## Principle 7

The user interface always reads data from SQLite.

The UI never waits for cloud synchronization.

---

## Principle 8

Synchronization failures must never result in data loss.

Failed synchronization attempts are retried later.

---

## Principle 9

Business logic remains identical regardless of internet availability.

Only the synchronization process changes.

---

## Principle 10

The mobile application remains fully functional without internet.

The only unavailable functionality during offline mode is the WhatsApp Bot, since WhatsApp requires an internet connection.

---

# 7. Upload Synchronization

Upload Synchronization transfers locally modified data from SQLite to Supabase.

This process is performed only by the Synchronization Engine.

Neither the Flutter application nor the WhatsApp Bot performs upload synchronization directly.

---

## Upload Flow

```
User Performs Action
        │
        ▼
SQLite Updated
        │
        ▼
Synchronization Triggered
        │
        ▼
Synchronization Engine
        │
        ▼
Upload Changes
        │
        ▼
Supabase Updated
        │
        ▼
Synchronization Complete
```

---

## Upload Principles

### Principle 1

SQLite is always updated before synchronization begins.

---

### Principle 2

The user interface never waits for cloud synchronization.

The application remains responsive regardless of internet speed.

---

### Principle 3

Only modified records are uploaded.

Entire tables are never synchronized.

---

### Principle 4

Upload synchronization occurs in the background.

Users may continue using the application during synchronization.

---

### Principle 5

Successful uploads never modify SQLite.

SQLite already contains the latest local state.

---

# 8. Download Synchronization

Download Synchronization transfers cloud changes from Supabase to SQLite.

These changes may originate from:

- WhatsApp Bot
- Future Web Portal
- Future Multi-device Support

---

## Download Flow

```
Cloud Data Changed
        │
        ▼
Synchronization Triggered
        │
        ▼
Synchronization Engine
        │
        ▼
Download Changes
        │
        ▼
Update SQLite
        │
        ▼
Refresh User Interface
```

---

## Download Principles

### Principle 1

Only modified cloud records are downloaded.

---

### Principle 2

The mobile application continues using SQLite during synchronization.

---

### Principle 3

User interface refresh occurs only after SQLite has been updated.

---

### Principle 4

Downloaded records follow the same validation rules as locally created records.

---

### Principle 5

Downloaded changes may affect multiple application modules simultaneously.

For example:

- Attendance
- To-Do
- Notes Repository
- Review Queue

---

# 9. Synchronization Triggers

Synchronization does not occur continuously.

Instead, it begins only when one of the following events occurs.

---

## Trigger 1 — Internet Connection Restored

```
Offline
      │
Internet Available
      │
      ▼
Start Synchronization
```

Purpose

Synchronize all pending local changes.

Download cloud updates.

---

## Trigger 2 — Application Startup

```
Launch App
      │
Internet Available
      │
      ▼
Start Synchronization
```

Purpose

Ensure the local database contains the latest cloud data before normal usage continues.

---

## Trigger 3 — Local Data Modification (While Online)

```
SQLite Updated
      │
Internet Available
      │
      ▼
Schedule Background Synchronization
```

Purpose

Upload newly created or modified records.

The upload should occur asynchronously without blocking the user interface.

---

## Trigger 4 — Cloud Data Modification

```
WhatsApp Bot
        │
Updates Supabase
        │
        ▼
Synchronization Engine
        │
        ▼
Download Latest Changes
```

Purpose

Keep SQLite synchronized with changes originating from cloud services.

---

## Trigger 5 — Manual Synchronization

Future Feature

The application may later provide a manual "Sync Now" option inside Settings.

This trigger simply starts the normal synchronization process.

No additional synchronization logic is introduced.

---

## Trigger 6 — Periodic Background Synchronization

Future Feature

While the application is active and internet connectivity is available, periodic background synchronization may be performed.

The synchronization interval is implementation-specific and is intentionally not defined in this document.

---

# 10. Background Synchronization Engine

The Synchronization Engine is responsible for coordinating every synchronization cycle.

---

## Responsibilities

- Detect local changes
- Detect cloud changes
- Upload local modifications
- Download cloud modifications
- Maintain synchronization metadata
- Resolve synchronization conflicts
- Retry failed synchronizations
- Preserve database consistency

---

## Background Synchronization Cycle

```
Synchronization Starts
          │
          ▼
Check Internet
          │
          ▼
Upload Local Changes
(Resolve conflicts if required)
          │
          ▼
Download Cloud Changes
(Resolve conflicts if required)
          │
          ▼
Update Synchronization Metadata
          │
          ▼
Refresh User Interface
          │
          ▼
Synchronization Complete
```

---

## Synchronization Principles

- Only the Synchronization Engine communicates with both databases.
- Synchronization is transparent to the user.
- Synchronization must never block normal application usage.
- Synchronization failures never prevent local database operations.
- The application always remains usable regardless of synchronization status.

---

# 11. Conflict Resolution Strategy

A synchronization conflict occurs when the same entity has been modified independently in both SQLite and Supabase before synchronization completes.

The Synchronization Engine is responsible for detecting and resolving these conflicts.

Conflict resolution must never result in silent data loss.

---

## General Conflict Resolution Principles

### Principle 1

Synchronization always uploads local changes before downloading cloud changes.

This preserves the user's most recent work performed through the mobile application.

---

### Principle 2

Every conflict must be resolved deterministically.

The same inputs should always produce the same result.

---

### Principle 3

Conflicts should never require user intervention unless automatic resolution could result in loss of important information.

---

### Principle 4

Successful conflict resolution creates an Activity Log.

---

## Conflict Types

The application currently expects the following conflict categories.

- Update vs Update
- Update vs Delete
- Delete vs Update

Future Finance conflicts will follow the same strategy.

---

## Conflict Resolution Rules

### Attendance

Attendance modifications performed through the mobile application take priority over cloud changes.

Reason:

Attendance is intended to be confirmed by the user and should not be silently overwritten.

---

### To-Do

If both copies are modified,

the record with the latest modification timestamp is retained.

---

### Notes Repository

Notes metadata follows the latest modification timestamp.

Uploaded files are never deleted automatically during conflict resolution.

---

### Review Queue

Resolved Review Queue items always take priority over pending ones.

---

### Activity Logs

Activity Logs never conflict.

New records are simply appended.

---

### App Settings

The most recently modified settings are retained.

---

# 12. Table-wise Synchronization Strategy

The following table defines how each database table participates in synchronization.

---

## semesters

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## subjects

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## lecture_templates

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## lecture_instances

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Local Attendance Updates Take Priority

---

## attendance_settings

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## holidays

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## todos

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## notes_subjects

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## notes_sections

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Latest Modification Wins

---

## notes_resources

SQLite

✓ Metadata

Supabase

✓ Metadata

Synchronization

Metadata Only

Conflict Strategy

Latest Modification Wins

Actual files are synchronized independently from metadata.

---

## review_queue

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Write

Synchronization

Bidirectional

Conflict Strategy

Resolved Status Takes Priority

---

## activity_logs

SQLite

✓ Read

✓ Write

Supabase

✓ Read

✓ Archive

Synchronization: didirectional(append only)

Conflict Strategy: not applicable

Business Rule:

Activity Logs are append-only.
Existing records are never updated.
Existing records are never deleted.
Synchronization only inserts missing records.

---

## app_settings

SQLite

✓ Read

✓ Write

Supabase

Not Stored

Synchronization

None

Application settings remain local to each device.

---

# 13. Synchronization Metadata

The Synchronization Engine maintains metadata required to track synchronization progress.

Examples include:

- Last Successful Synchronization
- Pending Local Changes
- Pending Cloud Changes
- Failed Synchronization Attempts

The implementation details of synchronization metadata are intentionally excluded from this document and will be defined during backend implementation.

---

# 14. Synchronization Failure Recovery

Synchronization failures are expected to occur due to temporary network issues, server maintenance or unexpected interruptions.

The application must recover gracefully without data loss.

---

## Failure Recovery Principles

### Principle 1

Local database operations must never fail because synchronization failed.

---

### Principle 2

Synchronization failures must never result in data loss.

---

### Principle 3

Failed synchronization attempts are retried automatically when appropriate.

---

### Principle 4

The user should continue using the application normally during synchronization failures.

---

## Failure Scenarios

### Scenario 1 — No Internet Connection

```
SQLite Updated
        │
        ▼
Synchronization Deferred
        │
        ▼
Continue Offline
```

Recovery

Synchronization begins automatically once internet connectivity is restored.

---

### Scenario 2 — Server Unavailable

```
SQLite Updated
        │
        ▼
Synchronization Attempt
        │
        ▼
Server Unavailable
        │
        ▼
Retry Later
```

Recovery

Synchronization retries automatically during the next synchronization cycle.

---

### Scenario 3 — Partial Synchronization

```
Upload Successful
        │
        ▼
Download Failed
```

Recovery

Only the incomplete portion of the synchronization process is retried.

Successfully synchronized records are never uploaded again.

---

### Scenario 4 — Application Closed During Synchronization

```
Synchronization Running
        │
        ▼
Application Closed
```

Recovery

Synchronization resumes during the next application launch.

---

## Recovery Principles

- No synchronized data should be uploaded again unnecessarily.
- Successfully synchronized records remain synchronized.
- Only pending operations are retried.
- User interaction is never blocked.

---

# 15. Security Considerations

The synchronization architecture must preserve data integrity and security.

---

## Principle 1

All communication between SQLite and Supabase must occur through secure encrypted connections.

---

## Principle 2

SQLite remains accessible only to the local application.

---

## Principle 3

Only authenticated cloud services may access Supabase.

---

## Principle 4

Synchronization must validate incoming data before applying database changes.

---

## Principle 5

Synchronization failures must never expose sensitive application data.

---

## Principle 6

The Synchronization Engine must never bypass application business rules.

Every synchronized record must satisfy the same validation rules as locally created records.

---

# 16. Future Improvements

The following features may be introduced in future versions.

---

## Multi-device Synchronization

Allow the same user account to synchronize multiple devices using Supabase.

---

## Manual Synchronization

Allow users to manually trigger synchronization from the Settings screen.

---

## Synchronization Status

Display:

- Last Synchronization Time
- Current Synchronization Status
- Pending Changes

inside the application.

---

## Background Synchronization Optimization

Perform intelligent synchronization by prioritizing frequently modified tables.

---

## Conflict History

Maintain a history of resolved synchronization conflicts for debugging and analytics.

---

## Incremental Synchronization

Synchronize only modified records instead of scanning complete tables.

---

# 17. Summary

The Student Buddy synchronization strategy follows an Offline-First architecture.

The architecture is based on the following principles.

---

## SQLite First Policy

All mobile application operations are performed on SQLite.

SQLite acts as the operational source of truth for the mobile application.

---

## Cloud Services

Cloud-based services such as the WhatsApp Bot interact only with Supabase.

Supabase acts as the operational source of truth for cloud services.

---

## Synchronization Engine

The Synchronization Engine is the only component permitted to communicate with both SQLite and Supabase.

Its responsibilities include:

- Upload Synchronization
- Download Synchronization
- Conflict Resolution
- Failure Recovery
- Synchronization Metadata Management
- Database Consistency

---

## Offline Operation

The application remains fully functional without internet connectivity.

Synchronization occurs automatically whenever connectivity becomes available.

---

## Data Consistency

Business rules remain identical regardless of internet availability.

Synchronization changes only where data is stored, never how the application behaves.

---

## Modular Architecture

The synchronization strategy has been designed so that future modules, including the Finance Module and multi-device support, can be integrated without changing the existing synchronization architecture.

---

# End of Database Synchronization Strategy
