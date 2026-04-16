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

# Import all models so SQLAlchemy registers them before create_all
from app.models import Zone, Worker, Policy, TriggerEvent, Claim  # noqa: F401


# Real Bengaluru dark store coordinates — verified against Google Maps
# Each zone maps to an actual 2.5km delivery radius around a q-commerce hub
_SEED_ZONES = [
    {
        "id": 1, "name": "Koramangala Dark Store",
        "pincode": "560034", "city": "Bengaluru",
        "latitude": 12.9352, "longitude": 77.6245,
        "base_risk_multiplier": 1.2,
    },
    {
        "id": 2, "name": "Indiranagar Hub",
        "pincode": "560038", "city": "Bengaluru",
        "latitude": 12.9784, "longitude": 77.6408,
        "base_risk_multiplier": 1.0,
    },
    {
        "id": 3, "name": "Whitefield Spoke",
        "pincode": "560066", "city": "Bengaluru",
        "latitude": 12.9698, "longitude": 77.7500,
        "base_risk_multiplier": 1.5,
    },
    {
        "id": 4, "name": "HSR Layout Store",
        "pincode": "560102", "city": "Bengaluru",
        "latitude": 12.9116, "longitude": 77.6389,
        "base_risk_multiplier": 0.9,
    },
    {
        "id": 5, "name": "Marathahalli Hub",
        "pincode": "560037", "city": "Bengaluru",
        "latitude": 12.9591, "longitude": 77.7009,
        "base_risk_multiplier": 1.3,
    },
    {
        "id": 6, "name": "Electronic City Store",
        "pincode": "560100", "city": "Bengaluru",
        "latitude": 12.8458, "longitude": 77.6603,
        "base_risk_multiplier": 1.4,
    },
    {
        "id": 7, "name": "JP Nagar Dark Store",
        "pincode": "560078", "city": "Bengaluru",
        "latitude": 12.9063, "longitude": 77.5857,
        "base_risk_multiplier": 1.1,
    },
    {
        "id": 8, "name": "Coimbatore RS Puram",
        "pincode": "641002", "city": "Coimbatore",
        "latitude": 11.0014, "longitude": 76.9628,
        "base_risk_multiplier": 1.1,
    },
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup: create tables, seed zones, start background jobs.
    Zones use upsert-style logic so re-deploys don't duplicate data.
    """
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        for z in _SEED_ZONES:
            existing = db.query(Zone).filter(Zone.id == z["id"]).first()
            if not existing:
                db.add(Zone(**z))
            else:
                # Update coordinates on re-deploy in case they were corrected
                existing.latitude = z["latitude"]
                existing.longitude = z["longitude"]
                existing.city = z["city"]
        db.commit()
    finally:
        db.close()

    # Start background jobs — policy expiry every hour, weather cache every 15 minutes
    from app.services.scheduler import start_scheduler, stop_scheduler
    start_scheduler()

    yield  # Application runs here

    stop_scheduler()


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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Routers imported after models to avoid circular imports
from app.routers import workers, policies, claims, admin  # noqa: E402
from app.routers.workers import zone_router               # noqa: E402
from app.routers.auth import router as auth_router        # noqa: E402

app.include_router(auth_router)
app.include_router(workers.router)
app.include_router(zone_router)
app.include_router(policies.router)
app.include_router(claims.router)
app.include_router(admin.router)


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
        "real_weather_api": settings.USE_REAL_WEATHER_API,
    }
