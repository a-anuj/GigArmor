"""
GigArmor — TriggerEvent Model
Records a parametric trigger event in a zone (e.g. heavy rain, AQI spike).
"""
from datetime import datetime

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class TriggerEvent(Base):
    __tablename__ = "trigger_events"

    id = Column(Integer, primary_key=True, index=True)
    zone_id = Column(Integer, ForeignKey("zones.id"), nullable=False, index=True)

    # Rain | AQI | Outage | Heat | Social
    event_type = Column(String(50), nullable=False)

    # e.g. "Extreme", "Severe", "Moderate"
    severity = Column(String(50), nullable=False)

    start_time = Column(DateTime, default=datetime.utcnow, nullable=False)
    end_time = Column(DateTime, nullable=True)  # None while event is still active

    # Relationships
    zone = relationship("Zone", back_populates="trigger_events")
    claims = relationship("Claim", back_populates="trigger_event")

    def __repr__(self) -> str:
        return (
            f"<TriggerEvent id={self.id} type={self.event_type} "
            f"zone={self.zone_id} severity={self.severity}>"
        )
