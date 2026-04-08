# from fastapi import FastAPI
# from fastapi.middleware.cors import CORSMiddleware
# from app.database import engine, Base
# from app.models import user, plan, score   # import so tables register
# from app.routers import setup, speech, dashboard

# Base.metadata.create_all(bind=engine)     # creates all tables

# app = FastAPI(title="BhashaSikho API")

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# app.include_router(setup.router,     prefix="/setup",     tags=["Setup"])
# app.include_router(speech.router,    prefix="/speech",    tags=["Speech"])
# app.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])

# @app.get("/health")
# def health():
#     return {"status": "ok"}

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine, Base

# ✅ Import models so tables are created
from app.models import user, plan, score

# ✅ Import routers
from app.routers import setup, speech, dashboard

# ✅ Create tables (SQLite will create test.db automatically)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="BhashaSikho API")

# ✅ Allow Flutter to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # (for dev only)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Register routes
app.include_router(setup.router, prefix="/setup", tags=["Setup"])
app.include_router(speech.router, prefix="/speech", tags=["Speech"])
app.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])

@app.get("/health")
def health():
    return {"status": "ok"}