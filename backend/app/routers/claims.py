"""
HustleHalt — Claims Router

Endpoints:
  GET  /api/v1/claims/worker/{worker_id}     — All claims for a worker (Flutter polling)
  GET  /api/v1/claims/{claim_id}             — Full claim detail
  GET  /api/v1/claims/{claim_id}/status      — Lightweight status poll (bandwidth-friendly)
  POST /api/v1/claims/{claim_id}/appeal      — Worker disputes a Blocked decision (72hr window)
"""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.claim import Claim
from app.models.policy import Policy
from app.models.worker import Worker
from app.schemas.claim import ClaimOut, ClaimListOut

router = APIRouter(prefix="/api/v1/claims", tags=["Claims"])


@router.get(
    "/worker/{worker_id}",
    response_model=ClaimListOut,
    summary="Get all claims for a worker (mobile polling endpoint)",
)
def get_worker_claims(worker_id: int, db: Session = Depends(get_db)):
    """
    The zero-touch mobile polling endpoint.
    Workers open the app and see that money has already arrived without ever submitting a claim.
    Claims appear here automatically after any parametric trigger fires for their zone.
    """
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {worker_id} not found.",
        )

    claims = (
        db.query(Claim)
        .join(Policy)
        .filter(Policy.worker_id == worker_id)
        .order_by(Claim.created_at.desc())
        .all()
    )

    total_payout = sum(c.payout_amount for c in claims if c.status == "Auto-Approved")

    claim_list = []
    for c in claims:
        event = c.trigger_event
        claim_list.append(
            ClaimOut(
                id=c.id,
                policy_id=c.policy_id,
                trigger_event_id=c.trigger_event_id,
                payout_amount=c.payout_amount,
                payout_percentage=c.payout_percentage,
                trust_score=c.trust_score,
                status=c.status,
                created_at=c.created_at,
                appeal_deadline=c.appeal_deadline,
                event_type=event.event_type if event else None,
                event_severity=event.severity if event else None,
                zone_name=event.zone.name if event and event.zone else None,
                upi_webhook_fired=(c.status == "Auto-Approved"),
            )
        )

    return {
        "worker_id":    worker_id,
        "worker_name":  worker.name,
        "total_claims": len(claim_list),
        "total_payout": round(total_payout, 2),
        "claims":       claim_list,
    }


@router.get("/{claim_id}", response_model=ClaimOut, summary="Get a specific claim by ID")
def get_claim(claim_id: int, db: Session = Depends(get_db)):
    """Returns the full detail of a single claim including trust score and event info."""
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Claim {claim_id} not found.",
        )
    event = claim.trigger_event
    return ClaimOut(
        id=claim.id,
        policy_id=claim.policy_id,
        trigger_event_id=claim.trigger_event_id,
        payout_amount=claim.payout_amount,
        payout_percentage=claim.payout_percentage,
        trust_score=claim.trust_score,
        status=claim.status,
        created_at=claim.created_at,
        appeal_deadline=claim.appeal_deadline,
        event_type=event.event_type if event else None,
        event_severity=event.severity if event else None,
        zone_name=event.zone.name if event and event.zone else None,
        upi_webhook_fired=(claim.status == "Auto-Approved"),
    )


@router.get("/{claim_id}/status", summary="Lightweight status poll — minimal payload")
def get_claim_status(claim_id: int, db: Session = Depends(get_db)):
    """
    Bandwidth-friendly status check — Flutter app polls this every 60s during soft-hold.
    Returns only status, payout amount, and appeal deadline. No heavy joins.
    """
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Claim {claim_id} not found.",
        )
    return {
        "claim_id":      claim.id,
        "status":        claim.status,
        "payout_amount": claim.payout_amount,
        "appeal_deadline": claim.appeal_deadline,
    }


# ── Worker Appeal — 72-hour window for Blocked claims ─────────────────────────
class AppealRequest(BaseModel):
    worker_id: int = Field(..., description="Must match the policy owner to prevent cross-appeals")
    reason: str = Field(..., min_length=10, max_length=1000, description="Worker's explanation")


@router.post("/{claim_id}/appeal", summary="Worker disputes a Blocked claim (72hr window)")
def appeal_claim(claim_id: int, data: AppealRequest, db: Session = Depends(get_db)):
    """
    Allows a worker to dispute a Blocked outcome within 72 hours.
    The claim moves to Under-Appeal and appears in the admin's soft-hold queue for review.
    Per README: 'Worker did not appeal within 72 hours' is labeled Fraud 0.70 confidence.
    """
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Claim {claim_id} not found.",
        )

    if claim.status != "Blocked":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Only Blocked claims can be appealed. This claim is currently '{claim.status}'.",
        )

    # Verify the worker owns this claim
    policy = claim.policy
    if not policy or policy.worker_id != data.worker_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only appeal your own claims.",
        )

    # 72-hour appeal window check
    if claim.appeal_deadline and datetime.utcnow() > claim.appeal_deadline:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="The 72-hour appeal window for this claim has closed.",
        )

    claim.status = "Under-Appeal"
    db.commit()

    return {
        "claim_id":   claim_id,
        "new_status": "Under-Appeal",
        "message":    "Your appeal has been submitted. An admin will review your claim. You'll be notified of the decision.",
        "reason_logged": data.reason,
    }
