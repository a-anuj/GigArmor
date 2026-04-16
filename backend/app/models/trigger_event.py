"""
HustleHalt — TriggerEvent Model
Records each parametric trigger that fires in a zone.
Added duration and raw_value so the trigger processor can apply correct payout scaling.
"""
from datetime import datetime

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship

from app.database import Base


class TriggerEvent(Base):
    __tablename__ = "trigger_events"

    id = Column(Integer, primary_key=True, index=True)
    zone_id = Column(Integer, ForeignKey("zones.id"), nullable=False, index=True)

    # Rain | AQI | Outage | Heat | Social
    event_type = Column(String(50), nullable=False)

    # Extreme | Severe | Moderate
    severity = Column(String(50), nullable=False)

    # How long the event lasted — drives payout scaling for Rain trigger
    # e.g. 0.75 = 45 minutes, 2.5 = 2.5 hours, 4.0+ = full payout
    duration_hours = Column(Float, nullable=True, default=0.0)

    # The actual measured value at trigger time (mm/hr, AQI number, temp°C, etc.)
    raw_value = Column(Float, nullable=True)

    # Oracle consensus score for Social triggers (weighted confidence 0–1)
    confidence_score = Column(Float, nullable=True)

    start_time = Column(DateTime, default=datetime.utcnow, nullable=False)
    end_time = Column(DateTime, nullable=True)

    # Relationships
    zone = relationship("Zone", back_populates="trigger_events")
    claims = relationship("Claim", back_populates="trigger_event")

    def __repr__(self) -> str:
        return (
            f"<TriggerEvent id={self.id} type={self.event_type} "
            f"zone={self.zone_id} severity={self.severity}>"
        )
