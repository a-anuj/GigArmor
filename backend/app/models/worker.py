"""
GigArmor — Worker Model
Represents a gig economy delivery worker enrolled on the platform.
"""
from datetime import datetime

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class Worker(Base):
    __tablename__ = "workers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    upi_id = Column(String(150), nullable=False)

    # Zone this worker operates in (their primary "dark store")
    zone_id = Column(Integer, ForeignKey("zones.id"), nullable=False)

    # Active / Inactive / Suspended
    status = Column(String(20), default="Active", nullable=False)

    # Baseline trust score used as a prior in fraud detection
    trust_baseline_score = Column(Float, default=75.0, nullable=False)

    # Set on registration — drives cold-start premium multiplier
    enrollment_date = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    zone = relationship("Zone", back_populates="workers")
    policies = relationship("Policy", back_populates="worker")

    @property
    def cold_start_active(self) -> bool:
        """True if the worker is still within their first 14 days (cold-start period)."""
        return (datetime.utcnow() - self.enrollment_date).days <= 14

    def __repr__(self) -> str:
        return f"<Worker id={self.id} name='{self.name}' zone={self.zone_id}>"
