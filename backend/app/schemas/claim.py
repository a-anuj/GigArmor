"""
GigArmor — Claim Pydantic Schemas (Response only — no worker-facing submit)
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ClaimOut(BaseModel):
    id: int
    policy_id: int
    trigger_event_id: int
    payout_amount: float
    trust_score: float
    status: str = Field(description="Auto-Approved | Soft-Hold | Blocked")
    created_at: datetime

    # Enriched fields from joins
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
