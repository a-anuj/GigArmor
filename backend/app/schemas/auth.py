"""
HustleHalt — Auth Schemas (Pydantic v2)
"""
from pydantic import BaseModel, EmailStr, model_validator, Field
from typing import Optional


# ── Register ──────────────────────────────────────────────────────────────────
class WorkerAuthRegister(BaseModel):
    """Payload for registering a new worker account with credentials."""

    name: str = Field(..., min_length=2, max_length=150, examples=["Ravi Kumar"])
    phone: str = Field(..., min_length=10, max_length=20, examples=["+919876543210"])
    email: EmailStr = Field(..., examples=["ravi@example.com"])
    password: str = Field(..., min_length=8, examples=["strongPass123!"])
    q_commerce_platform: str = Field("Zomato", examples=["Swiggy"])
    upi_id: Optional[str] = Field(None, examples=["ravi@upi"])
    zone_id: int = Field(..., ge=1, examples=[1])


# ── Login ─────────────────────────────────────────────────────────────────────
class WorkerAuthLogin(BaseModel):
    """Login with either email or phone + password."""

    identifier: str = Field(
        ...,
        description="Worker's registered email address or phone number.",
        examples=["ravi@example.com"],
    )
    password: str = Field(..., examples=["strongPass123!"])


# ── Token Response ────────────────────────────────────────────────────────────
class TokenOut(BaseModel):
    """JWT token response returned on successful authentication."""

    access_token: str
    token_type: str = "bearer"
    worker_id: int
    name: str
    email: Optional[str] = None
