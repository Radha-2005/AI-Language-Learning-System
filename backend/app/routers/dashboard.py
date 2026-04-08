# from fastapi import APIRouter, Depends
# from sqlalchemy.orm import Session
# from app.database import get_db
# from app.models.plan import LearningPlan
# from app.models.score import ModuleScore
# from app.models.user import User, UserLevel

# router = APIRouter()

# @router.get("/{user_id}")
# def get_dashboard(user_id: str, db: Session = Depends(get_db)):
#     """Returns everything the home screen needs in one call."""
#     user = db.query(User).filter_by(id=user_id).first()
#     level_row = db.query(UserLevel).filter_by(user_id=user_id).first()

#     # This week's plan
#     plan = db.query(LearningPlan).filter_by(
#         user_id=user_id
#     ).order_by(LearningPlan.day).all()

#     # Last 7 session scores for the chart
#     scores = db.query(ModuleScore).filter_by(
#         user_id=user_id
#     ).order_by(ModuleScore.session_date.desc()).limit(7).all()

#     # Streak — count consecutive days with a completed session
#     streak = 0
#     seen_dates = {s.session_date for s in scores}
#     from datetime import date, timedelta
#     check = date.today()
#     while check in seen_dates:
#         streak += 1
#         check -= timedelta(days=1)

#     # Total XP
#     total_xp = sum(int(s.session_score * 50) for s in scores)

#     return {
#         "user_name": user.name if user else "Learner",
#         "language": user.language if user else "hindi",
#         "level": level_row.level if level_row else "beginner",
#         "streak": streak,
#         "total_xp": total_xp,
#         "week_plan": [
#             {
#                 "day": p.day,
#                 "module": p.module,
#                 "topic": p.topic,
#                 "content_type": p.content_type,
#                 "status": p.status,
#             }
#             for p in plan
#         ],
#         "recent_scores": [
#             {
#                 "date": str(s.session_date),
#                 "score": s.session_score,
#                 "module": s.module,
#             }
#             for s in scores
#         ],
#     }

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.plan import LearningPlan
from app.models.score import ModuleScore
from app.models.user import User, UserLevel
from datetime import date, timedelta

router = APIRouter()


@router.get("/{user_id}")
def get_dashboard(user_id: str, db: Session = Depends(get_db)):
    """Returns everything the home screen needs in one call."""

    # ── Get user info ─────────────────────────────
    user = db.query(User).filter_by(id=user_id).first()
    level_row = db.query(UserLevel).filter_by(user_id=user_id).first()

    # ── Get plan (FIXED: day_number instead of day) ──
    plan = db.query(LearningPlan).filter_by(
        user_id=user_id
    ).order_by(LearningPlan.day_number).all()

    # ── Get recent scores ────────────────────────
    scores = db.query(ModuleScore).filter_by(
        user_id=user_id
    ).order_by(ModuleScore.session_date.desc()).limit(7).all()

    # ── Calculate streak ─────────────────────────
    streak = 0
    seen_dates = {s.session_date for s in scores}

    check = date.today()
    while check in seen_dates:
        streak += 1
        check -= timedelta(days=1)

    # ── Calculate XP ─────────────────────────────
    total_xp = sum(int(s.session_score * 50) for s in scores)

    # ── Response ────────────────────────────────
    return {
        "user_name": user.name if user else "Learner",
        "language": user.language if user else "hindi",
        "level": level_row.level if level_row else "beginner",
        "streak": streak,
        "total_xp": total_xp,

        "week_plan": [
            {
                "day": p.day_number,   # ✅ FIXED
                "module": p.module,
                "topic": p.topic,
                "content_type": p.content_type,
                "status": p.status,
            }
            for p in plan
        ],

        "recent_scores": [
            {
                "date": str(s.session_date),
                "score": s.session_score,
                "module": s.module,
            }
            for s in scores
        ],
    }