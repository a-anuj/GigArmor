"""
HustleHalt — Trigger Processing Service

Orchestrates the full zero-touch claim lifecycle when a parametric event fires.
Payout percentages now follow README Section 6 exactly instead of always paying 100%.
Also handles simultaneous trigger dedup (6-hour window, highest value wins).
"""
import logging
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.models.claim import Claim
from app.models.policy import Policy
from app.models.trigger_event import TriggerEvent
from app.models.worker import Worker
from app.services.trust_engine import calculate_trust_score, get_claim_status
from app.services.webhook_service import fire_upi_webhook

logger = logging.getLogger(__name__)

# README Section 6 — threshold descriptions for API response transparency
_THRESHOLDS: dict[str, str] = {
    "Rain":   "Extreme Rainfall ≥35 mm/hr sustained for ≥45 minutes",
    "AQI":    "Severe AQI >300 sustained for ≥3 hours + dispatch suspension confirmed",
    "Outage": "Platform Outage: 0 orders dispatched for ≥45 minutes during peak hours",
    "Social": "Social Disruption: Bandh/Curfew — weighted oracle consensus ≥0.65",
    "Heat":   "Extreme Heat: wet-bulb ≥38°C sustained for ≥4 hours (April–June only)",
}


def _calculate_payout_percentage(event_type: str, duration_hours: float) -> float:
    """
    Returns the correct payout percentage per README Section 6.
    Rain is the only trigger where payout scales with duration — all others are fixed.

    Rain:   45min–2hr  → 25%
            2hr–4hr    → 50%
            >4hr       → 100%

    AQI:    fixed 50%
    Outage: fixed 25%
    Social: fixed 75%
    Heat:   fixed 50%
    """
    if event_type == "Rain":
        if duration_hours >= 4.0:
            return 100.0
        elif duration_hours >= 2.0:
            return 50.0
        else:
            # Minimum qualifying duration is 0.75 hours (45 minutes)
            return 25.0
    elif event_type == "AQI":
        return 50.0
    elif event_type == "Outage":
        return 25.0
    elif event_type == "Social":
        return 75.0
    elif event_type == "Heat":
        return 50.0
    else:
        return 100.0


def _has_overlapping_trigger(
    db: Session, policy_id: int, event_type: str, now: datetime
) -> bool:
    """
    Checks whether a higher-or-equal value trigger already fired for this policy
    within the last 6 hours (the simultaneous trigger dedup window from README Section 8.4).

    If a Rain (100%) trigger already exists in the window, a Social (75%) trigger
    that fires simultaneously won't create a second payout.
    """
    six_hours_ago = now - timedelta(hours=6)
    payout_rank = {"Rain": 4, "Social": 3, "AQI": 2, "Heat": 2, "Outage": 1}
    incoming_rank = payout_rank.get(event_type, 0)

    recent_claims = (
        db.query(Claim)
        .join(TriggerEvent)
        .filter(
            Claim.policy_id == policy_id,
            Claim.created_at >= six_hours_ago,
            Claim.status != "Blocked",
        )
        .all()
    )

    for claim in recent_claims:
        existing_rank = payout_rank.get(claim.trigger_event.event_type, 0)
        if existing_rank >= incoming_rank:
            # A payout of equal or higher value already exists in this window
            return True

    return False


def _weekly_coverage_remaining(db: Session, policy_id: int, coverage_amount: float) -> float:
    """
    README Section 6: weekly coverage is capped at 100% of coverage_amount.
    Returns how much rupee coverage is still available this policy week.
    """
    already_paid = (
        db.query(Claim)
        .filter(
            Claim.policy_id == policy_id,
            Claim.status.in_(["Auto-Approved", "Soft-Hold"]),
        )
        .all()
    )
    total_committed = sum(c.payout_amount for c in already_paid)
    return max(0.0, coverage_amount - total_committed)


def process_trigger_event(
    db: Session,
    zone_id: int,
    event_type: str,
    severity: str,
    duration_hours: float = 1.0,
    raw_value: float = None,
    confidence_score: float = None,
) -> dict:
    """
    Core zero-touch claim processor.
    1. Create TriggerEvent record with duration and raw measurement
    2. Find all active policies in the affected zone
    3. Deduplicate against recent triggers (6-hour window)
    4. Calculate correct payout percentage per event type and duration
    5. Cap against remaining weekly coverage
    6. Run trust scoring per policy
    7. Generate Claim records and fire UPI webhooks for auto-approved claims
    """
    now = datetime.utcnow()

    trigger = TriggerEvent(
        zone_id=zone_id,
        event_type=event_type,
        severity=severity,
        duration_hours=duration_hours,
        raw_value=raw_value,
        confidence_score=confidence_score,
        start_time=now,
    )
    db.add(trigger)
    db.flush()  # Get trigger.id before we reference it in claims

    logger.info(
        f"[Trigger #{trigger.id}] {event_type} ({severity}) fired in Zone {zone_id} "
        f"| duration={duration_hours}h | raw_value={raw_value}"
    )

    # Find all active policies for workers in this zone
    active_policies = (
        db.query(Policy)
        .join(Worker)
        .filter(Worker.zone_id == zone_id, Policy.status == "Active")
        .all()
    )

    logger.info(f"[Trigger #{trigger.id}] {len(active_policies)} active policies found in Zone {zone_id}")

    payout_pct = _calculate_payout_percentage(event_type, duration_hours)

    auto_approved = 0
    soft_hold = 0
    blocked = 0
    deduped = 0
    total_payout = 0.0
    webhook_log = []

    for policy in active_policies:
        worker = policy.worker

        # Skip if a higher-value trigger already paid out in the 6-hour window
        if _has_overlapping_trigger(db, policy.id, event_type, now):
            deduped += 1
            logger.info(
                f"  ⏭  Policy #{policy.id} skipped — higher-value trigger already exists in 6hr window"
            )
            continue

        # Check weekly coverage cap — can't pay more than 100% total across all triggers
        remaining = _weekly_coverage_remaining(db, policy.id, policy.coverage_amount)
        if remaining <= 0:
            deduped += 1
            logger.info(
                f"  ⏭  Policy #{policy.id} skipped — weekly coverage cap already reached"
            )
            continue

        # Rupee payout for this specific trigger event
        raw_payout = policy.coverage_amount * (payout_pct / 100.0)
        payout = min(raw_payout, remaining)  # Never exceed what's left this week

        trust_score = calculate_trust_score(worker.id, worker.trust_baseline_score)
        status = get_claim_status(trust_score)

        # Blocked claims don't pay out
        if status == "Blocked":
            payout = 0.0

        # 72-hour appeal window for blocked claims — worker can dispute within this time
        appeal_deadline = None
        if status == "Blocked":
            appeal_deadline = now + timedelta(hours=72)

        claim = Claim(
            policy_id=policy.id,
            trigger_event_id=trigger.id,
            payout_percentage=payout_pct if status != "Blocked" else 0.0,
            payout_amount=round(payout, 2),
            trust_score=trust_score,
            status=status,
            appeal_deadline=appeal_deadline,
            created_at=now,
        )
        db.add(claim)
        db.flush()

        if status == "Auto-Approved":
            auto_approved += 1
            total_payout += payout
            result = fire_upi_webhook(worker.upi_id, payout, claim.id)
            webhook_log.append(result)
            logger.info(
                f"  ✅ Claim #{claim.id} → Auto-Approved | Score={trust_score:.1f} | "
                f"₹{payout:.0f} ({payout_pct:.0f}%) → {worker.upi_id}"
            )
        elif status == "Soft-Hold":
            soft_hold += 1
            logger.info(
                f"  ⏳ Claim #{claim.id} → Soft-Hold | Score={trust_score:.1f} | "
                f"₹{payout:.0f} awaiting re-verification"
            )
        else:
            blocked += 1
            logger.warning(
                f"  🚫 Claim #{claim.id} → Blocked | Score={trust_score:.1f} | "
                f"72hr appeal window opens"
            )

    db.commit()

    return {
        "trigger_event_id":       trigger.id,
        "zone_id":                zone_id,
        "event_type":             event_type,
        "severity":               severity,
        "duration_hours":         duration_hours,
        "payout_percentage":      payout_pct,
        "threshold_description":  _THRESHOLDS.get(event_type, "Unknown trigger type"),
        "active_policies_found":  len(active_policies),
        "claims_generated":       auto_approved + soft_hold + blocked,
        "deduped_skipped":        deduped,
        "auto_approved":          auto_approved,
        "soft_hold":              soft_hold,
        "blocked":                blocked,
        "total_payout":           round(total_payout, 2),
        "message": (
            f"Trigger processed. {auto_approved} instant UPI payouts (₹{total_payout:.0f} total), "
            f"{soft_hold} on soft-hold, {blocked} blocked, {deduped} deduped/capped."
        ),
    }


def get_threshold_description(event_type: str) -> str:
    return _THRESHOLDS.get(event_type, "Unknown trigger type")
