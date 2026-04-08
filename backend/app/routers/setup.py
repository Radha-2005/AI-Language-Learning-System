from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.database import get_db
from app.models.user import User, UserLevel
from app.agents.path_agent import generate_today_plan   # ✅ correct import

router = APIRouter()


class SetupRequest(BaseModel):
    name: str
    language: str
    level: str
    goal: str


@router.post("")
async def setup_user(req: SetupRequest, db: Session = Depends(get_db)):
    """Called once when user completes onboarding."""

    # Create user
    user = User(name=req.name, language=req.language, goal=req.goal)
    db.add(user)
    db.commit()
    db.refresh(user)   # ✅ IMPORTANT

    # Save level
    db.add(UserLevel(user_id=user.id, language=req.language, level=req.level))
    db.commit()

    # Generate today's plan
    plan = await generate_today_plan(
        user_id=user.id,
        language=req.language,
        level=req.level,
        avg_score=0.5,
        db=db,
    )

    return {
        "user_id": user.id,
        "message": f"Welcome {req.name}! Your plan is ready.",
        "plan_days": 1,
    }