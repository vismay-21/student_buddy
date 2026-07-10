import uuid
from typing import Any, Dict
from datetime import datetime, timezone
from app.core.exceptions import NotFoundException, ValidationException
from app.models.academic.lecture_instance import LectureStatus, AttendanceStatus, MarkedBy
from app.schemas.academic.lecture_instance import LectureInstanceUpdate
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.services.review_queue.resolvers.base import BaseResolver


class LectureInstanceResolver(BaseResolver):
    async def resolve(self, entity_id: uuid.UUID, resolution_data: Dict[str, Any]) -> None:
        li_repo = LectureInstanceRepository(self.db)
        instance = await li_repo.get_by_id(entity_id)
        if instance is None:
            raise NotFoundException(f"Referenced LectureInstance with ID {entity_id} not found")

        # Validate resolution data using LectureInstanceUpdate schema
        try:
            inst_update = LectureInstanceUpdate(**resolution_data)
        except Exception as e:
            raise ValidationException(f"Invalid resolution data for LectureInstance: {str(e)}")

        # Apply updates and business rules
        target_status = inst_update.attendance_status
        if target_status is not None:
            current_lecture_status = inst_update.lecture_status or instance.lecture_status
            if current_lecture_status == LectureStatus.HOLIDAY:
                if target_status in [AttendanceStatus.PRESENT, AttendanceStatus.ABSENT]:
                    raise ValidationException("Cannot mark holiday lectures as present or absent.")

            instance.attendance_status = target_status
            if target_status == AttendanceStatus.UNMARKED:
                instance.marked_by = None
                instance.marked_at = None
            else:
                instance.marked_by = MarkedBy.USER
                instance.marked_at = datetime.now(timezone.utc)

        if inst_update.lecture_status is not None:
            instance.lecture_status = inst_update.lecture_status
            if inst_update.lecture_status == LectureStatus.HOLIDAY:
                instance.attendance_status = AttendanceStatus.UNMARKED
                instance.marked_by = None
                instance.marked_at = None

        await li_repo.update(instance)

    async def get_summary(self, entity_id: uuid.UUID) -> str:
        li_repo = LectureInstanceRepository(self.db)
        instance = await li_repo.get_by_id(entity_id)
        if instance is None:
            return "Unknown Lecture"

        subject_name = "Unknown"
        day_str = "Unknown Day"
        time_str = "00:00"

        if instance.lecture_template:
            template = instance.lecture_template
            if template.subject:
                subject_name = template.subject.subject_name

            days = {
                1: "Monday",
                2: "Tuesday",
                3: "Wednesday",
                4: "Thursday",
                5: "Friday",
                6: "Saturday",
                7: "Sunday"
            }
            day_str = days.get(template.day_of_week, "Unknown Day")

            if template.start_time:
                time_str = template.start_time.strftime("%H:%M")

        return f"{subject_name} • {day_str} • {time_str}"
