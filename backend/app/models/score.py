from app.database import Base
from sqlalchemy import Column, String, Float, Date, JSON
import uuid
from datetime import date

class ModuleScore(Base):
    __tablename__ = "module_scores"
    id             = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id        = Column(String)
    module         = Column(String)  # speech / story / writing
    topic          = Column(String)
    language       = Column(String)
    session_score  = Column(Float)   # 0.0 to 1.0
    weak_areas     = Column(JSON)    # list of weak words/sounds
    session_date   = Column(Date, default=date.today)