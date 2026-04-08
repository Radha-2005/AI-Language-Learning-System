from app.database import Base
from sqlalchemy import Column, String, Integer, Date, JSON
import uuid


class LearningPlan(Base):
    __tablename__ = "learning_plans"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String)

    scheduled_date = Column(Date)
    day_number = Column(Integer)

    module = Column(String)        # speech / writing / story
    topic = Column(String)
    content_type = Column(String)

    items = Column(JSON)

    # ✅ NEW FIELDS
    completed_count = Column(Integer, default=0)
    total_tasks = Column(Integer, default=0)

    status = Column(String, default="pending")