import uuid
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.activity_logs.activity_log import EntityType, ActivityLog


async def get_activity_entity_summary(
    db: AsyncSession,
    entity_type: EntityType,
    entity_id: uuid.UUID
) -> str:
    """
    Resolves the human-readable entity summary for the given entity ID and type dynamically.
    Delegates to resolvers for polymorphic entities and queries repositories for other types.
    """
    try:
        if entity_type == EntityType.TODO:
            from app.services.review_queue.resolvers.todo import TodoResolver
            return await TodoResolver(db).get_summary(entity_id)

        elif entity_type == EntityType.ATTENDANCE:
            from app.services.review_queue.resolvers.lecture_instance import LectureInstanceResolver
            return await LectureInstanceResolver(db).get_summary(entity_id)

        elif entity_type == EntityType.FINANCE:
            from app.services.review_queue.resolvers.finance import FinanceResolver
            return await FinanceResolver(db).get_summary(entity_id)

        elif entity_type == EntityType.SEMESTER:
            from app.repositories.academic.semester import SemesterRepository
            semester = await SemesterRepository(db).get_by_id(entity_id)
            if semester:
                return f"Semester {semester.semester_number}"

        elif entity_type == EntityType.SUBJECT:
            from app.repositories.academic.subject import SubjectRepository
            subject = await SubjectRepository(db).get_by_id(entity_id)
            if subject:
                return subject.subject_name

        elif entity_type == EntityType.HOLIDAY:
            from app.repositories.academic.holiday import HolidayRepository
            holiday = await HolidayRepository(db).get_by_id(entity_id)
            if holiday:
                return holiday.holiday_name

        elif entity_type == EntityType.SETTINGS:
            return "App Settings"

        elif entity_type == EntityType.REVIEW_QUEUE:
            from app.repositories.review_queue.review_queue import ReviewQueueRepository
            item = await ReviewQueueRepository(db).get_by_id(entity_id)
            if item:
                return f"Review: {item.review_message}"

        elif entity_type == EntityType.NOTES:
            from app.repositories.notes.notes import NotesResourceRepository, NotesSectionRepository
            # Check resource
            res_repo = NotesResourceRepository(db)
            resource = await res_repo.get_by_id(entity_id)
            if resource:
                return resource.resource_name
            # Check section
            sec_repo = NotesSectionRepository(db)
            section = await sec_repo.get_by_id(entity_id)
            if section:
                return section.section_name
    except Exception:
        pass

    return f"Unknown {entity_type.value.capitalize()}"


async def bulk_populate_activity_summaries(
    db: AsyncSession,
    logs: Sequence[ActivityLog]
) -> None:
    """
    Polymorphically populates entity_summary for a list of ActivityLogs in batch.
    Replaces N+1 repository fetches with single bulk queries per entity type.
    """
    if not logs:
        return

    from collections import defaultdict
    grouped = defaultdict(list)
    for log in logs:
        grouped[log.entity_type].append(log.entity_id)

    summaries = {}  # (entity_type, entity_id) -> summary_str

    # 1. TODO
    todo_ids = grouped.get(EntityType.TODO)
    if todo_ids:
        from app.models.todo.todo import Todo
        from sqlalchemy import select
        stmt = select(Todo).where(Todo.todo_id.in_(todo_ids))
        res = await db.execute(stmt)
        todos = res.scalars().all()
        todo_map = {t.todo_id: t.title for t in todos}
        for tid in todo_ids:
            summaries[(EntityType.TODO, tid)] = todo_map.get(tid, "Unknown Todo")

    # 2. ATTENDANCE (LectureInstance)
    attendance_ids = grouped.get(EntityType.ATTENDANCE)
    if attendance_ids:
        from app.models.academic.lecture_instance import LectureInstance
        from app.models.academic.lecture_template import LectureTemplate
        from app.models.academic.subject import Subject
        from sqlalchemy import select
        from sqlalchemy.orm import joinedload
        stmt = (
            select(LectureInstance)
            .options(
                joinedload(LectureInstance.lecture_template)
                .joinedload(LectureTemplate.subject)
            )
            .where(LectureInstance.lecture_instance_id.in_(attendance_ids))
        )
        res = await db.execute(stmt)
        instances = res.scalars().all()

        days = {
            1: "Monday", 2: "Tuesday", 3: "Wednesday", 4: "Thursday",
            5: "Friday", 6: "Saturday", 7: "Sunday"
        }
        instance_map = {}
        for inst in instances:
            subject_name = "Unknown"
            day_str = "Unknown Day"
            time_str = "00:00"
            if inst.lecture_template:
                template = inst.lecture_template
                if template.subject:
                    subject_name = template.subject.subject_name
                day_str = days.get(template.day_of_week, "Unknown Day")
                if template.start_time:
                    time_str = template.start_time.strftime("%H:%M")
            instance_map[inst.lecture_instance_id] = f"{subject_name} • {day_str} • {time_str}"

        for aid in attendance_ids:
            summaries[(EntityType.ATTENDANCE, aid)] = instance_map.get(aid, "Unknown Lecture")

    # 3. FINANCE
    finance_ids = grouped.get(EntityType.FINANCE)
    if finance_ids:
        for fid in finance_ids:
            summaries[(EntityType.FINANCE, fid)] = "Finance Record"

    # 4. SEMESTER
    semester_ids = grouped.get(EntityType.SEMESTER)
    if semester_ids:
        from app.models.academic.semester import Semester
        from sqlalchemy import select
        stmt = select(Semester).where(Semester.semester_id.in_(semester_ids))
        res = await db.execute(stmt)
        semesters = res.scalars().all()
        semester_map = {s.semester_id: f"Semester {s.semester_number}" for s in semesters}
        for sid in semester_ids:
            summaries[(EntityType.SEMESTER, sid)] = semester_map.get(sid, "Unknown Semester")

    # 5. SUBJECT
    subject_ids = grouped.get(EntityType.SUBJECT)
    if subject_ids:
        from app.models.academic.subject import Subject
        from sqlalchemy import select
        stmt = select(Subject).where(Subject.subject_id.in_(subject_ids))
        res = await db.execute(stmt)
        subjects = res.scalars().all()
        subject_map = {s.subject_id: s.subject_name for s in subjects}
        for sid in subject_ids:
            summaries[(EntityType.SUBJECT, sid)] = subject_map.get(sid, "Unknown Subject")

    # 6. HOLIDAY
    holiday_ids = grouped.get(EntityType.HOLIDAY)
    if holiday_ids:
        from app.models.academic.holiday import Holiday
        from sqlalchemy import select
        stmt = select(Holiday).where(Holiday.holiday_id.in_(holiday_ids))
        res = await db.execute(stmt)
        holidays = res.scalars().all()
        holiday_map = {h.holiday_id: h.holiday_name for h in holidays}
        for hid in holiday_ids:
            summaries[(EntityType.HOLIDAY, hid)] = holiday_map.get(hid, "Unknown Holiday")

    # 7. SETTINGS
    settings_ids = grouped.get(EntityType.SETTINGS)
    if settings_ids:
        for sid in settings_ids:
            summaries[(EntityType.SETTINGS, sid)] = "App Settings"

    # 8. REVIEW_QUEUE
    rq_ids = grouped.get(EntityType.REVIEW_QUEUE)
    if rq_ids:
        from app.models.review_queue.review_queue import ReviewQueue
        from sqlalchemy import select
        stmt = select(ReviewQueue).where(ReviewQueue.review_id.in_(rq_ids))
        res = await db.execute(stmt)
        rq_items = res.scalars().all()
        rq_map = {rq.review_id: f"Review: {rq.review_message}" for rq in rq_items}
        for rqid in rq_ids:
            summaries[(EntityType.REVIEW_QUEUE, rqid)] = rq_map.get(rqid, "Unknown Review")

    # 9. NOTES
    notes_ids = grouped.get(EntityType.NOTES)
    if notes_ids:
        from app.models.notes.notes_resource import NotesResource
        from app.models.notes.notes_section import NotesSection
        from sqlalchemy import select

        # Check resources first
        stmt_res = select(NotesResource).where(NotesResource.resource_id.in_(notes_ids))
        res_res = await db.execute(stmt_res)
        resources = res_res.scalars().all()
        resource_map = {r.resource_id: r.resource_name for r in resources}

        # Check sections
        stmt_sec = select(NotesSection).where(NotesSection.section_id.in_(notes_ids))
        res_sec = await db.execute(stmt_sec)
        sections = res_sec.scalars().all()
        section_map = {s.section_id: s.section_name for s in sections}

        for nid in notes_ids:
            if nid in resource_map:
                summaries[(EntityType.NOTES, nid)] = resource_map[nid]
            elif nid in section_map:
                summaries[(EntityType.NOTES, nid)] = section_map[nid]
            else:
                summaries[(EntityType.NOTES, nid)] = "Unknown Notes"

    # Assign summaries back to logs
    for log in logs:
        log.entity_summary = summaries.get(
            (log.entity_type, log.entity_id),
            f"Unknown {log.entity_type.value.capitalize()}"
        )
