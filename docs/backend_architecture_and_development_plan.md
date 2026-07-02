# Student Buddy Backend Architecture & Development Plan
Version: 1.0 (Pre-Finance Module)

---

# 1. Introduction

This document defines how the Student Buddy backend should be implemented.

Unlike the previous documentation, which defines the database schema, business flow and synchronization strategy, this document focuses on the actual implementation architecture.

Its purpose is to ensure that every backend component follows a single consistent design philosophy, making the project easy to maintain, extend and understand.

This document should be treated as the implementation blueprint for the FastAPI backend and the Flutter data layer.

The Finance Module has intentionally been excluded from this version and will be implemented after the core application becomes stable.

---

# 2. Backend Design Philosophy

Student Buddy follows a modular architecture.

Each module is developed independently while following common development standards.

Every module contains its own:

- Database Model
- Pydantic Schemas
- Repository
- Service
- API Router

Business logic should never be written directly inside API routes.

Similarly, database queries should never be written directly inside services.

Every layer has exactly one responsibility.

---

## Design Principles

### Principle 1

One module should be completely implemented before moving to the next module.

Example:

```
Semester

↓

Complete

↓

Subject

↓

Complete

↓

Lecture Templates
```

Never partially implement multiple modules simultaneously.

---

### Principle 2

Business logic belongs only inside the Service Layer.

API routes should only:

- Receive requests
- Validate input
- Call services
- Return responses

---

### Principle 3

Database access belongs only inside the Repository Layer.

Repositories should never contain business logic.

---

### Principle 4

Models represent database tables.

Schemas represent request and response validation.

Models and Schemas should never be mixed.

---

### Principle 5

Every module should be independently testable.

No module should directly depend on another module's internal implementation.

---

# 3. Overall Architecture

```
                Flutter Application
                        │
                        ▼
                 Repository Layer
                        │
                        ▼
                  API Client Layer
                        │
                        ▼
                     FastAPI
                        │
                        ▼
                  Service Layer
                        │
                        ▼
                Repository Layer
                        │
                        ▼
                  SQLAlchemy ORM
                        │
                        ▼
                PostgreSQL / SQLite
```

---

## Layer Responsibilities

### Flutter UI

Responsible for:

- User Interface
- Navigation
- User Interaction

Contains no business logic.

---

### Flutter Repository Layer

Responsible for:

- Communicating with SQLite
- Communicating with FastAPI
- Returning data to Providers

The UI never communicates directly with APIs.

---

### API Client Layer

Responsible for:

- HTTP Requests
- Authentication Headers
- Serialization
- Error Translation

Contains no business logic.

---

### FastAPI

Responsible for:

- Request Routing
- Authentication
- Validation
- Response Generation

Contains no business logic.

---

### Service Layer

Responsible for:

- Business Rules
- Cross-module Operations
- Automatic Actions

Examples:

- Create Notes Subject after creating Subject
- Update Lecture Instances after creating Holiday
- Resolve Review Queue items

---

### Repository Layer

Responsible for:

- Reading database records
- Creating records
- Updating records
- Deleting records

Contains no business logic.

---

### SQLAlchemy Models

Responsible only for database mapping.

No validation.

No business logic.

---

# 4. Technology Stack

## Backend

- Python 3.12+
- FastAPI
- SQLAlchemy 2.x
- Alembic
- Pydantic v2
- PostgreSQL (Supabase)

---

## Mobile Application

- Flutter
- Riverpod
- SQLite
- Dio (HTTP Client)

---

## Synchronization

- SQLite
- Supabase PostgreSQL

Following the SQLite First Policy documented in the Synchronization Strategy.

---

# 5. Backend Folder Structure

```
backend/

│
├── app/
│   │
│   ├── api/
│   │   └── v1/
│   │       ├── academic/
│   │       │   ├── semesters.py
│   │       │   ├── subjects.py
│   │       │   ├── lecture_templates.py
│   │       │   ├── lecture_instances.py
│   │       │   ├── attendance_settings.py
│   │       │   └── holidays.py
│   │       │
│   │       ├── notes/
│   │       │   └── notes.py
│   │       │
│   │       ├── todo/
│   │       │   └── todos.py
│   │       │
│   │       ├── review_queue/
│   │       │   └── review_queue.py
│   │       │
│   │       ├── settings/
│   │       │   └── app_settings.py
│   │       │
│   │       └── activity_logs/
│   │           └── activity_logs.py
│   │
│   ├── core/
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── logging.py
│   │   ├── security.py
│   │   ├── exceptions.py
│   │   └── constants.py
│   │
│   ├── models/
│   │   ├── academic/
│   │   ├── notes/
│   │   ├── todo/
│   │   ├── review_queue/
│   │   ├── settings/
│   │   └── activity_logs/
│   │
│   ├── schemas/
│   │   ├── academic/
│   │   ├── notes/
│   │   ├── todo/
│   │   ├── review_queue/
│   │   ├── settings/
│   │   └── activity_logs/
│   │
│   ├── repositories/
│   │   ├── academic/
│   │   ├── notes/
│   │   ├── todo/
│   │   ├── review_queue/
│   │   ├── settings/
│   │   └── activity_logs/
│   │
│   ├── services/
│   │   ├── academic/
│   │   ├── notes/
│   │   ├── todo/
│   │   ├── review_queue/
│   │   ├── settings/
│   │   └── activity_logs/
│   │
│   ├── dependencies/
│   │
│   ├── utils/
│   │
│   └── main.py
│
├── alembic/
│
├── tests/
│   ├── academic/
│   ├── notes/
│   ├── todo/
│   ├── review_queue/
│   ├── settings/
│   └── activity_logs/
│
├── requirements.txt
│
└── README.md
```

---

# 6. Flutter Folder Structure

Only the implementation-related folders are shown below.

```
lib/

core/
    constants/
    database/
    network/
    services/
    theme/
    utils/
    widgets/

data/
    api/
    database/
    dto/
    mappers/
    repositories/

domain/
    models/

providers/

screens/
```

The Flutter application is divided into three logical layers:

- Presentation Layer
- Data Layer
- Domain Layer

This separation keeps the UI independent from networking and storage implementations.

---

# 7. Layer Responsibilities

## Presentation Layer

Contains:

- Screens
- Widgets
- Providers

Responsible only for displaying data and handling user interaction.

---

## Domain Layer

Contains:

- Business Models

Represents the application's core entities.

Example:

```
Semester

Subject

Lecture Instance

Todo
```

These models are independent of SQLite and HTTP.

---

## Data Layer

Contains:

- API Clients
- SQLite Helpers
- DTOs
- Repositories

Responsible for obtaining data regardless of its source.

The rest of the application should not know whether data came from:

- SQLite
- FastAPI
- Future cloud services

---

# 8. Development Standards

Every module must follow the same implementation structure.

Each module should contain:

```
Database Model

↓

Pydantic Schemas

↓

Repository

↓

Service

↓

API Router

↓

Tests
```

Implementation should always proceed in this order.

---

## Naming Standards

Use singular names for:

- Models
- Services
- Repositories

Examples:

```
Semester

SemesterRepository

SemesterService
```

Use plural names for:

- API Routes

Example:

```
/api/v1/semesters
```

---

## General Rules

- Follow the Database Schema document.
- Follow the Business Flow document.
- Follow the Synchronization Strategy document.
- Do not duplicate business logic.
- Keep modules independent.
- Write reusable code.
- Maintain consistent naming conventions throughout the project.

---

# 9. Backend Module Development Order

The backend should be implemented module by module.

A module is considered complete only when all of the following components have been implemented.

- SQLAlchemy Model
- Pydantic Schemas
- Repository
- Service
- API Router
- Unit Tests
- Integration Tests
- Documentation

Only after completing one module should development proceed to the next.

---

## Official Development Order

```
1. Core Configuration

2. Semester

3. Subject

4. Lecture Template

5. Lecture Instance

6. Attendance Settings

7. Holiday

8. App Settings

9. Todo

10. Notes Repository

11. Review Queue

12. Activity Logs

13. Authentication

14. Synchronization Engine

15. WhatsApp Integration

16. AI Integration

17. Finance Module
```

This order follows the dependency hierarchy of the database.

No module should be implemented before its parent module.

---

# 10. Standard Module Structure

Every backend module must follow exactly the same structure.

Example:

```
Semester Module

│
├── Model
├── Schemas
├── Repository
├── Service
├── API
├── Tests
└── Documentation
```

Every future module should follow this template.

---

## Model

Responsible for:

- SQLAlchemy table mapping
- Relationships
- Constraints

Must never contain business logic.

---

## Schemas

Responsible for:

- Request validation
- Response serialization

Recommended schemas:

```
CreateSchema

UpdateSchema

ResponseSchema

ListResponseSchema
```

---

## Repository

Responsible for:

- CRUD operations
- Database queries
- Pagination
- Filtering

Repositories should never contain business logic.

---

## Service

Responsible for:

- Business Rules
- Validation beyond schema validation
- Cross-module operations
- Automatic operations

Examples

```
Create Subject

↓

Automatically create Notes Subject
```

or

```
Create Holiday

↓

Update Lecture Instances
```

These belong inside Services.

---

## API Router

Responsible only for:

- Receiving requests
- Calling Services
- Returning responses

Routes must remain thin.

---

## Tests

Every module should include:

- Repository Tests
- Service Tests
- API Tests

---

# 11. Semester Module

The Semester Module is the first functional module to be implemented.

All remaining academic modules depend on it.

---

## Responsibilities

- Create Semester
- Update Semester
- Delete Semester
- List Semesters
- Retrieve Semester
- Validate Semester Number uniqueness

---

## Database Tables

```
semesters
```

---

## API Endpoints

```
GET    /semesters

GET    /semesters/{id}

POST   /semesters

PUT    /semesters/{id}

DELETE /semesters/{id}
```

---

## Service Responsibilities

- Validate semester dates.
- Validate unique semester number.
- Create default Attendance Settings.
- Create Activity Log.

---

## Repository Responsibilities

- CRUD operations.
- Lookup by ID.
- Lookup by semester number.
- List semesters.

---

## Completion Checklist

```
✓ Model

✓ Schemas

✓ Repository

✓ Service

✓ API

✓ Tests
```

Only after every checkbox is complete should Subject Module begin.

---

# 12. Subject Module

The Subject Module manages academic subjects belonging to a semester.

---

## Responsibilities

- Create Subject
- Update Subject
- Delete Subject
- List Subjects
- Retrieve Subject

---

## Database Tables

```
subjects

notes_subjects
```

---

## API Endpoints

```
GET    /subjects

GET    /subjects/{id}

POST   /subjects

PUT    /subjects/{id}

DELETE /subjects/{id}
```

---

## Service Responsibilities

- Validate semester exists.
- Validate unique subject name within semester.
- Automatically create Notes Subject.
- Rename corresponding Notes Subject when Subject name changes.
- Prompt for Notes Subject deletion when Subject is deleted.
- Create Activity Log.

---

## Repository Responsibilities

- CRUD operations.
- List by semester.
- Lookup by ID.

---

## Completion Checklist

```
✓ Model

✓ Schemas

✓ Repository

✓ Service

✓ API

✓ Tests
```

---

# 13. Lecture Template Module

Lecture Templates define recurring weekly classes.

Attendance is not stored here.

---

## Responsibilities

- Create Template
- Update Template
- Delete Template
- List Templates

---

## Database Tables

```
lecture_templates
```

---

## API Endpoints

```
GET    /lecture-templates

GET    /lecture-templates/{id}

POST   /lecture-templates

PUT    /lecture-templates/{id}

DELETE /lecture-templates/{id}
```

---

## Service Responsibilities

- Validate subject exists.
- Validate lecture time.
- Validate day of week.
- Generate Lecture Instances for semester duration.
- Skip holidays during generation.
- Create Activity Log.

---

## Repository Responsibilities

- CRUD operations.
- List templates by subject.
- Lookup template.

---

## Completion Checklist

```
✓ Model

✓ Schemas

✓ Repository

✓ Service

✓ API

✓ Tests
```

---

# 14. Lecture Instance Module

Lecture Instances represent every individual lecture occurring during a semester.

Attendance is stored directly inside this table.

---

## Responsibilities

- Retrieve lecture instances.
- Retrieve today's lectures.
- Retrieve lecture history.
- Update attendance.
- Update lecture status.

---

## Database Tables

```
lecture_instances
```

---

## API Endpoints

```
GET /lecture-instances

GET /lecture-instances/today

GET /lecture-instances/{id}

PUT /lecture-instances/{id}

PUT /lecture-instances/day
```

---

## Service Responsibilities

- Mark attendance.
- Mark whole day.
- Return lecture data required for dashboard generation.
- Resolve Review Queue items.
- Create Activity Log.

---

## Repository Responsibilities

- Retrieve by date.
- Retrieve by subject.
- Retrieve by semester.
- Update attendance.
- Update lecture status.

---

## Completion Checklist

```
✓ Model

✓ Schemas

✓ Repository

✓ Service

✓ API

✓ Tests
```

---

# 15. Attendance Settings Module

The Attendance Settings module manages semester-level attendance configuration.

There is exactly one Attendance Settings record for every Semester.

---

## Responsibilities

- Retrieve Attendance Settings
- Update Attendance Settings
- Change Attendance Criteria Mode
- Update Overall Attendance Goal

---

## Database Tables

```
attendance_settings
```

---

## API Endpoints

```
GET    /attendance-settings

PUT    /attendance-settings
```

---

## Service Responsibilities

- Validate criteria mode.
- Validate attendance goals.
- Apply attendance configuration changes.
- Create Activity Log.

---

## Repository Responsibilities

- Retrieve settings by semester.
- Update settings.

---

## Completion Checklist

```
✓ Model
✓ Schemas
✓ Repository
✓ Service
✓ API
✓ Tests
```

---

# 16. Holiday Module

The Holiday Module manages semester holidays.

---

## Responsibilities

- Create Holiday
- Update Holiday
- Delete Holiday
- List Holidays

---

## Database Tables

```
holidays
```

---

## API Endpoints

```
GET    /holidays

GET    /holidays/{id}

POST   /holidays

PUT    /holidays/{id}

DELETE /holidays/{id}
```

---

## Service Responsibilities

- Validate holiday date.
- Prevent duplicate holidays.
- Update affected Lecture Instances.
- Restore Lecture Instances when holiday is removed.
- Create Activity Log.

---

## Repository Responsibilities

- CRUD operations.
- Retrieve by semester.
- Retrieve by date.

---

## Completion Checklist

```
✓ Model
✓ Schemas
✓ Repository
✓ Service
✓ API
✓ Tests
```

---

# 17. App Settings Module

The App Settings module stores application-wide preferences.

Only one App Settings record exists.

---

## Responsibilities

- Retrieve settings.
- Update settings.
- Change active semester.
- Enable or disable modules.

---

## Database Tables

```
app_settings
```

---

## API Endpoints

```
GET /app-settings

PUT /app-settings
```

---

## Service Responsibilities

- Validate active semester.
- Update preferences.
- Create Activity Log.

---

## Repository Responsibilities

- Retrieve settings.
- Update settings.

---

## Completion Checklist

```
✓ Model
✓ Schemas
✓ Repository
✓ Service
✓ API
✓ Tests
```

---

# 18. Todo Module

The Todo Module manages reminder tasks.

---

## Responsibilities

- Create Task
- Update Task
- Delete Task
- Complete Task
- Retrieve Tasks

---

## Database Tables

```
todos
```

---

## API Endpoints

```
GET    /todos

GET    /todos/{id}

POST   /todos

PUT    /todos/{id}

DELETE /todos/{id}

PUT    /todos/{id}/complete
```

---

## Service Responsibilities

- Validate task.
- Apply default values.
- Resolve Review Queue item when applicable.
- Create Activity Log.

---

## Repository Responsibilities

- CRUD operations.
- Retrieve pending tasks.
- Retrieve completed tasks.

---

## Completion Checklist

```
✓ Model
✓ Schemas
✓ Repository
✓ Service
✓ API
✓ Tests
```

---

# 19. Notes Repository Module

The Notes Repository is implemented as one module.

The following three tables are always implemented together.

```
notes_subjects

notes_sections

notes_resources
```

---

## Responsibilities

- Manage Notes Subjects
- Manage Notes Sections
- Upload Resources
- Retrieve Resources
- Delete Resources

---

## API Endpoints

```
GET

POST

PUT

DELETE
```

for:

- Notes Subjects
- Notes Sections
- Notes Resources

---

## Service Responsibilities

- Validate hierarchy.
- Upload metadata.
- Delete metadata.
- Coordinate storage service.
- Create Activity Log.

---

## Repository Responsibilities

- CRUD operations.
- Hierarchical retrieval.
- Search resources.

---

## Completion Checklist

```
✓ Model
✓ Schemas
✓ Repository
✓ Service
✓ API
✓ Tests
```

---

# 20. Review Queue Module

The Review Queue manages unresolved decisions.

---

## Responsibilities

- Retrieve pending items.
- Resolve item.
- Retrieve history.

---

## Database Tables

```
review_queue
```

---

## API Endpoints

```
GET    /review-queue

GET    /review-queue/{id}

PUT    /review-queue/{id}
```

---

## Service Responsibilities

- Update referenced entity.
- Mark review resolved.
- Create Activity Log.

---

## Repository Responsibilities

- Retrieve pending items.
- Retrieve resolved items.
- Update status.

---

## Completion Checklist

```
✓ Model
✓ Schemas
✓ Repository
✓ Service
✓ API
✓ Tests
```

---

# 21. Activity Logs Module

The Activity Logs module provides immutable application history.

---

## Responsibilities

- Retrieve logs.
- Filter logs.

No create/update/delete endpoints are exposed.

Activity Logs are generated internally.

---

## Database Tables

```
activity_logs
```

---

## API Endpoints

```
GET /activity-logs

GET /activity-logs/{id}
```

---

## Service Responsibilities

- Record application events.
- Filter history.
- Support Activity Timeline.

---

## Repository Responsibilities

- Insert logs.
- Retrieve logs.
- Filter logs.

---

## Completion Checklist

```
✓ Model
✓ Schemas
✓ Repository
✓ Service
✓ API
✓ Tests
```

---

# End of Part 3

The next section completes the backend implementation guide with:

- API Design Standards
- Repository Pattern
- Service Layer Rules
- Dependency Injection
- Error Handling
- Logging
- Validation
- Final Development Rules
- Backend Completion Checklist



# 22. API Design Standards

Every API in Student Buddy must follow a consistent design standard.

Consistency across all modules makes the backend easier to maintain and simplifies frontend development.

---

## REST Principles

Use RESTful endpoints.

Examples

```
GET    /subjects

POST   /subjects

GET    /subjects/{id}

PUT    /subjects/{id}

DELETE /subjects/{id}
```

Avoid verbs inside endpoint names.

Correct

```
POST /subjects
```

Incorrect

```
POST /createSubject
```

---

## HTTP Status Codes

Use standard HTTP status codes.

```
200 OK

201 Created

204 No Content

400 Bad Request

401 Unauthorized

403 Forbidden

404 Not Found

409 Conflict

422 Validation Error

500 Internal Server Error
```

---

## Standard API Response

Every successful response should follow the same structure.

```json
{
  "success": true,
  "message": "Operation completed successfully.",
  "data": {}
}
```

Every failed response should follow the same structure.

```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": []
}
```

This response format should be used consistently across every module.

---

# 23. Repository Pattern

Student Buddy follows the Repository Pattern.

Repositories are responsible only for database access.

---

## Responsibilities

Repositories may

- Create records
- Read records
- Update records
- Delete records
- Execute database queries

Repositories must never

- Validate business rules
- Perform calculations
- Trigger cross-module actions

---

## Example Flow

```
API

↓

Service

↓

Repository

↓

Database
```

Repositories never call Services.

Repositories never call other Repositories.

---

# 24. Service Layer Rules

The Service Layer contains all business logic.

It coordinates repositories and implements application behaviour.

---

## Responsibilities

Services may

- Validate business rules
- Coordinate multiple repositories
- Create Activity Logs
- Generate Review Queue items
- Trigger automatic operations

Services must never

- Execute raw SQL
- Return HTTP responses
- Know UI implementation details

---

## Example

```
Create Subject

↓

Subject Service

↓

Subject Repository

↓

Notes Repository

↓

Activity Log Repository
```

The Subject API communicates only with the Subject Service.

The Service coordinates the remaining repositories.

---

# 25. Dependency Injection

FastAPI dependency injection should be used throughout the application.

---

## Principles

Services should never instantiate repositories.

Repositories should never instantiate database sessions.

Dependencies should be injected by FastAPI.

---

## Dependency Flow

```
Request

↓

API Router

↓

Injected Service

↓

Injected Repository

↓

Injected Database Session
```

This approach improves

- Testability
- Maintainability
- Reusability

---

# 26. Error Handling

Errors should be handled consistently.

---

## Validation Errors

Return

```
400 Bad Request
```

---

## Missing Resources

Return

```
404 Not Found
```

---

## Duplicate Records

Return

```
409 Conflict
```

---

## Unexpected Errors

Return

```
500 Internal Server Error
```

Unexpected exceptions should always be logged.

Internal implementation details must never be returned to clients.

---

# 27. Logging

Logging is required throughout the backend.

Logs should assist debugging without exposing sensitive information.

---

## Log Categories

- Application Startup
- API Requests
- Validation Failures
- Synchronization
- Database Errors
- Authentication
- Unexpected Exceptions

---

## Logging Principles

Never log

- Passwords
- Authentication tokens
- Personal sensitive information

Always log

- Timestamp
- Module
- Operation
- Error details (when applicable)

---

# 28. Validation Standards

Validation occurs at multiple levels.

---

## Schema Validation

Handled by Pydantic.

Examples

- Required fields
- Data types
- Length limits

---

## Business Validation

Handled by Services.

Examples

- Semester number uniqueness
- Attendance rules
- Holiday conflicts
- Notes hierarchy validation

---

## Database Validation

Handled by PostgreSQL.

Examples

- Foreign Keys
- Unique Constraints
- Check Constraints

---

# 29. Development Rules

The following rules apply throughout backend development.

---

## Rule 1

Follow the Database Schema document.

Never modify the database structure without updating the documentation.

---

## Rule 2

Follow the Business Flow document.

Business logic must remain consistent with documented workflows.

---

## Rule 3

Follow the Synchronization Strategy.

Never bypass the SQLite First Policy.

---

## Rule 4

Business logic belongs only inside Services.

---

## Rule 5

Database access belongs only inside Repositories.

---

## Rule 6

API routes must remain thin.

---

## Rule 7

Every significant operation creates an Activity Log.

---

## Rule 8

Review Queue stores references only.

Never duplicate application data.

---

## Rule 9

Every new backend module must follow the standard module structure defined in this document.

---

## Rule 10

Keep code modular, readable and reusable.

Optimize for maintainability before optimization for performance.

---

# 30. Backend Completion Checklist

Before considering the backend complete, verify that every module contains

```
✓ SQLAlchemy Model

✓ Pydantic Schemas

✓ Repository

✓ Service

✓ API Router

✓ Dependency Injection

✓ Validation

✓ Logging

✓ Unit Tests

✓ Integration Tests

✓ Documentation
```

---

## Backend Milestones

The backend implementation is complete when:

- Every documented module has been implemented.
- Every database table has corresponding models, schemas, repositories, services and APIs.
- All business rules match the Business Flow document.
- Synchronization follows the Synchronization Strategy.
- Tests pass successfully.
- Documentation remains synchronized with implementation.

---

# End of Backend Architecture & Development Plan