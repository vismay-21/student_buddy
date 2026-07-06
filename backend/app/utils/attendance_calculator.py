import math
from datetime import date
from typing import Sequence
from app.models.academic.lecture_instance import LectureInstance, AttendanceStatus


class AttendanceCalculator:
    @staticmethod
    def calculate_attendance_percentage(present: int, absent: int) -> float:
        marked = present + absent
        if marked == 0:
            return 100.0
        return round((present / marked) * 100.0, 2)

    @staticmethod
    def calculate_safe_skip(present: int, absent: int, goal: int) -> int:
        marked = present + absent
        if marked == 0:
            return 0
        val_k = (100 * present - goal * marked) / goal
        k = math.floor(val_k)
        return max(0, k)

    @staticmethod
    def calculate_remaining_lectures(scheduled_instances: Sequence[LectureInstance], today_date: date) -> int:
        return sum(
            1 for inst in scheduled_instances
            if inst.lecture_date > today_date and inst.attendance_status == AttendanceStatus.UNMARKED
        )

    @staticmethod
    def calculate_status_message(present: int, absent: int, goal: int) -> str:
        marked = present + absent
        if marked == 0:
            return "can't skip next lecture"

        val_k = (100 * present - goal * marked) / goal
        k = math.floor(val_k)
        if k > 0:
            return f"can skip {k} lectures"
        elif k == 0:
            return "can't skip next lecture"
        else:
            divisor = 100 - goal
            if divisor <= 0:
                return "need to attend next lecture" if absent > 0 else "can't skip next lecture"
            val_m = (goal * marked - 100 * present) / divisor
            m = math.ceil(val_m)
            return f"need to attend next {m} lectures"

    @staticmethod
    def calculate_need_to_attend(present: int, absent: int, goal: int) -> int:
        marked = present + absent
        if marked == 0:
            return 0
        val_k = (100 * present - goal * marked) / goal
        k = math.floor(val_k)
        if k >= 0:
            return 0
        divisor = 100 - goal
        if divisor <= 0:
            return 1 if absent > 0 else 0
        val_m = (goal * marked - 100 * present) / divisor
        return math.ceil(val_m)
