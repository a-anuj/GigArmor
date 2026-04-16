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
    q_commerce_platform: str = Field(
        "Zomato",
        description="The Quick Commerce platform the worker drives for (e.g. Zomato, Swiggy)",
    )
    upi_id: Optional[str] = Field(
        None,
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

class WorkerUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    q_commerce_platform: Optional[str] = Field(None, description="Q-Commerce platform")
    upi_id: Optional[str] = Field(None, min_length=5)

class ZoneOut(BaseModel):
    id: int
    name: str
    pincode: str
    city: str = "Bengaluru"
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    base_risk_multiplier: float

    model_config = {"from_attributes": True}


# ── Response ──────────────────────────────────────────────────────────────────
class WorkerOut(BaseModel):
    id: int
    name: str
    phone: str
    q_commerce_platform: str
    upi_id: Optional[str] = None
    zone_id: int
    zone: Optional[ZoneOut] = None
    status: str
    trust_baseline_score: float
    enrollment_date: datetime
    cold_start_active: bool

    model_config = {"from_attributes": True}


class WorkerListOut(BaseModel):
    total: int
    workers: list[WorkerOut]
