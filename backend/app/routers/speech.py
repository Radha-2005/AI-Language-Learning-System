from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List
from datetime import date

from app.database import get_db
from app.models.plan import LearningPlan
from app.models.score import ModuleScore
from app.models.user import User, UserLevel

from app.agents.speech_agent import transcribe_audio, score_pronunciation
from app.agents.level_agent import check_and_update_level
from app.agents.path_agent import get_todays_plan, generate_today_plan

router = APIRouter()


# ✅ REQUEST MODEL (MISSING IN YOUR CODE)
class CompleteSessionRequest(BaseModel):
    user_id: str
    plan_id: str
    language: str
    topic: str
    word_scores: List[dict]


# ✅ GET TODAY SESSION
@router.get("/today/{user_id}")
async def get_today_session(user_id: str, db: Session = Depends(get_db)):

    today_plan = get_todays_plan(user_id, db)

    if not today_plan:
        user = db.query(User).filter_by(id=user_id).first()
        level_row = db.query(UserLevel).filter_by(user_id=user_id).first()

        language = user.language if user else "hindi"
        level = level_row.level if level_row else "beginner"

        today_plan = await generate_today_plan(
            user_id=user_id,
            language=language,
            level=level,
            avg_score=0.5,
            db=db
        )

    return {
        "plan_id": today_plan.id,
        "topic": today_plan.topic,
        "content_type": today_plan.content_type,
        "items": today_plan.items,
        "progress": f"{today_plan.completed_count}/{today_plan.total_tasks}"
    }


# ✅ SCORE WORD
@router.post("/score-word")
async def score_word(
    user_id: str = Form(...),
    plan_id: str = Form(...),
    language: str = Form(...),
    target_text: str = Form(...),
    audio: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    audio_bytes = await audio.read()
    heard = await transcribe_audio(audio_bytes, language)
    result = score_pronunciation(target_text, heard)

    # ✅ Update progress
    plan = db.query(LearningPlan).filter_by(id=plan_id).first()

    if plan:
        plan.completed_count += 1

        if plan.completed_count >= plan.total_tasks:
            plan.status = "done"

        db.commit()

    return result


# ✅ COMPLETE SESSION (FIXED LOGIC)
@router.post("/complete")
async def complete_session(
    req: CompleteSessionRequest,
    db: Session = Depends(get_db),
):
    if not req.word_scores:
        return {"error": "No word scores provided"}

    avg = sum(w["score"] for w in req.word_scores) / len(req.word_scores)
    weak = [w["text"] for w in req.word_scores if w["score"] < 0.60]

    # ✅ Save session score
    db.add(ModuleScore(
        user_id=req.user_id,
        module="speech",
        topic=req.topic,
        language=req.language,
        session_score=round(avg, 2),
        weak_areas=weak,
        session_date=date.today(),
    ))

    # ✅ Mark today's plan as done
    plan = db.query(LearningPlan).filter_by(id=req.plan_id).first()
    if plan:
        plan.status = "done"

    db.commit()

    # ✅ Level check
    level_update = check_and_update_level(req.user_id, req.language, db)

    # ✅ NEW LOGIC → generate NEXT DAY dynamically
    user = db.query(User).filter_by(id=req.user_id).first()
    level_row = db.query(UserLevel).filter_by(user_id=req.user_id).first()

    language = user.language if user else "hindi"
    level = level_row.level if level_row else "beginner"

    # 👉 Generate next day's plan based on TODAY performance
    await generate_today_plan(
        user_id=req.user_id,
        language=language,
        level=level,
        avg_score=avg,   # 🔥 IMPORTANT: adaptive input
        db=db
    )

    return {
        "session_score": round(avg, 2),
        "xp_earned": int(avg * 50),
        "weak_areas": weak,
        "level_update": level_update,
        "completed_date": str(date.today()),
        "message": "Session saved successfully!",
    }