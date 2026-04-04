"""
HustleHalt — Worker Pydantic Schemas (Request & Response)
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator


# ── Request ───────────────────────────────────────────────────────────────────
class WorkerRegister(BaseModel):
    name: str = Field(..., min_length=2, max_length=150, examples=["Arjun Sharma"])
    phone: str = Field(
        ...,
        min_length=10,
        max_length=15,
        examples=["9876543210"],
        description="10–15 digit mobile number (with or without country code)",
    )
    upi_id: str = Field(
        ...,
        min_length=5,
        examples=["arjun@upi"],
        description="Worker's UPI ID for instant payouts",
    )
    zone_id: int = Field(
        ...,
        ge=1,
        description="ID of the primary dark store / zone the worker operates in",
    )

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        digits = v.replace("+", "").replace("-", "").replace(" ", "")
        if not digits.isdigit():
            raise ValueError("Phone number must contain only digits")
        if not (10 <= len(digits) <= 15):
            raise ValueError("Phone number must be 10–15 digits")
        return v


class WorkerLogin(BaseModel):
    phone: str = Field(..., description="10–15 digit mobile number")

# ── Response ──────────────────────────────────────────────────────────────────
class WorkerOut(BaseModel):
    id: int
    name: str
    phone: str
    upi_id: str
    zone_id: int
    status: str
    trust_baseline_score: float
    enrollment_date: datetime
    cold_start_active: bool

    model_config = {"from_attributes": True}


class WorkerListOut(BaseModel):
    total: int
    workers: list[WorkerOut]


class ZoneOut(BaseModel):
    id: int
    name: str
    pincode: str
    base_risk_multiplier: float

    model_config = {"from_attributes": True}
