"""
HustleHalt — Workers Router

Endpoints:
  POST /api/v1/workers/register           — Onboard a new gig worker (legacy, no auth)
  POST /api/v1/workers/login              — Phone-only login (legacy, no auth)
  GET  /api/v1/workers                    — List all workers (admin/demo)
  GET  /api/v1/workers/{id}               — Get worker profile
  PATCH /api/v1/workers/{id}/zone         — Dynamic zone switch (Edge Case 3)
  GET  /api/v1/workers/{id}/dashboard     — Full Flutter home screen data in one call
  GET  /api/v1/zones                      — List available dark store zones
"""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.claim import Claim
from app.models.policy import Policy
from app.models.worker import Worker
from app.models.zone import Zone
from app.schemas.worker import WorkerRegister, WorkerLogin, WorkerOut, WorkerListOut, ZoneOut
from app.services.premium_engine import calculate_premium, get_consecutive_quiet_weeks, QUIET_WEEKS_THRESHOLD
from app.services.weather_service import fetch_zone_weather
from app.services.aqi_service import fetch_zone_aqi

router = APIRouter(prefix="/api/v1/workers", tags=["Workers"])
zone_router = APIRouter(prefix="/api/v1/zones", tags=["Zones"])


@zone_router.get("", response_model=list[ZoneOut], summary="List all dark store zones")
def list_zones(db: Session = Depends(get_db)):
    """Returns all available zones a worker can register with — used on the onboarding screen."""
    return db.query(Zone).all()


# ── Worker Registration (Legacy — use /auth/register for proper accounts) ─────
@router.post(
    "/register",
    response_model=WorkerOut,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new gig worker (no-auth legacy endpoint)",
)
def register_worker(data: WorkerRegister, db: Session = Depends(get_db)):
    """
    Quick registration with no password — kept for demo and smoke tests.
    For the Flutter app with full auth use POST /api/v1/auth/register instead.
    """
    zone = db.query(Zone).filter(Zone.id == data.zone_id).first()
    if not zone:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zone {data.zone_id} not found. Use GET /api/v1/zones to list zones.",
        )

    if db.query(Worker).filter(Worker.phone == data.phone).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A worker with this phone number is already registered.",
        )

    worker = Worker(
        name=data.name,
        phone=data.phone,
        upi_id=data.upi_id,
        zone_id=data.zone_id,
        enrollment_date=datetime.utcnow(),
        status="Active",
        trust_baseline_score=75.0,
    )
    db.add(worker)
    db.commit()
    db.refresh(worker)
    return _worker_to_schema(worker)


@router.post("/login", response_model=WorkerOut, summary="Login a gig worker by phone (legacy)")
def login_worker(data: WorkerLogin, db: Session = Depends(get_db)):
    """Phone-only login kept for smoke tests. Flutter app should use /auth/login."""
    worker = db.query(Worker).filter(Worker.phone == data.phone).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found. Please register first.",
        )
    return _worker_to_schema(worker)


@router.get("", response_model=WorkerListOut, summary="List all registered workers")
def list_workers(db: Session = Depends(get_db)):
    """Returns all workers — useful for the admin dashboard and demo."""
    workers = db.query(Worker).all()
    return {"total": len(workers), "workers": [_worker_to_schema(w) for w in workers]}


@router.get("/{worker_id}", response_model=WorkerOut, summary="Get worker profile by ID")
def get_worker(worker_id: int, db: Session = Depends(get_db)):
    """Returns a single worker profile including current cold-start status."""
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found.")
    return _worker_to_schema(worker)


# ── Dynamic Zone Switch — Edge Case 3 from README ────────────────────────────
class ZoneSwitchRequest(BaseModel):
    zone_id: int = Field(..., ge=1, description="New zone ID the worker is delivering from")


@router.patch("/{worker_id}/zone", summary="Switch worker's active delivery zone")
def switch_zone(worker_id: int, data: ZoneSwitchRequest, db: Session = Depends(get_db)):
    """
    Handles Edge Case 3: a worker picking up a guest shift at a different dark store.
    Their insurance coverage follows them to the new zone immediately.
    The Flutter app calls this when the platform app shows a new dispatch origin.
    """
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found.")

    new_zone = db.query(Zone).filter(Zone.id == data.zone_id).first()
    if not new_zone:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zone {data.zone_id} not found. Use GET /api/v1/zones to list zones.",
        )

    old_zone_name = worker.zone.name if worker.zone else "Unknown"
    worker.zone_id = data.zone_id
    db.commit()
    db.refresh(worker)

    return {
        "worker_id":     worker_id,
        "worker_name":   worker.name,
        "previous_zone": old_zone_name,
        "new_zone":      new_zone.name,
        "new_zone_id":   new_zone.id,
        "message":       f"Coverage zone updated. You're now delivering from {new_zone.name}. Your coverage follows you.",
    }


# ── Worker Dashboard — Single call for Flutter home screen ───────────────────
@router.get("/{worker_id}/dashboard", summary="Full dashboard data for Flutter home screen")
def worker_dashboard(worker_id: int, db: Session = Depends(get_db)):
    """
    Returns everything the Flutter home screen needs in one API call.
    Active policy, live weather, zone risk, last claim, Shield Credits, and coverage status.
    This saves the Flutter app from making 4–5 separate calls on load.
    """
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found.")

    zone = worker.zone

    # Active policy — the one the worker is currently covered under this week
    active_policy = (
        db.query(Policy)
        .filter(Policy.worker_id == worker_id, Policy.status == "Active")
        .first()
    )

    # Last claim across all their policies (most recent, regardless of status)
    last_claim = (
        db.query(Claim)
        .join(Policy)
        .filter(Policy.worker_id == worker_id)
        .order_by(Claim.created_at.desc())
        .first()
    )

    # Live weather for the worker's current zone
    weather = {}
    aqi = {}
    if zone and zone.latitude and zone.longitude:
        weather = fetch_zone_weather(zone.latitude, zone.longitude, zone.id)
        aqi = fetch_zone_aqi(zone.latitude, zone.longitude, zone.id)

    m_weather = weather.get("m_weather", 1.0)
    if m_weather >= 2.5:
        risk_level = "HIGH"
    elif m_weather >= 1.5:
        risk_level = "MEDIUM"
    else:
        risk_level = "LOW"

    # Shield Credits eligibility
    quiet_weeks = get_consecutive_quiet_weeks(worker_id, db)
    shield_eligible = quiet_weeks >= QUIET_WEEKS_THRESHOLD

    return {
        "worker": {
            "id":                   worker.id,
            "name":                 worker.name,
            "phone":                worker.phone,
            "upi_id":               worker.upi_id,
            "status":               worker.status,
            "cold_start_active":    worker.cold_start_active,
            "enrollment_date":      worker.enrollment_date,
            "trust_baseline_score": worker.trust_baseline_score,
        },
        "zone": {
            "id":           zone.id if zone else None,
            "name":         zone.name if zone else None,
            "pincode":      zone.pincode if zone else None,
            "risk_level":   risk_level,
        },
        "active_policy": {
            "id":               active_policy.id,
            "coverage_amount":  active_policy.coverage_amount,
            "premium_paid":     active_policy.premium_amount,
            "valid_until":      active_policy.end_date,
            "status":           active_policy.status,
        } if active_policy else None,
        "live_weather": {
            "rainfall_mm_hr":    weather.get("rainfall_mm_hr", 0.0),
            "temperature_c":     weather.get("temperature_c", 0.0),
            "wet_bulb_c":        weather.get("wet_bulb_c", 0.0),
            "humidity_pct":      weather.get("humidity_pct", 0.0),
            "condition":         weather.get("weather_condition", "Unknown"),
            "aqi":               aqi.get("aqi", 0),
            "aqi_category":      aqi.get("category", "Good"),
            "data_source":       weather.get("source", "mock"),
        },
        "last_claim": {
            "id":            last_claim.id,
            "status":        last_claim.status,
            "payout_amount": last_claim.payout_amount,
            "payout_pct":    last_claim.payout_percentage,
            "created_at":    last_claim.created_at,
            "event_type":    last_claim.trigger_event.event_type if last_claim.trigger_event else None,
        } if last_claim else None,
        "loyalty": {
            "consecutive_quiet_weeks": quiet_weeks,
            "shield_credits_eligible": shield_eligible,
            "weeks_until_eligible":    max(0, QUIET_WEEKS_THRESHOLD - quiet_weeks),
        },
    }


# ── Helper ─────────────────────────────────────────────────────────────────────
def _worker_to_schema(worker: Worker) -> dict:
    return {
        "id":                   worker.id,
        "name":                 worker.name,
        "phone":                worker.phone,
        "upi_id":               worker.upi_id,
        "zone_id":              worker.zone_id,
        "zone": {
            "id":                   worker.zone.id,
            "name":                 worker.zone.name,
            "pincode":              worker.zone.pincode,
            "base_risk_multiplier": worker.zone.base_risk_multiplier,
        } if worker.zone else None,
        "status":               worker.status,
        "trust_baseline_score": worker.trust_baseline_score,
        "enrollment_date":      worker.enrollment_date,
        "cold_start_active":    worker.cold_start_active,
    }
