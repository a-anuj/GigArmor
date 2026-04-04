"""
HustleHalt — Workers Router (Phase 2)

Endpoints:
  POST /api/v1/workers/register  — Onboard a new gig worker
  GET  /api/v1/workers           — List all workers (admin/demo)
  GET  /api/v1/workers/{id}      — Get worker profile
  GET  /api/v1/zones             — List available zones
"""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.worker import Worker
from app.models.zone import Zone
from app.schemas.worker import WorkerRegister, WorkerLogin, WorkerOut, WorkerListOut, ZoneOut

router = APIRouter(prefix="/api/v1/workers", tags=["Workers"])

# ── Zones endpoint (lives here since zones are worker-facing) ─────────────────
zone_router = APIRouter(prefix="/api/v1/zones", tags=["Zones"])


@zone_router.get("", response_model=list[ZoneOut], summary="List all dark store zones")
def list_zones(db: Session = Depends(get_db)):
    """Returns all available dark store zones a worker can register with."""
    return db.query(Zone).all()


# ── Worker Endpoints ──────────────────────────────────────────────────────────
@router.post(
    "/register",
    response_model=WorkerOut,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new gig worker",
)
def register_worker(data: WorkerRegister, db: Session = Depends(get_db)):
    """
    Onboards a new gig worker onto HustleHalt.

    **Cold-Start Logic**: Workers enrolled for ≤14 days receive a M_coldstart = 1.2
    premium multiplier (higher risk, no behavioural baseline). This is automatically
    calculated from the `enrollment_date` stamped at registration — no flag needed.

    Returns the worker profile including whether cold-start is currently active.
    """
    # Validate zone exists
    zone = db.query(Zone).filter(Zone.id == data.zone_id).first()
    if not zone:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zone {data.zone_id} not found. Use GET /api/v1/zones to list zones.",
        )

    # Check phone uniqueness
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

@router.post(
    "/login",
    response_model=WorkerOut,
    summary="Login a gig worker",
)
def login_worker(data: WorkerLogin, db: Session = Depends(get_db)):
    """Authenticates worker by phone number for the demo."""
    worker = db.query(Worker).filter(Worker.phone == data.phone).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found. Please register first.",
        )
    return _worker_to_schema(worker)


@router.get(
    "",
    response_model=WorkerListOut,
    summary="List all registered workers",
)
def list_workers(db: Session = Depends(get_db)):
    """Returns all workers (useful for admin dashboard / demo)."""
    workers = db.query(Worker).all()
    return {
        "total":   len(workers),
        "workers": [_worker_to_schema(w) for w in workers],
    }


@router.get(
    "/{worker_id}",
    response_model=WorkerOut,
    summary="Get worker profile by ID",
)
def get_worker(worker_id: int, db: Session = Depends(get_db)):
    """Returns a single worker's profile including cold-start status."""
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {worker_id} not found.",
        )
    return _worker_to_schema(worker)


# ── Helper ────────────────────────────────────────────────────────────────────
def _worker_to_schema(worker: Worker) -> dict:
    """Converts Worker ORM object → dict with computed cold_start_active."""
    return {
        "id":                   worker.id,
        "name":                 worker.name,
        "phone":                worker.phone,
        "upi_id":               worker.upi_id,
        "zone_id":              worker.zone_id,
        "zone": {
            "id": worker.zone.id,
            "name": worker.zone.name,
            "pincode": worker.zone.pincode,
            "base_risk_multiplier": worker.zone.base_risk_multiplier,
        } if worker.zone else None,
        "status":               worker.status,
        "trust_baseline_score": worker.trust_baseline_score,
        "enrollment_date":      worker.enrollment_date,
        "cold_start_active":    worker.cold_start_active,
    }
