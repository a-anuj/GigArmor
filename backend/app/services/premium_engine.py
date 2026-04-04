"""
GigArmor — Dynamic Premium Calculation Engine (Phase 3)

Formula:
  Premium = max(19, min(99, R_base × M_weather × M_social × H_expected × M_coldstart))

Where:
  R_base     = ₹5 (base rate)
  M_weather  = 1.0 (Clear) → 3.5 (Severe monsoon) — mocked per zone
  M_social   = 1.0 (Normal) → 2.0 (Bandh/Curfew)  — mocked per zone
  H_expected = 1.0 (constant for demo)
  M_coldstart= 1.2 if enrolled < 14 days, else 1.0
"""
from datetime import datetime

from sqlalchemy.orm import Session

# ── Constants ─────────────────────────────────────────────────────────────────
R_BASE: float = 5.0
H_EXPECTED: float = 1.0
COLD_START_DAYS: int = 14
COLD_START_MULTIPLIER: float = 1.2
PREMIUM_FLOOR: float = 19.0
PREMIUM_CEILING: float = 99.0
SHIELD_DISCOUNT_PCT: float = 0.20
SHIELD_DISCOUNT_CAP: float = 99.0   # Max discount ₹99
COVERAGE_AMOUNT: float = 1200.0
QUIET_WEEKS_THRESHOLD: int = 4      # Weeks before Shield Credits kick in

# ── Mock Weather Forecast Data (per zone) ─────────────────────────────────────
# Simulates calls to an external weather forecasting API
_ZONE_WEATHER: dict[int, dict] = {
    1: {"condition": "Heavy Rain",       "multiplier": 2.8},
    2: {"condition": "Partly Cloudy",    "multiplier": 1.3},
    3: {"condition": "Severe Monsoon",   "multiplier": 3.5},
    4: {"condition": "Clear",            "multiplier": 1.0},
    5: {"condition": "Moderate Rain",    "multiplier": 2.0},
    6: {"condition": "Thunderstorm",     "multiplier": 3.0},
    7: {"condition": "Hazy / Smoggy",   "multiplier": 1.8},
}

# ── Mock Social Disruption Data (per zone) ────────────────────────────────────
# Simulates weighted consensus: news API + traffic API
_ZONE_SOCIAL: dict[int, dict] = {
    1: {"condition": "Normal",                    "multiplier": 1.0},
    2: {"condition": "Traffic Disruption",         "multiplier": 1.4},
    3: {"condition": "Bandh — Full shutdown",      "multiplier": 2.0},
    4: {"condition": "Normal",                    "multiplier": 1.0},
    5: {"condition": "Political Protest",          "multiplier": 1.6},
    6: {"condition": "Curfew-like restrictions",   "multiplier": 1.9},
    7: {"condition": "Normal",                    "multiplier": 1.0},
}

_DEFAULT_WEATHER = {"condition": "Moderate Overcast", "multiplier": 1.5}
_DEFAULT_SOCIAL  = {"condition": "Normal",             "multiplier": 1.0}


# ── API Mock Functions ────────────────────────────────────────────────────────
def get_weather_multiplier(zone_id: int) -> tuple[float, str]:
    """Mock weather forecast API call for a given zone."""
    data = _ZONE_WEATHER.get(zone_id, _DEFAULT_WEATHER)
    return data["multiplier"], data["condition"]


def get_social_multiplier(zone_id: int) -> tuple[float, str]:
    """Mock social disruption consensus (news + traffic API) for a given zone."""
    data = _ZONE_SOCIAL.get(zone_id, _DEFAULT_SOCIAL)
    return data["multiplier"], data["condition"]


def is_cold_start(enrollment_date: datetime) -> bool:
    """True if worker is still in their cold-start period (first 14 days)."""
    return (datetime.utcnow() - enrollment_date).days <= COLD_START_DAYS


# ── Loyalty: Consecutive Quiet Weeks ─────────────────────────────────────────
def get_consecutive_quiet_weeks(worker_id: int, db: Session) -> int:
    """
    Returns the number of consecutive *expired* policy weeks with no payout
    (i.e., no Auto-Approved or Soft-Hold claims).

    A 'quiet week' = an expired Policy where every associated Claim is Blocked
    (fraud detected) or there are 0 claims at all.
    """
    from app.models.policy import Policy
    from app.models.claim import Claim

    past_policies = (
        db.query(Policy)
        .filter(Policy.worker_id == worker_id, Policy.status == "Expired")
        .order_by(Policy.end_date.desc())
        .all()
    )

    consecutive = 0
    for policy in past_policies:
        # Any claim that actually paid out (not blocked) breaks the streak
        payout_claims = (
            db.query(Claim)
            .filter(Claim.policy_id == policy.id, Claim.status != "Blocked")
            .count()
        )
        if payout_claims == 0:
            consecutive += 1
        else:
            break   # Streak broken

    return consecutive


# ── Core Calculation ──────────────────────────────────────────────────────────
def calculate_premium(
    zone_id: int,
    base_risk_multiplier: float,
    enrollment_date: datetime,
    shield_credits: bool = False,
) -> dict:
    """
    Compute the weekly parametric premium for a worker.

    Returns a dict with the full calculation breakdown (transparent audit trail).
    """
    m_weather, weather_condition = get_weather_multiplier(zone_id)
    m_social, social_condition   = get_social_multiplier(zone_id)

    cold_start   = is_cold_start(enrollment_date)
    m_coldstart  = COLD_START_MULTIPLIER if cold_start else 1.0

    raw_premium           = R_BASE * base_risk_multiplier * m_weather * m_social * H_EXPECTED * m_coldstart
    premium_before_disc   = max(PREMIUM_FLOOR, min(PREMIUM_CEILING, raw_premium))

    coverage_amount = base_risk_multiplier * 1000.0

    # Shield Credits discount (only if not in cold-start period)
    discount_amount   = 0.0
    credits_applied   = False
    if shield_credits and not cold_start:
        discount_amount = min(premium_before_disc * SHIELD_DISCOUNT_PCT, SHIELD_DISCOUNT_CAP)
        premium_before_disc = max(PREMIUM_FLOOR, premium_before_disc - discount_amount)
        credits_applied = True

    final_premium = round(premium_before_disc, 2)

    return {
        "r_base":                 R_BASE,
        "m_weather":              round(m_weather, 4),
        "m_social":               round(m_social, 4),
        "m_coldstart":            m_coldstart,
        "h_expected":             H_EXPECTED,
        "base_risk_multiplier":   base_risk_multiplier,
        "raw_premium":            round(raw_premium, 2),
        "premium_before_discount": round(premium_before_disc + discount_amount, 2),
        "premium":                final_premium,
        "weather_condition":      weather_condition,
        "social_condition":       social_condition,
        "cold_start_active":      cold_start,
        "coverage_amount":        coverage_amount,
        "shield_credits_applied": credits_applied,
        "discount_amount":        round(discount_amount, 2),
    }
