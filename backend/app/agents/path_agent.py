from datetime import date
from sqlalchemy.orm import Session

from app.models.plan import LearningPlan
from app.agents.content_agent import generate_content, determine_content_type


def decide_next_module(avg_score):
    if avg_score < 0.5:
        return "speech"
    elif avg_score < 0.75:
        return "writing"
    else:
        return "story"


async def generate_today_plan(
    user_id: str,
    language: str,
    level: str,
    avg_score: float,
    db: Session,
):
    today = date.today()

    # Check if already exists
    existing = db.query(LearningPlan).filter_by(
        user_id=user_id,
        scheduled_date=today,
        status="pending"
    ).first()

    if existing:
        return existing

    module = decide_next_module(avg_score)
    topic = "daily_conversation"

    items = await generate_content(
        language=language,
        level=level,
        topic=topic,
        content_type=determine_content_type(level, avg_score),
        weak_areas=[],
        avg_score=avg_score,
    )

    plan = LearningPlan(
        user_id=user_id,
        scheduled_date=today,
        day_number=1,
        module=module,
        topic=topic,
        content_type="word",
        items=items,
        total_tasks=len(items),
        completed_count=0,
        status="pending",
    )

    db.add(plan)
    db.commit()

    return plan


def get_todays_plan(user_id: str, db: Session):
    today = date.today()
    return db.query(LearningPlan).filter_by(
        user_id=user_id,
        scheduled_date=today,
        status="pending"
    ).first()