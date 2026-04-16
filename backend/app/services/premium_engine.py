"""
HustleHalt — Dynamic Premium Calculation Engine

Formula (verbatim from README Section 5):
  Premium = max(19, min(99, R_base × M_weather × M_social × H_expected × M_coldstart))

M_weather now comes from a real OWM API call using the zone's lat/lon.
M_social is still mocked — no reliable free API for hyperlocal Indian social disruption data exists.
"""
from datetime import datetime

from sqlalchemy.orm import Session

from app.services.weather_service import fetch_zone_weather

# Constants — hard-coded as per README, do not change without product sign-off
R_BASE: float = 5.0
H_EXPECTED: float = 1.0
COLD_START_DAYS: int = 14
COLD_START_MULTIPLIER: float = 1.2
PREMIUM_FLOOR: float = 19.0
PREMIUM_CEILING: float = 99.0
SHIELD_DISCOUNT_PCT: float = 0.20
SHIELD_DISCOUNT_CAP: float = 99.0       # Max Shield Credit in rupees
COVERAGE_BASE: float = 1000.0           # Coverage = zone.base_risk_multiplier × 1000
QUIET_WEEKS_THRESHOLD: int = 4          # Weeks before Shield Credits kick in


# M_social stays mocked — simulates the weighted oracle consensus (news + traffic + platform)
# In production this would be a call to a news NLP microservice
_ZONE_SOCIAL: dict[int, dict] = {
    1: {"condition": "Normal",                    "multiplier": 1.0},
    2: {"condition": "Moderate Traffic Disruption","multiplier": 1.4},
    3: {"condition": "Bandh — Full Shutdown",     "multiplier": 2.0},
    4: {"condition": "Normal",                    "multiplier": 1.0},
    5: {"condition": "Political Protest",          "multiplier": 1.6},
    6: {"condition": "Curfew-like Restrictions",  "multiplier": 1.9},
    7: {"condition": "Normal",                    "multiplier": 1.0},
    8: {"condition": "Normal",                    "multiplier": 1.0},
}
_DEFAULT_SOCIAL = {"condition": "Normal", "multiplier": 1.0}


def get_social_multiplier(zone_id: int) -> tuple[float, str]:
    data = _ZONE_SOCIAL.get(zone_id, _DEFAULT_SOCIAL)
    return data["multiplier"], data["condition"]


def is_cold_start(enrollment_date: datetime) -> bool:
    return (datetime.utcnow() - enrollment_date).days <= COLD_START_DAYS


def get_consecutive_quiet_weeks(worker_id: int, db: Session) -> int:
    """
    Count consecutive expired policy weeks where no payout claim was Auto-Approved or Soft-Hold.
    Used to determine Shield Credit eligibility (4+ quiet weeks = 20% discount).
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
        payout_claims = (
            db.query(Claim)
            .filter(Claim.policy_id == policy.id, Claim.status != "Blocked")
            .count()
        )
        if payout_claims == 0:
            consecutive += 1
        else:
            break  # One week with a payout breaks the quiet streak

    return consecutive


def calculate_premium(
    zone_id: int,
    base_risk_multiplier: float,
    enrollment_date: datetime,
    lat: float = None,
    lon: float = None,
    shield_credits: bool = False,
    booked_shift_ratio: float = 1.0,
) -> dict:
    """
    Computes the full weekly premium breakdown for a worker.
    Returns a detailed dict used for both the quote API and the enrollment confirmation.
    M_weather comes from a live OWM call if lat/lon is provided, otherwise falls back.
    """
    # Live weather call — this is what makes the premium actually responsive to real conditions
    weather = fetch_zone_weather(lat or 12.9716, lon or 77.5946, zone_id)
    m_weather = weather["m_weather"]
    weather_condition = weather["weather_condition"]
    weather_source = weather.get("source", "mock")

    m_social, social_condition = get_social_multiplier(zone_id)

    cold_start = is_cold_start(enrollment_date)
    m_coldstart = COLD_START_MULTIPLIER if cold_start else 1.0

    # Shift-linked micro-policy support — part-time workers pay proportionally less
    h_expected = H_EXPECTED * booked_shift_ratio

    raw_premium = R_BASE * m_weather * m_social * h_expected * m_coldstart
    premium_before_disc = max(PREMIUM_FLOOR, min(PREMIUM_CEILING, raw_premium))

    # Coverage scales with zone risk — riskier zones = higher coverage ceiling
    coverage_amount = round(base_risk_multiplier * COVERAGE_BASE, 2)

    discount_amount = 0.0
    credits_applied = False
    if shield_credits and not cold_start:
        discount_amount = min(premium_before_disc * SHIELD_DISCOUNT_PCT, SHIELD_DISCOUNT_CAP)
        premium_before_disc = max(PREMIUM_FLOOR, premium_before_disc - discount_amount)
        credits_applied = True

    final_premium = round(premium_before_disc, 2)

    return {
        "r_base":                   R_BASE,
        "m_weather":                round(m_weather, 4),
        "m_social":                 round(m_social, 4),
        "m_coldstart":              m_coldstart,
        "h_expected":               round(h_expected, 4),
        "base_risk_multiplier":     base_risk_multiplier,
        "raw_premium":              round(raw_premium, 2),
        "premium_before_discount":  round(premium_before_disc + discount_amount, 2),
        "premium":                  final_premium,
        "weather_condition":        weather_condition,
        "social_condition":         social_condition,
        "weather_source":           weather_source,
        "cold_start_active":        cold_start,
        "coverage_amount":          coverage_amount,
        "shield_credits_applied":   credits_applied,
        "discount_amount":          round(discount_amount, 2),
        # Expose raw weather data for the Flutter dashboard's live readout
        "live_rainfall_mm_hr":      weather.get("rainfall_mm_hr", 0.0),
        "live_temperature_c":       weather.get("temperature_c", 0.0),
        "live_wet_bulb_c":          weather.get("wet_bulb_c", 0.0),
        "live_humidity_pct":        weather.get("humidity_pct", 0.0),
    }
