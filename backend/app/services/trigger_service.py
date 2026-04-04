"""
HustleHalt — Trigger Processing Service (Phase 5)

Orchestrates the Zero-Touch claim lifecycle when a parametric event fires:
1. Create a TriggerEvent record
2. Find all active policies in the affected zone
3. Run trust scoring (fraud check) per policy
4. Generate Claim records with the appropriate status
5. Fire mock UPI webhook for Auto-Approved claims
"""
import logging
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.claim import Claim
from app.models.policy import Policy
from app.models.trigger_event import TriggerEvent
from app.models.worker import Worker
from app.services.trust_engine import calculate_trust_score, get_claim_status
from app.services.webhook_service import fire_upi_webhook

logger = logging.getLogger(__name__)

# Human-readable threshold descriptions per event type
_THRESHOLDS: dict[str, str] = {
    "Rain":    "Extreme Rainfall >35 mm/hr sustained for ≥45 minutes",
    "AQI":     "Severe AQI >300 sustained for ≥3 hours",
    "Outage":  "Platform Outage: 0 orders dispatched for ≥45 minutes",
    "Social":  "Social Disruption: Bandh/Curfew — weighted news + traffic consensus",
    "Heat":    "Extreme Heat: >38°C wet-bulb sustained for ≥4 hours",
}


def process_trigger_event(
    db: Session,
    zone_id: int,
    event_type: str,
    severity: str,
) -> dict:
    """
    Core zero-touch claim processor.

    Creates a TriggerEvent, generates Claims for all active zone policies,
    and fires UPI webhooks for auto-approved claims.

    Returns a summary dict suitable for the API response.
    """
    # ── Step 1: Create TriggerEvent ───────────────────────────────────────────
    trigger = TriggerEvent(
        zone_id=zone_id,
        event_type=event_type,
        severity=severity,
        start_time=datetime.utcnow(),
    )
    db.add(trigger)
    db.flush()  # Assign trigger.id before using it in claims

    logger.info(
        f"[Trigger #{trigger.id}] {event_type} ({severity}) fired in Zone {zone_id}"
    )

    # ── Step 2: Find all active policies in this zone ─────────────────────────
    active_policies = (
        db.query(Policy)
        .join(Worker)
        .filter(Worker.zone_id == zone_id, Policy.status == "Active")
        .all()
    )

    logger.info(
        f"[Trigger #{trigger.id}] {len(active_policies)} active policies found in Zone {zone_id}"
    )

    # ── Step 3–5: Score, classify, generate claims ────────────────────────────
    auto_approved = 0
    soft_hold     = 0
    blocked       = 0
    total_payout  = 0.0
    webhook_log   = []

    for policy in active_policies:
        worker = policy.worker

        # Trust Score Engine (fraud check)
        trust_score = calculate_trust_score(worker.id, worker.trust_baseline_score)
        status      = get_claim_status(trust_score)

        # Use actual enrolled coverage amount
        payout = policy.coverage_amount if status != "Blocked" else 0.0

        claim = Claim(
            policy_id=policy.id,
            trigger_event_id=trigger.id,
            payout_amount=payout,
            trust_score=trust_score,
            status=status,
            created_at=datetime.utcnow(),
        )
        db.add(claim)
        db.flush()  # Get claim.id for webhook reference

        if status == "Auto-Approved":
            auto_approved += 1
            total_payout  += payout
            result = fire_upi_webhook(worker.upi_id, payout, claim.id)
            webhook_log.append(result)
            logger.info(
                f"  ✅ Claim #{claim.id} → Auto-Approved | "
                f"Score={trust_score} | ₹{payout} → {worker.upi_id}"
            )
        elif status == "Soft-Hold":
            soft_hold += 1
            logger.info(
                f"  ⏳ Claim #{claim.id} → Soft-Hold | "
                f"Score={trust_score} | Awaiting re-verification"
            )
        else:
            blocked += 1
            logger.warning(
                f"  🚫 Claim #{claim.id} → Blocked | "
                f"Score={trust_score} | Suspected fraud"
            )

    db.commit()

    return {
        "trigger_event_id":      trigger.id,
        "zone_id":               zone_id,
        "event_type":            event_type,
        "severity":              severity,
        "threshold_description": _THRESHOLDS.get(event_type, "Unknown trigger type"),
        "active_policies_found": len(active_policies),
        "claims_generated":      len(active_policies),
        "auto_approved":         auto_approved,
        "soft_hold":             soft_hold,
        "blocked":               blocked,
        "total_payout":          round(total_payout, 2),
        "message": (
            f"Trigger processed. "
            f"{auto_approved} UPI payouts fired instantly, "
            f"{soft_hold} on soft-hold, "
            f"{blocked} blocked."
        ),
    }


def get_threshold_description(event_type: str) -> str:
    return _THRESHOLDS.get(event_type, "Unknown trigger type")
