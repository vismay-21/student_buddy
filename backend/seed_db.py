import os
import sys
import asyncio
from datetime import date, time, datetime, timezone

# Ensure the backend directory is in the Python search path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import text
from app.core.database import async_session, engine
from app.schemas.academic.semester import SemesterCreate
from app.schemas.academic.subject import SubjectCreate
from app.schemas.academic.lecture_template import LectureTemplateCreate
from app.schemas.academic.holiday import HolidayCreate
from app.schemas.todo.todo import TodoCreate
from app.models.todo.todo import TodoPriority
from app.services.academic.semester import SemesterService
from app.services.academic.subject import SubjectService
from app.services.academic.lecture_template import LectureTemplateService
from app.services.academic.holiday import HolidayService
from app.services.todo.todo import TodoService
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.notes.notes_subject import NotesSubjectRepository
from app.repositories.academic.lecture_template import LectureTemplateRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.academic.holiday import HolidayRepository
from app.repositories.todo.todo import TodoRepository


async def main():
    print("Connecting to the database...")
    # Truncate tables and reset database sequence IDs
    async with engine.begin() as conn:
        print("Truncating existing tables and resetting sequences...")
        await conn.execute(
            text(
                "TRUNCATE TABLE semesters, attendance_settings, subjects, notes_subjects, "
                "notes_sections, notes_resources, lecture_templates, lecture_instances, "
                "holidays, todos, review_queue, activity_logs RESTART IDENTITY CASCADE;"
            )
        )
        print("Initializing default app settings...")
        await conn.execute(
            text(
                "INSERT INTO app_settings (settings_id, theme_mode, finance_enabled, "
                "morning_digest_enabled, night_digest_enabled, attendance_prompt_enabled, created_at, updated_at) "
                "VALUES (1, 'SYSTEM', false, true, true, true, NOW(), NOW()) "
                "ON CONFLICT (settings_id) DO NOTHING;"
            )
        )
    
    async with async_session() as session:
        # Instantiate repositories
        semester_repo = SemesterRepository(session)
        attendance_repo = AttendanceSettingsRepository(session)
        subject_repo = SubjectRepository(session)
        notes_subject_repo = NotesSubjectRepository(session)
        lecture_template_repo = LectureTemplateRepository(session)
        lecture_instance_repo = LectureInstanceRepository(session)
        holiday_repo = HolidayRepository(session)
        todo_repo = TodoRepository(session)

        # Instantiate services
        semester_service = SemesterService(session, semester_repo, attendance_repo)
        subject_service = SubjectService(session, subject_repo, semester_repo, notes_subject_repo)
        lecture_template_service = LectureTemplateService(
            session, lecture_template_repo, lecture_instance_repo, subject_repo, semester_repo
        )
        holiday_service = HolidayService(session, holiday_repo, semester_repo)
        todo_service = TodoService(session, todo_repo)

        # 1. Create Semester
        print("Creating Semester 1 (Jul 6, 2026 - Aug 1, 2026)...")
        semester_in = SemesterCreate(
            semester_number=1,
            start_date=date(2026, 7, 6),
            end_date=date(2026, 8, 1)
        )
        semester = await semester_service.create_semester(semester_in)
        print(f"Semester 1 created with ID: {semester.semester_id}")

        # 2. Create Holidays
        print("Creating Holidays...")
        holidays_data = [
            ("Mid-Term Break", date(2026, 7, 15)),
            ("College Fest", date(2026, 7, 24)),
        ]
        for name, h_date in holidays_data:
            holiday_in = HolidayCreate(
                semester_id=semester.semester_id,
                holiday_date=h_date,
                holiday_name=name
            )
            await holiday_service.create_holiday(semester.semester_id, holiday_in)
            print(f"Created holiday: {name} on {h_date}")

        # 3. Create Subjects
        print("Creating Subjects...")
        subjects_data = [
            ("Mathematics", "Dr. Amit Sharma", "#3F51B5", 75),
            ("Database Management Systems", "Prof. S. R. Patel", "#4CAF50", 80),
            ("Operating Systems", "Dr. Vivek Gupta", "#FF9800", 75),
            ("Computer Networks", "Mrs. Sneha Shah", "#E91E63", 75),
        ]
        subjects_map = {}
        for name, faculty, color, goal in subjects_data:
            subject_in = SubjectCreate(
                semester_id=semester.semester_id,
                subject_name=name,
                faculty_name=faculty,
                theme_color=color,
                attendance_goal=goal
            )
            subject = await subject_service.create_subject(subject_in)
            subjects_map[name] = subject.subject_id
            print(f"Created subject: {name} ({faculty})")

        # 4. Create Lecture Templates (timetable)
        print("Creating Lecture Templates (this will automatically generate matching lecture instances)...")
        # Monday (1) to Friday (5)
        # format: (subject_name, day_of_week, start_time, end_time, room)
        templates_data = [
            ("Operating Systems", 1, time(9, 0), time(10, 0), "Room 301"),
            ("Database Management Systems", 1, time(10, 0), time(11, 0), "Room 302"),
            
            ("Computer Networks", 2, time(9, 0), time(10, 0), "Room 204"),
            ("Mathematics", 2, time(11, 0), time(12, 0), "Room 101"),
            
            ("Operating Systems", 3, time(9, 0), time(10, 0), "Room 301"),
            ("Database Management Systems", 3, time(10, 0), time(11, 0), "Room 302"),
            
            ("Computer Networks", 4, time(9, 0), time(10, 0), "Room 204"),
            ("Mathematics", 4, time(11, 0), time(12, 0), "Room 101"),
            
            ("Database Management Systems", 5, time(10, 0), time(11, 0), "Room 302"),
            ("Mathematics", 5, time(11, 0), time(12, 0), "Room 101"),
        ]
        for sub_name, day, start, end, room in templates_data:
            sub_id = subjects_map[sub_name]
            template_in = LectureTemplateCreate(
                subject_id=sub_id,
                day_of_week=day,
                start_time=start,
                end_time=end,
                room=room
            )
            await lecture_template_service.create_template(template_in)
            print(f"Created template: {sub_name} on day {day} from {start} to {end} ({room})")

        # 5. Create Todo Items
        print("Creating Todo Items...")
        todos_data = [
            ("Buy Math textbook", TodoPriority.LOW, datetime(2026, 7, 15, 12, 0, tzinfo=timezone.utc)),
            ("Submit DBMS assignment", TodoPriority.HIGH, datetime(2026, 7, 20, 23, 59, tzinfo=timezone.utc)),
            ("Revise CN subnetting", TodoPriority.MEDIUM, datetime(2026, 7, 25, 18, 0, tzinfo=timezone.utc)),
        ]
        for title, priority, due in todos_data:
            todo_in = TodoCreate(
                title=title,
                priority=priority,
                due_datetime=due
            )
            await todo_service.create_todo(todo_in)
            print(f"Created todo: '{title}' (Priority: {priority.value})")

        # 6. Set Active Semester in app_settings
        print("Setting Semester 1 as active in app_settings...")
        await session.execute(
            text("UPDATE app_settings SET active_semester_id = :sem_id WHERE settings_id = 1;"),
            {"sem_id": semester.semester_id}
        )
        await session.commit()
        print("Seeding completed successfully!")


if __name__ == "__main__":
    asyncio.run(main())
