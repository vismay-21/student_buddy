from app.models.review_queue.review_queue import EntityType
from app.services.review_queue.resolvers.todo import TodoResolver
from app.services.review_queue.resolvers.lecture_instance import LectureInstanceResolver
from app.services.review_queue.resolvers.finance import FinanceResolver

RESOLVERS = {
    EntityType.TODO: TodoResolver,
    EntityType.ATTENDANCE: LectureInstanceResolver,
    EntityType.FINANCE: FinanceResolver
}
