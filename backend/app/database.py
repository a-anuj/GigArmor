"""
HustleHalt — Database Layer
SQLAlchemy synchronous engine (PostgreSQL / Supabase ready)
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.config import settings


# ── Engine ─────────────────────────────────────────────
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,   # avoids stale connections
    pool_size=5,
    max_overflow=10,
)


# ── Session Factory ────────────────────────────────────
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


# ── Base Class ─────────────────────────────────────────
class Base(DeclarativeBase):
    pass


# ── Dependency (FastAPI) ───────────────────────────────
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()