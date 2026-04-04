"""
HustleHalt — Database Layer
SQLAlchemy synchronous engine. Defaults to SQLite for zero-config demos.
Switch to PostgreSQL by setting DATABASE_URL in .env.
"""
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.config import settings


# ── Engine ────────────────────────────────────────────────────────────────────
# SQLite needs check_same_thread=False for FastAPI's thread pool
_connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    _connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=_connect_args,
    echo=settings.DEBUG,        # Logs SQL queries in dev
)

# Enable WAL mode for SQLite (better concurrent read performance)
if settings.DATABASE_URL.startswith("sqlite"):
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()


# ── Session Factory ───────────────────────────────────────────────────────────
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


# ── Declarative Base ──────────────────────────────────────────────────────────
class Base(DeclarativeBase):
    pass


# ── Dependency ────────────────────────────────────────────────────────────────
def get_db():
    """FastAPI dependency — yields a DB session and closes it after the request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
