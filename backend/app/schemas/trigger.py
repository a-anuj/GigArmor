"""
GigArmor — Trigger / Admin Pydantic Schemas
"""
from typing import Literal

from pydantic import BaseModel, Field


# ── Request: Simulate a parametric trigger ────────────────────────────────────
class SimulateTriggerRequest(BaseModel):
    zone_id: int = Field(..., ge=1, description="Zone to fire the trigger in")
    event_type: Literal["Rain", "AQI", "Outage", "Social", "Heat"] = Field(
        ...,
        description=(
            "Rain=Extreme Rainfall >35mm/hr | "
            "AQI=Severe AQI >300 | "
            "Outage=Platform Outage 0 orders | "
            "Social=Bandh/Curfew | "
            "Heat=Extreme heat >38°C"
        ),
    )
    severity: str = Field(default="Severe", examples=["Severe", "Extreme", "Moderate"])


# ── Response: Trigger simulation result ───────────────────────────────────────
class TriggerSimulateOut(BaseModel):
    trigger_event_id: int
    zone_id: int
    zone_name: str
    event_type: str
    severity: str
    threshold_description: str

    # Claim generation summary
    active_policies_found: int
    claims_generated: int
    auto_approved: int
    soft_hold: int
    blocked: int
    total_payout: float

    message: str
