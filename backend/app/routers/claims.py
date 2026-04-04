"""
HustleHalt — Claims Router (Phase 5)

Endpoints:
  GET /api/v1/claims/worker/{worker_id}  — Worker polls for their claim status
  GET /api/v1/claims/{claim_id}          — Get a specific claim
"""
from fastapi import APIRouter, Depends, HTTPException, status
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
    The **Zero-Touch** mobile polling endpoint.

    Workers open the app and see that money has already arrived — without ever
    submitting a claim. New claims appear here automatically after a trigger fires.

    Returns all claims across all the worker's policies, newest first.
    """
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {worker_id} not found.",
        )

    # Join: Claims → Policies → Worker
    claims = (
        db.query(Claim)
        .join(Policy)
        .filter(Policy.worker_id == worker_id)
        .order_by(Claim.created_at.desc())
        .all()
    )

    total_payout = sum(
        c.payout_amount for c in claims if c.status == "Auto-Approved"
    )

    claim_list = []
    for c in claims:
        event = c.trigger_event
        claim_list.append(
            ClaimOut(
                id=c.id,
                policy_id=c.policy_id,
                trigger_event_id=c.trigger_event_id,
                payout_amount=c.payout_amount,
                trust_score=c.trust_score,
                status=c.status,
                created_at=c.created_at,
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


@router.get(
    "/{claim_id}",
    response_model=ClaimOut,
    summary="Get a specific claim by ID",
)
def get_claim(claim_id: int, db: Session = Depends(get_db)):
    """Returns the details of a single claim."""
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
        trust_score=claim.trust_score,
        status=claim.status,
        created_at=claim.created_at,
        event_type=event.event_type if event else None,
        event_severity=event.severity if event else None,
        zone_name=event.zone.name if event and event.zone else None,
        upi_webhook_fired=(claim.status == "Auto-Approved"),
    )
