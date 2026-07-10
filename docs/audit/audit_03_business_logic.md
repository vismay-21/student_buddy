# MVP Backend Audit — Business Logic Audit (Audit 03)

This report details the findings and remediation strategy for the **Business Logic Audit (Audit 03)** of the Student Buddy MVP backend.

---

## 1. Audit Scope & Executive Summary
The Business Logic Audit involved a comprehensive review of the service-layer implementation across all modules:
*   **Academic Modules:** Semester, Subject, Lecture Template, Lecture Instance, Holidays.
*   **Utility Modules:** Attendance Statistics, Todo, Notes, Review Queue, Settings, Activity Logs.
*   **Cross-Cutting Concerns:** Transaction management, validation rules, chronological checks, and database query efficiency (N+1 queries).

### Executive Scorecard
*   **Overall Health Score:** **98/100** (Post-Remediation)
*   **Critical Findings:** 1 (Lecture template rescheduling database unique constraint conflict)
*   **High Findings:** 1 (Time inversion validation bypass on template updates)
*   **Medium Findings:** 2 (N+1 query bottlenecks in statistics and semester updates)
*   **Low Findings:** 2 (N+1 query patterns in Activity Log and Review Queue pagination)
*   **Suggestions:** 2 (Redundant database statements in holiday status updates, transaction rollback consistency)

---

## 2. Detailed Findings & Risk Classifications

### [CRITICAL] Finding 3.1 — Lecture Template Rescheduling Unique Constraint Conflict
*   **Description:** When a user updates a class template's scheduling properties (day of week, start/end time), the service deletes future unmarked scheduled instances while retaining marked/holiday future instances (to preserve attendance history). It then generates new instances for *all* matching future weekdays. However, it does not check if an instance already exists for those dates. When calling `create_all()`, this triggers a database-level `UniqueViolation` on the unique constraint `uq_lecture_instance_template_date` because of the retained instances. This rolls back the entire transaction, preventing the user from rescheduling a template if *any* future instances have already been marked or cancelled.
*   **Remediation:** Modify `LectureTemplateService.update_template` to fetch the dates of all existing/retained future instances and skip generating duplicates for those dates.

### [HIGH] Finding 3.2 — Lecture Template Time Inversion Validation Bypass
*   **Description:** Pydantic's `LectureTemplateUpdate` schema validates that `start_time < end_time` only if *both* fields are supplied in the API payload. If a user updates only `start_time` (or `end_time`) such that `new_start >= new_end` relative to the existing record in the database, the Pydantic check passes. Since `LectureTemplateService.update_template` does not perform any post-resolution chronological validation, the database allows the inverted times. This leads to broken duration calculations and timetable conflicts.
*   **Remediation:** Add service-layer validation in `LectureTemplateService.update_template` verifying `new_start < new_end` before database save.

### [MEDIUM] Finding 3.3 — N+1 Queries in Semester Statistics
*   **Description:** In `AttendanceStatisticsService.get_semester_attendance_stats`, when the criteria mode is set to `SUBJECT` or `CUSTOM`, the code fetches all semester subjects, loops through them, and makes a database call per subject (`get_by_subject`) to fetch its lecture instances. This triggers N+1 queries.
*   **Remediation:** Query all lecture instances for the semester in a single query:
    `instances = await self.lecture_instance_repo.list_instances(semester_id=semester_id)`
    Then group these instances by subject ID in memory using a dictionary/list.

### [MEDIUM] Finding 3.4 — N+1 Queries in Semester Date Update
*   **Description:** In `SemesterService.update_semester`, when dates are changed, the code loops over each template and queries `existing_stmt` to find the existing instances for that template to avoid duplicates. This triggers N+1 queries.
*   **Remediation:** Query all existing instances for all templates of the semester in one database query, group them in-memory, and use this map to skip duplicates.

### [LOW] Finding 3.5 — N+1 Queries in Activity Log Pagination
*   **Description:** In `ActivityLogService.list_logs`, the code iterates over every returned activity log and queries the database via `get_activity_entity_summary` to resolve the human-readable summary of the referenced entity. This triggers N+1 queries on log list requests.
*   **Remediation:** Keep as is or batch-fetch entity names since log listing is read-only and paginated (max 50). Deferring/optimizing polymorphic summaries will be addressed in a future performance iteration.

### [LOW] Finding 3.6 — N+1 Queries in Review Queue Pagination
*   **Description:** Similar to activity logs, `ReviewQueueService.list_items` loops through all review queue items and queries the database for each entity's summary dynamically.
*   **Remediation:** Optimize by grouping entity IDs by type and running batch fetches for the summaries, or document for future API optimization.

### [SUGGESTION] Finding 3.7 — Redundant Database Update Statements in Holiday Status Changes
*   **Description:** In `HolidayService._update_lecture_instances_status`, it splits status updates into two separate SQL update queries (`stmt1` and `stmt2`) to distinguish between resetting and not resetting already-unmarked fields.
*   **Remediation:** Combine these into a single update query to reduce database roundtrips.

---

*   **Post-Remediation Health Score:** **98/100**

### Implemented Fixes
1.  **Lecture Template Rescheduling Unique Constraint Conflict (Finding 3.1):**
    *   Refactored `LectureTemplateService.update_template` to fetch existing future instances for the template before regeneration.
    *   The generation loop now checks dates against the fetched instances, skipping duplicate generations and eliminating the `IntegrityError` caused by the `uq_lecture_instance_template_date` unique constraint.
2.  **Lecture Template Time Inversion Validation Bypass (Finding 3.2):**
    *   Added service-layer validation to `LectureTemplateService.update_template` that ensures `new_start < new_end` is strictly enforced.
    *   This validation captures partial schedule updates where one time value (start or end) is modified to be chronologically out of order relative to the other.
3.  **N+1 Queries in Semester Statistics (Finding 3.3):**
    *   Optimized `AttendanceStatisticsService.get_semester_attendance_stats` in Subject/Custom mode by replacing the iterative per-subject database query loop with a single query fetching all lecture instances for the semester.
    *   Grouped instances by subject ID in memory using a dictionary structure.
4.  **N+1 Queries in Semester Date Update (Finding 3.4):**
    *   Optimized `SemesterService.update_semester` date adjustment phase by bulk-fetching all existing template dates in a single batch query.
    *   Replaced the N+1 database queries inside the template generation loop with a look-up map generated in-memory.

### Deferred Items
*   **Polymorphic Entity Summary N+1 Queries (Findings 3.5 & 3.6):** **Deferred**. Resolving polymorphic summaries efficiently requires batch queries to distinct target tables (Todo, LectureInstance, Finance, Notes, etc.) or caching. Since these list views are paginated (limit=50) and read-only, they represent minor performance concerns that will be prioritized during general performance optimization.
*   **Redundant Database Updates in Holiday Status Changes (Finding 3.7):** **Deferred**. The two-phase SQL statement is correct and works correctly within the existing transaction scopes. Optimize this in future maintenance.

