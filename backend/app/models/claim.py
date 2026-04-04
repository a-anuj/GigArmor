"""
GigArmor — Claim Model
Auto-generated server-side when a parametric trigger fires. Workers never
file claims manually — this is the "Zero-Touch" experience.
"""
from datetime import datetime

from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class Claim(Base):
    __tablename__ = "claims"

    id = Column(Integer, primary_key=True, index=True)
    policy_id = Column(Integer, ForeignKey("policies.id"), nullable=False, index=True)
    trigger_event_id = Column(
        Integer, ForeignKey("trigger_events.id"), nullable=False, index=True
    )

    # For this demo, 100% payout (₹1,200) or ₹0 if Blocked
    payout_amount = Column(Float, nullable=False)

    # 0–100 score from the Trust Engine fraud check
    trust_score = Column(Float, nullable=False)

    # Auto-Approved | Soft-Hold | Blocked
    status = Column(String(20), nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    policy = relationship("Policy", back_populates="claims")
    trigger_event = relationship("TriggerEvent", back_populates="claims")

    def __repr__(self) -> str:
        return (
            f"<Claim id={self.id} policy={self.policy_id} "
            f"status={self.status} payout=₹{self.payout_amount}>"
        )
