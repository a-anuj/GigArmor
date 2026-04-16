"""
HustleHalt — Claim Pydantic Schemas
Response only — workers never POST a claim, the system creates them on trigger fire.
Updated to include payout_percentage and appeal_deadline.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ClaimOut(BaseModel):
    id: int
    policy_id: int
    trigger_event_id: int
    payout_amount: float
    payout_percentage: float = Field(default=100.0, description="25 | 50 | 75 | 100 — per README Section 6")
    trust_score: float
    status: str = Field(description="Auto-Approved | Soft-Hold | Blocked | Under-Appeal")
    created_at: datetime
    appeal_deadline: Optional[datetime] = None

    # Enriched from joins — avoids N+1 round trips in the Flutter app
    event_type: Optional[str] = None
    event_severity: Optional[str] = None
    zone_name: Optional[str] = None
    upi_webhook_fired: bool = False

    model_config = {"from_attributes": True}


class ClaimListOut(BaseModel):
    worker_id: int
    worker_name: str
    total_claims: int
    total_payout: float
    claims: list[ClaimOut]
