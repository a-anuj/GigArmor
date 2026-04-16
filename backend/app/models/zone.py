"""
HustleHalt — Zone (Dark Store) Model
Added lat/lon so the weather service can make real API calls per zone
"""
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.orm import relationship

from app.database import Base


class Zone(Base):
    __tablename__ = "zones"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    pincode = Column(String(10), nullable=False)
    city = Column(String(100), nullable=False, default="Bengaluru")

    # Needed for OWM and AQICN API calls — the whole point of hyperlocal zone intelligence
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    # Zone's base risk level applied on top of the formula's R_base
    base_risk_multiplier = Column(Float, default=1.0, nullable=False)

    # Relationships
    workers = relationship("Worker", back_populates="zone")
    trigger_events = relationship("TriggerEvent", back_populates="zone")

    def __repr__(self) -> str:
        return f"<Zone id={self.id} name='{self.name}' pincode={self.pincode}>"
