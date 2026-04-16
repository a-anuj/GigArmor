"""
HustleHalt — Trigger / Admin Pydantic Schemas
Updated to include duration_hours so payout scaling works correctly.
"""
from typing import Literal, Optional

from pydantic import BaseModel, Field


class SimulateTriggerRequest(BaseModel):
    zone_id: int = Field(..., ge=1, description="Zone to fire the trigger in")
    event_type: Literal["Rain", "AQI", "Outage", "Social", "Heat"] = Field(
        ...,
        description=(
            "Rain=Extreme Rainfall ≥35mm/hr | "
            "AQI=Severe AQI >300 | "
            "Outage=Platform Outage 0 orders | "
            "Social=Bandh/Curfew | "
            "Heat=Extreme heat ≥38°C wet-bulb"
        ),
    )
    severity: str = Field(default="Severe", examples=["Severe", "Extreme", "Moderate"])

    # Duration drives payout scaling for the Rain trigger
    # Rain: 0.75h=25%, 2.0h=50%, 4.0h+=100%
    duration_hours: float = Field(
        default=1.0,
        ge=0.75,
        description="How long the event lasted in hours — determines payout % for Rain trigger",
    )

    # The actual measured value for context (mm/hr for Rain, AQI number, celsius for Heat)
    raw_value: Optional[float] = Field(
        default=None,
        description="Measured value at trigger time (38.5 mm/hr, AQI 312, 40.2°C, etc.)",
    )

    # Oracle confidence score for Social disruption triggers
    confidence_score: Optional[float] = Field(
        default=None,
        ge=0.0,
        le=1.0,
        description="Weighted oracle consensus score (0–1) — used for Social trigger only",
    )


class TriggerSimulateOut(BaseModel):
    trigger_event_id: int
    zone_id: int
    zone_name: str
    event_type: str
    severity: str
    duration_hours: float
    payout_percentage: float
    threshold_description: str

    # Claim generation summary
    active_policies_found: int
    claims_generated: int
    deduped_skipped: int
    auto_approved: int
    soft_hold: int
    blocked: int
    total_payout: float

    message: str
