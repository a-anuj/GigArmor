"""
HustleHalt — Claim Model
Server-generated when a parametric trigger fires. Workers never file claims manually.
Added payout_percentage, goodwill_credit and appeal fields per README spec.
"""
from datetime import datetime

from sqlalchemy import Boolean, Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class Claim(Base):
    __tablename__ = "claims"

    id = Column(Integer, primary_key=True, index=True)
    policy_id = Column(Integer, ForeignKey("policies.id"), nullable=False, index=True)
    trigger_event_id = Column(
        Integer, ForeignKey("trigger_events.id"), nullable=False, index=True
    )

    # 25 | 50 | 75 | 100 — driven by event type and duration per README Section 6
    payout_percentage = Column(Float, nullable=False, default=100.0)

    # Actual rupee payout = coverage_amount × (payout_percentage / 100)
    payout_amount = Column(Float, nullable=False)

    # 0–100 trust score from the three-layer fraud engine
    trust_score = Column(Float, nullable=False)

    # Auto-Approved | Soft-Hold | Blocked | Under-Appeal
    status = Column(String(20), nullable=False)

    # Set when a genuine auto-approved claim was held for > 4hrs — triggers ₹25 goodwill
    goodwill_credit_applied = Column(Boolean, default=False, nullable=False)

    # Workers have 72 hours to appeal a Blocked decision
    appeal_deadline = Column(DateTime, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    policy = relationship("Policy", back_populates="claims")
    trigger_event = relationship("TriggerEvent", back_populates="claims")

    def __repr__(self) -> str:
        return (
            f"<Claim id={self.id} policy={self.policy_id} "
            f"status={self.status} payout=₹{self.payout_amount} ({self.payout_percentage}%)>"
        )
