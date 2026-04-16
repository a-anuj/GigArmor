"""
HustleHalt — Database Layer
Handles both SQLite (local dev) and PostgreSQL (Supabase prod) without config changes
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.config import settings


def _build_engine():
    """
    SQLite doesn't support pool_size/max_overflow — those are PostgreSQL-only args.
    This factory keeps the two configs separate so neither blows up.
    """
    is_postgres = settings.DATABASE_URL.startswith("postgresql")

    if is_postgres:
        return create_engine(
            settings.DATABASE_URL,
            echo=settings.DEBUG,
            pool_pre_ping=True,   # keeps stale Supabase connections from dying silently
            pool_size=5,
            max_overflow=10,
        )
    else:
        # SQLite — used for quick local runs, no connection pool needed
        return create_engine(
            settings.DATABASE_URL,
            echo=settings.DEBUG,
            connect_args={"check_same_thread": False},
        )


engine = _build_engine()

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()