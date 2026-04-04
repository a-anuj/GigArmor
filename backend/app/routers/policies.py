"""
GigArmor — Policies Router (Phase 3 & 4)

Endpoints:
  GET  /api/v1/policies/quote/{worker_id}  — Dynamic premium quote
  POST /api/v1/policies/enroll             — Enroll in this week's policy
  GET  /api/v1/policies/worker/{worker_id} — List worker's policy history
"""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.policy import Policy
from app.models.worker import Worker
from app.schemas.policy import (
    PolicyEnroll,
    PolicyOut,
    PolicyEnrollOut,
    PolicyListOut,
    PremiumQuote,
)
from app.services.premium_engine import (
    calculate_premium,
    get_consecutive_quiet_weeks,
    QUIET_WEEKS_THRESHOLD,
)

router = APIRouter(prefix="/api/v1/policies", tags=["Policies"])


# ── Phase 3: Dynamic Premium Quote ───────────────────────────────────────────
@router.get(
    "/quote/{worker_id}",
    response_model=PremiumQuote,
    summary="Get dynamic premium quote for upcoming week",
)
def get_premium_quote(worker_id: int, db: Session = Depends(get_db)):
    """
    Calculates and returns the upcoming week's parametric premium for a worker.

    **Formula**: `max(19, min(99, R_base × M_weather × M_social × H_expected × M_coldstart))`

    The response includes a full calculation breakdown (multipliers, conditions,
    shield credits eligibility) — useful for the mobile app transparency screen.
    """
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {worker_id} not found.",
        )

    zone = worker.zone
    consecutive_quiet = get_consecutive_quiet_weeks(worker_id, db)
    shield_credits = consecutive_quiet >= QUIET_WEEKS_THRESHOLD

    quote = calculate_premium(
        zone_id=worker.zone_id,
        base_risk_multiplier=zone.base_risk_multiplier,
        enrollment_date=worker.enrollment_date,
        shield_credits=shield_credits,
    )

    message_parts = []
    if quote["cold_start_active"]:
        message_parts.append("🆕 Cold-start premium (first 2 weeks, M=1.2 applied)")
    if quote["shield_credits_applied"]:
        message_parts.append(
            f"🛡️ Shield Credits active! 20% discount (₹{quote['discount_amount']:.0f} off) "
            f"after {consecutive_quiet} quiet week(s)"
        )
    if not message_parts:
        message_parts.append("✅ Standard weekly premium")

    return {
        **quote,
        "worker_id":              worker_id,
        "worker_name":            worker.name,
        "zone_id":                worker.zone_id,
        "zone_name":              zone.name,
        "consecutive_quiet_weeks": consecutive_quiet,
        "message":                " | ".join(message_parts),
    }


# ── Phase 4: Policy Enrollment ────────────────────────────────────────────────
@router.post(
    "/enroll",
    response_model=PolicyEnrollOut,
    status_code=status.HTTP_201_CREATED,
    summary="Enroll in this week's parametric insurance policy",
)
def enroll_policy(data: PolicyEnroll, db: Session = Depends(get_db)):
    """
    Creates an **Active** weekly insurance policy for the worker.

    - Premium is calculated dynamically using the current zone's weather/social data.
    - Coverage is fixed at ₹1,200 (parametric — no claims form needed).
    - **Loyalty / Shield Credits**: If the worker has 4+ consecutive quiet weeks,
      a 20% discount (max ₹99) is applied automatically.
    - Prevents duplicate enrollment: returns 400 if an active policy already exists.
    """
    worker = db.query(Worker).filter(Worker.id == data.worker_id).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {data.worker_id} not found.",
        )

    if worker.status != "Active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Worker account is {worker.status}. Only Active workers can enroll.",
        )

    # Prevent double enrollment
    existing_active = (
        db.query(Policy)
        .filter(Policy.worker_id == data.worker_id, Policy.status == "Active")
        .first()
    )
    if existing_active:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"Worker already has an active policy (ID: {existing_active.id}) "
                f"valid until {existing_active.end_date.date()}."
            ),
        )

    # Loyalty check
    zone = worker.zone
    consecutive_quiet = get_consecutive_quiet_weeks(data.worker_id, db)
    shield_credits = consecutive_quiet >= QUIET_WEEKS_THRESHOLD

    # Calculate premium
    quote = calculate_premium(
        zone_id=worker.zone_id,
        base_risk_multiplier=zone.base_risk_multiplier,
        enrollment_date=worker.enrollment_date,
        shield_credits=shield_credits,
    )

    now = datetime.utcnow()
    policy = Policy(
        worker_id=data.worker_id,
        start_date=now,
        end_date=now + timedelta(days=7),
        premium_amount=quote["premium"],
        coverage_amount=quote["coverage_amount"],
        status="Active",
    )
    db.add(policy)
    db.commit()
    db.refresh(policy)

    message_parts = [f"✅ Policy #{policy.id} created. Coverage: ₹{quote['coverage_amount']:.0f}."]
    if quote["shield_credits_applied"]:
        message_parts.append(
            f"🛡️ Shield Credits discount applied: -₹{quote['discount_amount']:.0f}"
        )
    if quote["cold_start_active"]:
        message_parts.append("🆕 Cold-start period active — premium includes 1.2× multiplier.")

    return {
        "policy": policy,
        "quote_used": {
            **quote,
            "worker_id":               data.worker_id,
            "worker_name":             worker.name,
            "zone_id":                 worker.zone_id,
            "zone_name":               zone.name,
            "consecutive_quiet_weeks": consecutive_quiet,
            "message":                 " | ".join(message_parts),
        },
        "message": " | ".join(message_parts),
    }


# ── Policy History ────────────────────────────────────────────────────────────
@router.get(
    "/worker/{worker_id}",
    response_model=PolicyListOut,
    summary="Get all policies for a worker",
)
def list_worker_policies(worker_id: int, db: Session = Depends(get_db)):
    """Returns all policies (active + expired) for a worker, newest first."""
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {worker_id} not found.",
        )

    policies = (
        db.query(Policy)
        .filter(Policy.worker_id == worker_id)
        .order_by(Policy.start_date.desc())
        .all()
    )
    return {"total": len(policies), "policies": policies}
