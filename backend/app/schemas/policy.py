"""
HustleHalt — Policy Pydantic Schemas (Request & Response)
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# ── Request ───────────────────────────────────────────────────────────────────
class PolicyEnroll(BaseModel):
    worker_id: int = Field(..., description="Worker ID to enroll for this week's cover")
    razorpay_payment_id: Optional[str] = None
    razorpay_order_id: Optional[str] = None
    razorpay_signature: Optional[str] = None


# ── Response: Premium Quote ───────────────────────────────────────────────────
class PremiumQuote(BaseModel):
    worker_id: int
    worker_name: str
    zone_id: int
    zone_name: str

    # Premium calculation breakdown
    r_base: float = Field(description="Base rate (₹5)")
    m_weather: float = Field(description="Weather multiplier (1.0 – 3.5)")
    m_social: float = Field(description="Social disruption multiplier (1.0 – 2.0)")
    m_coldstart: float = Field(description="Cold-start multiplier (1.2 first 2 weeks, else 1.0)")
    h_expected: float = Field(description="Expected hours multiplier (1.0 for demo)")
    base_risk_multiplier: float = Field(description="Zone base risk multiplier")

    raw_premium: float = Field(description="Premium before floor/ceiling clamping")
    premium_before_discount: float = Field(description="After clamping, before loyalty discount")
    premium: float = Field(description="Final premium (₹19 – ₹99)")

    # Context
    weather_condition: str
    social_condition: str
    cold_start_active: bool

    # Loyalty / Shield Credits
    consecutive_quiet_weeks: int
    shield_credits_applied: bool
    discount_amount: float
    coverage_amount: float

    message: str

    # Live weather data — powers the Flutter home screen weather readout
    weather_source: str = "mock"
    live_rainfall_mm_hr: float = 0.0
    live_temperature_c: float = 0.0
    live_wet_bulb_c: float = 0.0
    live_humidity_pct: float = 0.0

class CreateOrderResponse(BaseModel):
    order_id: str
    quote: PremiumQuote


# ── Response: Active Policy ───────────────────────────────────────────────────
class PolicyOut(BaseModel):
    id: int
    worker_id: int
    start_date: datetime
    end_date: datetime
    premium_amount: float
    coverage_amount: float
    status: str

    model_config = {"from_attributes": True}


class PolicyEnrollOut(BaseModel):
    policy: PolicyOut
    quote_used: PremiumQuote
    message: str


class PolicyListOut(BaseModel):
    total: int
    policies: list[PolicyOut]
