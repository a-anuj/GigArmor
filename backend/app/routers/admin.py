"""
HustleHalt — Admin Router (Phase 5)

Endpoints:
  POST /api/v1/admin/simulate-trigger — Force-fire a parametric trigger for demo
  GET  /api/v1/admin/triggers         — List all trigger events
  GET  /api/v1/admin/stats            — Platform-wide summary stats
"""
import logging

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.claim import Claim
from app.models.policy import Policy
from app.models.trigger_event import TriggerEvent
from app.models.worker import Worker
from app.models.zone import Zone
from app.schemas.trigger import SimulateTriggerRequest, TriggerSimulateOut
from app.services.trigger_service import process_trigger_event

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/admin", tags=["Admin / Demo"])


@router.post(
    "/simulate-trigger",
    response_model=TriggerSimulateOut,
    status_code=status.HTTP_201_CREATED,
    summary="⚡ Simulate a parametric trigger event (demo tool)",
)
def simulate_trigger(
    data: SimulateTriggerRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """
    **Admin / Demo endpoint** — Force-fires a parametric trigger for a specific zone.

    Triggers supported:
    - `Rain`   → Extreme Rainfall >35 mm/hr for 45 min
    - `AQI`    → Severe AQI >300 for 3 hours
    - `Outage` → Platform Outage: 0 orders for 45 min
    - `Social` → Bandh / Curfew (news + traffic consensus)
    - `Heat`   → Extreme Heat >38°C wet-bulb for 4 hours

    For demo purposes, every trigger fires a **100% payout (₹1,200)** to keep
    the flow simple and understandable in the 2-minute video.

    The Zero-Touch claim process runs synchronously so results are visible immediately.
    """
    zone = db.query(Zone).filter(Zone.id == data.zone_id).first()
    if not zone:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zone {data.zone_id} not found. Use GET /api/v1/zones to list zones.",
        )

    logger.info(
        f"[Admin] Simulating {data.event_type} trigger in Zone {data.zone_id} ({zone.name})"
    )

    # Run zero-touch claim processing synchronously (instant demo feedback)
    result = process_trigger_event(
        db=db,
        zone_id=data.zone_id,
        event_type=data.event_type,
        severity=data.severity,
    )

    return {
        **result,
        "zone_name": zone.name,
    }


@router.get(
    "/triggers",
    summary="List all parametric trigger events",
)
def list_triggers(db: Session = Depends(get_db)):
    """Returns all historical trigger events, newest first."""
    triggers = (
        db.query(TriggerEvent)
        .order_by(TriggerEvent.start_time.desc())
        .all()
    )
    return [
        {
            "id":         t.id,
            "zone_id":    t.zone_id,
            "zone_name":  t.zone.name if t.zone else None,
            "event_type": t.event_type,
            "severity":   t.severity,
            "start_time": t.start_time,
            "end_time":   t.end_time,
        }
        for t in triggers
    ]


@router.get(
    "/stats",
    summary="Platform-wide statistics",
)
def platform_stats(db: Session = Depends(get_db)):
    """Returns aggregate stats for the admin dashboard / hackathon demo."""
    total_workers   = db.query(Worker).count()
    active_workers  = db.query(Worker).filter(Worker.status == "Active").count()
    total_policies  = db.query(Policy).count()
    active_policies = db.query(Policy).filter(Policy.status == "Active").count()
    total_triggers  = db.query(TriggerEvent).count()
    total_claims    = db.query(Claim).count()

    approved_claims = db.query(Claim).filter(Claim.status == "Auto-Approved").all()
    total_payout    = sum(c.payout_amount for c in approved_claims)

    soft_hold_count = db.query(Claim).filter(Claim.status == "Soft-Hold").count()
    blocked_count   = db.query(Claim).filter(Claim.status == "Blocked").count()

    return {
        "platform": "HustleHalt",
        "workers": {
            "total":  total_workers,
            "active": active_workers,
        },
        "policies": {
            "total":   total_policies,
            "active":  active_policies,
            "expired": total_policies - active_policies,
        },
        "triggers": {
            "total": total_triggers,
        },
        "claims": {
            "total":         total_claims,
            "auto_approved": len(approved_claims),
            "soft_hold":     soft_hold_count,
            "blocked":       blocked_count,
            "total_payout":  round(total_payout, 2),
        },
    }
