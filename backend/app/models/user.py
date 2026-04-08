from app.database import Base
from sqlalchemy import Column, String, Float, DateTime
from datetime import datetime
import uuid

class User(Base):
    __tablename__ = "users"
    id         = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name       = Column(String)
    language   = Column(String)   # hindi / marathi / english
    goal       = Column(String)   # conversational / full_literacy / script
    created_at = Column(DateTime, default=datetime.utcnow)

class UserLevel(Base):
    __tablename__ = "user_levels"
    user_id    = Column(String, primary_key=True)
    language   = Column(String, primary_key=True)
    level      = Column(String)   # beginner / intermediate / advanced
    updated_at = Column(DateTime, default=datetime.utcnow)