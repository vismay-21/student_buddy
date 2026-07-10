import uuid
from datetime import date
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academic.attendance_settings import CriteriaMode
from app.models.academic.lecture_instance import AttendanceStatus, LectureStatus
from app.schemas.academic.lecture_instance import AttendanceStatsResponse
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.utils.attendance_calculator import AttendanceCalculator
from app.core.constants import DEFAULT_ATTENDANCE_GOAL
from app.core.exceptions import NotFoundException


class AttendanceStatisticsService:
    def __init__(
        self,
        db: AsyncSession,
        lecture_instance_repo: LectureInstanceRepository,
        subject_repo: SubjectRepository,
        semester_repo: SemesterRepository,
        attendance_settings_repo: AttendanceSettingsRepository,
    ):
        self.db = db
        self.lecture_instance_repo = lecture_instance_repo
        self.subject_repo = subject_repo
        self.semester_repo = semester_repo
        self.attendance_settings_repo = attendance_settings_repo

    async def get_subject_attendance_stats(self, subject_id: uuid.UUID) -> AttendanceStatsResponse:
        subject = await self.subject_repo.get_by_id(subject_id)
        if subject is None:
            raise NotFoundException(f"Subject with ID {subject_id} not found")

        settings = await self.attendance_settings_repo.get_by_semester_id(subject.semester_id)
        criteria_mode = settings.criteria_mode if settings is not None else CriteriaMode.OVERALL

        # Determine target goal
        if criteria_mode in [CriteriaMode.OVERALL, CriteriaMode.SUBJECT]:
            goal = settings.overall_attendance_goal if settings is not None and settings.overall_attendance_goal is not None else DEFAULT_ATTENDANCE_GOAL
        else:
            # Custom Mode
            goal = subject.attendance_goal if subject.attendance_goal is not None else DEFAULT_ATTENDANCE_GOAL

        instances = await self.lecture_instance_repo.get_by_subject(subject_id)
        scheduled_instances = [inst for inst in instances if inst.lecture_status == LectureStatus.SCHEDULED]

        present = sum(1 for inst in scheduled_instances if inst.attendance_status == AttendanceStatus.PRESENT)
        absent = sum(1 for inst in scheduled_instances if inst.attendance_status == AttendanceStatus.ABSENT)

        pct = AttendanceCalculator.calculate_attendance_percentage(present, absent)
        rem = AttendanceCalculator.calculate_remaining_lectures(scheduled_instances, date.today())
        skip = AttendanceCalculator.calculate_safe_skip(present, absent, goal)
        msg = AttendanceCalculator.calculate_status_message(present, absent, goal)

        return AttendanceStatsResponse(
            total_lectures=len(scheduled_instances),
            present_lectures=present,
            absent_lectures=absent,
            attendance_percentage=pct,
            remaining_lectures=rem,
            safe_skip_count=skip,
            status_message=msg,
            criteria_mode=criteria_mode,
        )

    async def get_semester_attendance_stats(self, semester_id: uuid.UUID) -> AttendanceStatsResponse:
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")

        settings = await self.attendance_settings_repo.get_by_semester_id(semester_id)
        criteria_mode = settings.criteria_mode if settings is not None else CriteriaMode.OVERALL
        goal = settings.overall_attendance_goal if settings is not None and settings.overall_attendance_goal is not None else DEFAULT_ATTENDANCE_GOAL

        if criteria_mode == CriteriaMode.OVERALL:
            # Overall Mode: compute globally across all instances
            instances = await self.lecture_instance_repo.list_instances(semester_id=semester_id)
            scheduled_instances = [inst for inst in instances if inst.lecture_status == LectureStatus.SCHEDULED]

            present = sum(1 for inst in scheduled_instances if inst.attendance_status == AttendanceStatus.PRESENT)
            absent = sum(1 for inst in scheduled_instances if inst.attendance_status == AttendanceStatus.ABSENT)

            pct = AttendanceCalculator.calculate_attendance_percentage(present, absent)
            rem = AttendanceCalculator.calculate_remaining_lectures(scheduled_instances, date.today())
            skip = AttendanceCalculator.calculate_safe_skip(present, absent, goal)
            msg = AttendanceCalculator.calculate_status_message(present, absent, goal)

            return AttendanceStatsResponse(
                total_lectures=len(scheduled_instances),
                present_lectures=present,
                absent_lectures=absent,
                attendance_percentage=pct,
                remaining_lectures=rem,
                safe_skip_count=skip,
                status_message=msg,
                criteria_mode=criteria_mode,
            )
        else:
            # Subject or Custom Mode: aggregate subject-level calculations
            subjects = await self.subject_repo.list_by_semester(semester_id)
            all_instances = await self.lecture_instance_repo.list_instances(semester_id=semester_id)
            from collections import defaultdict
            instances_by_subject = defaultdict(list)
            for inst in all_instances:
                instances_by_subject[inst.lecture_template.subject_id].append(inst)
            
            total_lectures = 0
            present_lectures = 0
            absent_lectures = 0
            remaining_lectures = 0
            
            subject_percentages = []
            total_safe_skips = 0
            total_need_to_attend = 0

            for subject in subjects:
                # Determine active goal for subject
                if criteria_mode == CriteriaMode.SUBJECT:
                    sub_goal = goal
                else:
                    # Custom Mode
                    sub_goal = subject.attendance_goal if subject.attendance_goal is not None else DEFAULT_ATTENDANCE_GOAL

                instances = instances_by_subject[subject.subject_id]
                scheduled_instances = [inst for inst in instances if inst.lecture_status == LectureStatus.SCHEDULED]

                sub_present = sum(1 for inst in scheduled_instances if inst.attendance_status == AttendanceStatus.PRESENT)
                sub_absent = sum(1 for inst in scheduled_instances if inst.attendance_status == AttendanceStatus.ABSENT)

                sub_pct = AttendanceCalculator.calculate_attendance_percentage(sub_present, sub_absent)
                sub_rem = AttendanceCalculator.calculate_remaining_lectures(scheduled_instances, date.today())
                sub_skip = AttendanceCalculator.calculate_safe_skip(sub_present, sub_absent, sub_goal)
                sub_need = AttendanceCalculator.calculate_need_to_attend(sub_present, sub_absent, sub_goal)

                total_lectures += len(scheduled_instances)
                present_lectures += sub_present
                absent_lectures += sub_absent
                remaining_lectures += sub_rem

                if len(scheduled_instances) > 0:
                    subject_percentages.append(sub_pct)

                total_safe_skips += sub_skip
                total_need_to_attend += sub_need

            if subject_percentages:
                attendance_percentage = round(sum(subject_percentages) / len(subject_percentages), 2)
            else:
                attendance_percentage = 100.0

            # Status message aggregation
            if total_safe_skips > 0:
                status_message = f"can skip {total_safe_skips} lectures"
            elif total_need_to_attend > 0:
                status_message = f"need to attend next {total_need_to_attend} lectures"
            else:
                status_message = "can't skip next lecture"

            return AttendanceStatsResponse(
                total_lectures=total_lectures,
                present_lectures=present_lectures,
                absent_lectures=absent_lectures,
                attendance_percentage=attendance_percentage,
                remaining_lectures=remaining_lectures,
                safe_skip_count=total_safe_skips,
                status_message=status_message,
                criteria_mode=criteria_mode,
            )
