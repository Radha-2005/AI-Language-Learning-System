from sqlalchemy.orm import Session
from app.models.score import ModuleScore
from app.models.user import UserLevel


def check_and_update_level(user_id: str, language: str, db: Session) -> dict:
    """
    Runs after every completed session.

    Logic:
      - Fetch the last 3 speech session scores for this user.
      - If fewer than 3 sessions exist → not enough data yet, do nothing.
      - If rolling average >= 0.85 for 3 sessions → upgrade one level.
      - If rolling average <  0.45 for 3 sessions → downgrade one level.
      - Otherwise → stay at current level.

    Returns a dict describing what happened so the Flutter app
    can show a "Level up!" message if needed.
    """
    # Get last 3 completed speech sessions, most recent first
    recent = (
        db.query(ModuleScore)
        .filter(
            ModuleScore.user_id == user_id,
            ModuleScore.language == language,
            ModuleScore.module == "speech",
        )
        .order_by(ModuleScore.session_date.desc())
        .limit(3)
        .all()
    )

    # Need at least 3 sessions before making a level decision
    if len(recent) < 3:
        sessions_done = len(recent)
        sessions_needed = 3 - sessions_done
        return {
            "changed": False,
            "reason": "not_enough_data",
            "message": f"Complete {sessions_needed} more session(s) to unlock level adjustment.",
        }

    # Calculate rolling average
    avg = sum(s.session_score for s in recent) / len(recent)

    # Get current level
    level_row = (
        db.query(UserLevel)
        .filter_by(user_id=user_id, language=language)
        .first()
    )
    current = level_row.level if level_row else "beginner"

    ORDER = ["beginner", "intermediate", "advanced"]
    idx = ORDER.index(current)
    new_level = current

    # Decide if level should change
    if avg >= 0.85 and idx < 2:
        new_level = ORDER[idx + 1]   # upgrade
    elif avg < 0.45 and idx > 0:
        new_level = ORDER[idx - 1]   # downgrade

    # Apply the change if needed
    if new_level != current:
        if level_row:
            level_row.level = new_level
        else:
            db.add(UserLevel(
                user_id=user_id,
                language=language,
                level=new_level,
            ))
        db.commit()

        direction = "up" if ORDER.index(new_level) > idx else "down"
        return {
            "changed": True,
            "direction": direction,
            "old": current,
            "new": new_level,
            "avg": round(avg, 2),
            "message": (
                f"Level up! You moved from {current} to {new_level}."
                if direction == "up"
                else f"Content adjusted. Moving from {current} to {new_level} to help you improve."
            ),
        }

    # No change
    return {
        "changed": False,
        "current": current,
        "avg": round(avg, 2),
        "message": "Level stays the same. Keep going!",
    }