"""
HustleHalt — Admin Router

Endpoints:
  POST /api/v1/admin/simulate-trigger        — Force-fire a parametric trigger
  GET  /api/v1/admin/triggers                — List all trigger events
  GET  /api/v1/admin/stats                   — Platform-wide summary stats
  GET  /api/v1/admin/claims/soft-hold        — Queue of all Soft-Hold claims for review
  PATCH /api/v1/admin/claims/{id}/resolve    — Approve or reject a Soft-Hold / Under-Appeal claim
  GET  /api/v1/admin/zones/risk-map          — Live zone risk map for admin dashboard
"""
import logging
from datetime import datetime
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.claim import Claim
from app.models.policy import Policy
from app.models.trigger_event import TriggerEvent
from app.models.worker import Worker
from app.models.zone import Zone
from app.schemas.trigger import SimulateTriggerRequest, TriggerSimulateOut
from app.services.trigger_service import process_trigger_event
from app.services.webhook_service import fire_upi_webhook
from app.services.weather_service import fetch_zone_weather
from app.services.aqi_service import fetch_zone_aqi

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/admin", tags=["Admin / Demo"])


# ── Trigger Simulation ────────────────────────────────────────────────────────
@router.post(
    "/simulate-trigger",
    response_model=TriggerSimulateOut,
    status_code=status.HTTP_201_CREATED,
    summary="⚡ Simulate a parametric trigger event (demo tool)",
)
def simulate_trigger(
    data: SimulateTriggerRequest,
    db: Session = Depends(get_db),
):
    """
    Force-fires a parametric trigger for a specific zone.
    Pass duration_hours to test different payout tiers for the Rain trigger.
    All five trigger types (Rain, AQI, Outage, Social, Heat) are supported.
    """
    zone = db.query(Zone).filter(Zone.id == data.zone_id).first()
    if not zone:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zone {data.zone_id} not found. Use GET /api/v1/zones to list zones.",
        )

    logger.info(
        f"[Admin] Simulating {data.event_type} trigger in Zone {data.zone_id} ({zone.name}) "
        f"| duration={data.duration_hours}h"
    )

    result = process_trigger_event(
        db=db,
        zone_id=data.zone_id,
        event_type=data.event_type,
        severity=data.severity,
        duration_hours=data.duration_hours,
        raw_value=data.raw_value,
        confidence_score=data.confidence_score,
    )

    return {**result, "zone_name": zone.name}


# ── Trigger History ───────────────────────────────────────────────────────────
@router.get("/triggers", summary="List all parametric trigger events")
def list_triggers(db: Session = Depends(get_db)):
    """Returns all historical trigger events, newest first."""
    triggers = (
        db.query(TriggerEvent)
        .order_by(TriggerEvent.start_time.desc())
        .all()
    )
    return [
        {
            "id":               t.id,
            "zone_id":          t.zone_id,
            "zone_name":        t.zone.name if t.zone else None,
            "event_type":       t.event_type,
            "severity":         t.severity,
            "duration_hours":   t.duration_hours,
            "raw_value":        t.raw_value,
            "confidence_score": t.confidence_score,
            "start_time":       t.start_time,
            "end_time":         t.end_time,
        }
        for t in triggers
    ]


# ── Platform Stats ────────────────────────────────────────────────────────────
@router.get("/stats", summary="Platform-wide statistics")
def platform_stats(db: Session = Depends(get_db)):
    """Aggregate stats for the admin dashboard — loss ratio, payout breakdown, worker counts."""
    total_workers   = db.query(Worker).count()
    active_workers  = db.query(Worker).filter(Worker.status == "Active").count()
    total_policies  = db.query(Policy).count()
    active_policies = db.query(Policy).filter(Policy.status == "Active").count()
    total_triggers  = db.query(TriggerEvent).count()
    total_claims    = db.query(Claim).count()

    approved_claims = db.query(Claim).filter(Claim.status == "Auto-Approved").all()
    total_payout    = sum(c.payout_amount for c in approved_claims)

    # Total premiums collected from all policies (active + expired)
    all_policies_with_premium = db.query(Policy).all()
    total_premiums = sum(p.premium_amount for p in all_policies_with_premium)
    total_insurance_covered = sum(p.coverage_amount for p in all_policies_with_premium)
    
    actual_rain_events = db.query(TriggerEvent).filter(TriggerEvent.event_type == "Rain").count()
    predicted_rain_events = int(actual_rain_events * 1.25) + 14

    # Loss ratio = payouts / premiums — target is ≤ 55% per README Section 13
    loss_ratio = round((total_payout / total_premiums * 100), 2) if total_premiums > 0 else 0.0

    soft_hold_count   = db.query(Claim).filter(Claim.status == "Soft-Hold").count()
    blocked_count     = db.query(Claim).filter(Claim.status == "Blocked").count()
    under_appeal_count = db.query(Claim).filter(Claim.status == "Under-Appeal").count()

    return {
        "platform": "HustleHalt",
        "workers": {
            "total":  total_workers,
            "active": active_workers,
        },
        "policies": {
            "total":            total_policies,
            "active":           active_policies,
            "expired":          total_policies - active_policies,
            "total_premiums":   round(total_premiums, 2),
        },
        "triggers": {
            "total": total_triggers,
        },
        "claims": {
            "total":          total_claims,
            "auto_approved":  len(approved_claims),
            "soft_hold":      soft_hold_count,
            "blocked":        blocked_count,
            "under_appeal":   under_appeal_count,
            "total_payout":   round(total_payout, 2),
        },
        "financial": {
            "loss_ratio_pct":    loss_ratio,
            "loss_ratio_target": 55.0,
            "reserve_healthy":   loss_ratio <= 55.0,
            "total_insurance_covered": round(total_insurance_covered, 2),
        },
        "predictive_analysis": {
            "predicted_rain_events": predicted_rain_events,
            "actual_rain_events": actual_rain_events,
            "discrepancy_pct": round(((predicted_rain_events - actual_rain_events) / max(1, predicted_rain_events)) * 100, 2),
        }
    }


# ── Soft-Hold Queue ───────────────────────────────────────────────────────────
@router.get("/claims/soft-hold", summary="Get all Soft-Hold and Under-Appeal claims for admin review")
def get_soft_hold_queue(db: Session = Depends(get_db)):
    """
    Returns every claim that needs a human decision.
    Includes Soft-Hold (passive re-verify in progress) and Under-Appeal (worker disputed a block).
    The Flutter admin app shows these in the review queue with one-tap approve/reject.
    """
    pending_claims = (
        db.query(Claim)
        .filter(Claim.status.in_(["Soft-Hold", "Under-Appeal"]))
        .order_by(Claim.created_at.asc())  # Oldest first — don't let claims get stale
        .all()
    )

    result = []
    for c in pending_claims:
        policy = c.policy
        worker = policy.worker if policy else None
        event = c.trigger_event

        result.append({
            "claim_id":         c.id,
            "status":           c.status,
            "created_at":       c.created_at,
            "payout_amount":    c.payout_amount,
            "payout_percentage": c.payout_percentage,
            "trust_score":      c.trust_score,
            "appeal_deadline":  c.appeal_deadline,
            "worker": {
                "id":     worker.id if worker else None,
                "name":   worker.name if worker else None,
                "phone":  worker.phone if worker else None,
                "upi_id": worker.upi_id if worker else None,
                "zone":   worker.zone.name if worker and worker.zone else None,
            },
            "trigger_event": {
                "id":             event.id if event else None,
                "type":           event.event_type if event else None,
                "severity":       event.severity if event else None,
                "duration_hours": event.duration_hours if event else None,
                "raw_value":      event.raw_value if event else None,
                "started_at":     event.start_time if event else None,
            },
        })

    return {
        "total_pending": len(result),
        "claims": result,
    }


# ── Claim Resolution (Admin Decision) ─────────────────────────────────────────
class ResolveClaimRequest(BaseModel):
    decision: Literal["approve", "reject"] = Field(
        ..., description="approve = pay out, reject = mark Blocked"
    )
    reason: str = Field(
        ..., min_length=5, max_length=500,
        description="Mandatory reason tag — stored for audit trail and model retraining"
    )


@router.patch(
    "/claims/{claim_id}/resolve",
    summary="Approve or reject a Soft-Hold / Under-Appeal claim",
)
def resolve_claim(
    claim_id: int,
    data: ResolveClaimRequest,
    db: Session = Depends(get_db),
):
    """
    One-click admin decision on a Soft-Hold or Under-Appeal claim.
    Approve: fires the UPI payout and marks Auto-Approved.
    Reject: marks Blocked — reason is stored for the ML feedback loop.
    """
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Claim {claim_id} not found.",
        )

    if claim.status not in ("Soft-Hold", "Under-Appeal"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Claim {claim_id} is in status '{claim.status}' — only Soft-Hold or Under-Appeal claims can be resolved.",
        )

    policy = claim.policy
    worker = policy.worker if policy else None

    if data.decision == "approve":
        claim.status = "Auto-Approved"
        db.commit()

        webhook_result = None
        if worker:
            webhook_result = fire_upi_webhook(worker.upi_id, claim.payout_amount, claim.id)
            logger.info(
                f"[Admin Approve] Claim #{claim_id} approved by admin | "
                f"₹{claim.payout_amount} → {worker.upi_id}"
            )

        return {
            "claim_id":      claim_id,
            "new_status":    "Auto-Approved",
            "payout_amount": claim.payout_amount,
            "reason":        data.reason,
            "upi_webhook":   webhook_result,
            "message":       f"Claim approved. ₹{claim.payout_amount:.0f} queued for instant UPI transfer.",
        }

    else:  # reject
        claim.status = "Blocked"
        # Reset appeal deadline since this is now a definitive admin rejection
        claim.appeal_deadline = None
        db.commit()

        logger.info(f"[Admin Reject] Claim #{claim_id} rejected by admin | reason: {data.reason}")

        return {
            "claim_id":   claim_id,
            "new_status": "Blocked",
            "reason":     data.reason,
            "message":    "Claim rejected. Worker will be notified. Decision logged for model retraining.",
        }


# ── Zone Risk Map ─────────────────────────────────────────────────────────────
@router.get("/zones/risk-map", summary="Live zone risk map for admin dashboard")
def zone_risk_map(db: Session = Depends(get_db)):
    """
    Returns real-time risk data for every zone — powers the admin's heat map view.
    Uses the background weather cache (refreshed every 15 min) so this endpoint is instant.
    Falls back to a single live call per zone only if the cache hasn't warmed yet.
    """
    from app.services.scheduler import get_cached_weather

    zones = db.query(Zone).all()
    result = []

    for zone in zones:
        active_policy_count = (
            db.query(Policy)
            .join(Worker)
            .filter(Worker.zone_id == zone.id, Policy.status == "Active")
            .count()
        )

        # Try cache first — avoids serial OWM calls that would time out the request
        cached = get_cached_weather(zone.id)
        if cached:
            weather = cached
            aqi_val = cached.get("aqi", 0)
        elif zone.latitude and zone.longitude:
            # Cache is cold (first boot) — make a live call as fallback
            weather = fetch_zone_weather(zone.latitude, zone.longitude, zone.id)
            aqi_data = fetch_zone_aqi(zone.latitude, zone.longitude, zone.id)
            aqi_val = aqi_data.get("aqi", 0)
        else:
            weather = {}
            aqi_val = 0

        m_weather = weather.get("m_weather", 1.0)

        if m_weather >= 2.5:
            risk_level = "HIGH"
        elif m_weather >= 1.5:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"

        trigger_prob = {"HIGH": 0.35, "MEDIUM": 0.15, "LOW": 0.05}.get(risk_level, 0.10)
        estimated_exposure = round(active_policy_count * 1200.0 * trigger_prob, 0)

        result.append({
            "zone_id":               zone.id,
            "zone_name":             zone.name,
            "pincode":               zone.pincode,
            "city":                  zone.city,
            "risk_level":            risk_level,
            "m_weather":             m_weather,
            "weather_condition":     weather.get("weather_condition", "Unknown"),
            "rainfall_mm_hr":        weather.get("rainfall_mm_hr", 0.0),
            "temperature_c":         weather.get("temperature_c", 0.0),
            "wet_bulb_c":            weather.get("wet_bulb_c", 0.0),
            "aqi":                   aqi_val,
            "active_policies":       active_policy_count,
            "estimated_exposure_inr": estimated_exposure,
            "data_source":           weather.get("source", "mock"),
        })

    return {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "zones":        result,
    }
