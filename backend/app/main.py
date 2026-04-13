"""
HustleHalt — FastAPI Application Entry Point
Protect Your Worker | Guidewire DEVTrails Hackathon
"""
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine, Base, SessionLocal

# ── Import all models so SQLAlchemy registers them before create_all ──────────
from app.models import Zone, Worker, Policy, TriggerEvent, Claim  # noqa: F401


# ── Seed Data — Dark Store Zones across Bengaluru ─────────────────────────────
_SEED_ZONES = [
    {"id": 1, "name": "Koramangala Dark Store",  "pincode": "560034", "base_risk_multiplier": 1.2},
    {"id": 2, "name": "Indiranagar Hub",          "pincode": "560038", "base_risk_multiplier": 1.0},
    {"id": 3, "name": "Whitefield Spoke",          "pincode": "560066", "base_risk_multiplier": 1.5},
    {"id": 4, "name": "HSR Layout Store",          "pincode": "560102", "base_risk_multiplier": 0.9},
    {"id": 5, "name": "Marathahalli Hub",          "pincode": "560037", "base_risk_multiplier": 1.3},
    {"id": 6, "name": "Electronic City Store",     "pincode": "560100", "base_risk_multiplier": 1.4},
    {"id": 7, "name": "JP Nagar Dark Store",       "pincode": "560078", "base_risk_multiplier": 1.1},
    {"id": 8, "name": "Coimbatore RS Puram",       "pincode": "641002", "base_risk_multiplier": 1.1},
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup: create all tables and seed zones.
    Shutdown: nothing special needed for SQLite.
    """
    # Create tables (idempotent)
    Base.metadata.create_all(bind=engine)

    # Seed zones if not already present
    db = SessionLocal()
    try:
        for z in _SEED_ZONES:
            if not db.query(Zone).filter(Zone.id == z["id"]).first():
                db.add(Zone(**z))
        db.commit()
    finally:
        db.close()

    yield  # ← Application runs here


# ── FastAPI App ───────────────────────────────────────────────────────────────
app = FastAPI(
    title="HustleHalt API",
    description=(
        "**AI-powered parametric income insurance for gig economy workers.**\n\n"
        "Zero-touch claims, dynamic pricing, and instant UPI payouts. "
        "Built for the Guidewire DEVTrails Hackathon — Theme: *Protect Your Worker*."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Routers (imported after models to avoid circular imports) ─────────────────
from app.routers import workers, policies, claims, admin  # noqa: E402
from app.routers.workers import zone_router  # noqa: E402

app.include_router(workers.router)
app.include_router(zone_router)
app.include_router(policies.router)
app.include_router(claims.router)
app.include_router(admin.router)


# ── Root / Health Endpoints ───────────────────────────────────────────────────
@app.get("/", tags=["Health"], summary="Service Info")
def root():
    return {
        "service": "HustleHalt API",
        "version": "1.0.0",
        "status": "online",
        "tagline": "Protect Your Worker — Zero-Touch Parametric Insurance",
        "docs": "/docs",
        "environment": settings.APP_ENV,
    }


@app.get("/health", tags=["Health"], summary="Health Check")
def health():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "database": settings.DATABASE_URL.split("://")[0],
    }
