"""
GigArmor — Policy Model
Represents a weekly parametric income insurance policy for a worker.
"""
from datetime import datetime

from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, String
from sqlalchemy.orm import relationship

from app.database import Base


class Policy(Base):
    __tablename__ = "policies"

    id = Column(Integer, primary_key=True, index=True)
    worker_id = Column(Integer, ForeignKey("workers.id"), nullable=False, index=True)

    # Weekly coverage window
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)

    # Premium paid (₹19 – ₹99 based on dynamic engine)
    premium_amount = Column(Float, nullable=False)

    # Fixed parametric coverage ceiling (₹1,200)
    coverage_amount = Column(Float, default=1200.0, nullable=False)

    # Active | Expired
    status = Column(String(20), default="Active", nullable=False)

    # Relationships
    worker = relationship("Worker", back_populates="policies")
    claims = relationship("Claim", back_populates="policy")

    def __repr__(self) -> str:
        return (
            f"<Policy id={self.id} worker={self.worker_id} "
            f"premium=₹{self.premium_amount} status={self.status}>"
        )
