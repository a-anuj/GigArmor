"""
HustleHalt — Auth Router
JWT-based registration and login for gig workers.

Endpoints:
  POST /api/v1/auth/register  — Create account (name, phone, email, password, zone)
  POST /api/v1/auth/login     — Login with email or phone + password → JWT
  GET  /api/v1/auth/me        — Return current authenticated worker profile
"""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import hash_password, verify_password, create_access_token
from app.database import get_db
from app.dependencies import get_current_worker
from app.models.worker import Worker
from app.models.zone import Zone
from app.schemas.auth import WorkerAuthRegister, WorkerAuthLogin, TokenOut

router = APIRouter(prefix="/api/v1/auth", tags=["Auth"])


# ── Register ──────────────────────────────────────────────────────────────────
@router.post(
    "/register",
    response_model=TokenOut,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new worker account",
)
def register(data: WorkerAuthRegister, db: Session = Depends(get_db)):
    """
    Create a new gig-worker account.

    - **phone** must be unique across the platform.
    - **email** must be unique across the platform.
    - **password** is bcrypt-hashed before storage; the plain-text is never persisted.
    - Returns a JWT access token alongside basic profile info.
    """
    # ── Validate zone ────────────────────────────────────────────────────────
    zone = db.query(Zone).filter(Zone.id == data.zone_id).first()
    if not zone:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zone {data.zone_id} not found. Use GET /api/v1/zones to list valid zones.",
        )

    # ── Uniqueness checks ────────────────────────────────────────────────────
    if db.query(Worker).filter(Worker.phone == data.phone).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A worker with this phone number is already registered.",
        )
    if db.query(Worker).filter(Worker.email == data.email).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A worker with this email address is already registered.",
        )

    # ── Create worker ────────────────────────────────────────────────────────
    worker = Worker(
        name=data.name,
        phone=data.phone,
        email=data.email,
        hashed_password=hash_password(data.password),
        q_commerce_platform=data.q_commerce_platform,
        upi_id=data.upi_id,
        zone_id=data.zone_id,
        enrollment_date=datetime.utcnow(),
        status="Active",
        trust_baseline_score=75.0,
    )
    db.add(worker)
    db.commit()
    db.refresh(worker)

    token = create_access_token(subject=worker.id)
    return TokenOut(
        access_token=token,
        worker_id=worker.id,
        name=worker.name,
        email=worker.email,
    )


# ── Login ─────────────────────────────────────────────────────────────────────
@router.post(
    "/login",
    response_model=TokenOut,
    summary="Login with email / phone + password",
)
def login(data: WorkerAuthLogin, db: Session = Depends(get_db)):
    """
    Authenticate a worker.

    - **identifier**: the worker's registered email **or** phone number.
    - **password**: plain-text password (compared against bcrypt hash).
    - Returns a JWT access token on success.
    - Returns HTTP 401 on wrong credentials (intentionally vague to prevent enumeration).
    """
    # Try to look up by email first, then by phone
    worker = (
        db.query(Worker).filter(Worker.email == data.identifier).first()
        or db.query(Worker).filter(Worker.phone == data.identifier).first()
    )

    invalid_credentials = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not worker:
        raise invalid_credentials

    if not worker.hashed_password:
        # Worker was created via the old (phone-only) endpoint — no password set.
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "This account has no password set. "
                "Please use the registration endpoint to set up credentials."
            ),
        )

    if not verify_password(data.password, worker.hashed_password):
        raise invalid_credentials

    token = create_access_token(subject=worker.id)
    return TokenOut(
        access_token=token,
        worker_id=worker.id,
        name=worker.name,
        email=worker.email,
    )


# ── Me ────────────────────────────────────────────────────────────────────────
@router.get(
    "/me",
    summary="Get current authenticated worker profile",
)
def me(current_worker: Worker = Depends(get_current_worker)):
    """
    Returns the profile of the currently authenticated worker.
    Requires a valid ``Bearer`` JWT in the ``Authorization`` header.
    """
    return {
        "id": current_worker.id,
        "name": current_worker.name,
        "phone": current_worker.phone,
        "email": current_worker.email,
        "q_commerce_platform": current_worker.q_commerce_platform,
        "upi_id": current_worker.upi_id,
        "zone_id": current_worker.zone_id,
        "status": current_worker.status,
        "trust_baseline_score": current_worker.trust_baseline_score,
        "enrollment_date": current_worker.enrollment_date,
        "cold_start_active": current_worker.cold_start_active,
    }
