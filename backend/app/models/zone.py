"""
GigArmor — Zone (Dark Store) Model
Represents a geographic delivery zone / dark store.
"""
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.orm import relationship

from app.database import Base


class Zone(Base):
    __tablename__ = "zones"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    pincode = Column(String(10), nullable=False)
    # Multiplier applied on top of R_base to account for zone risk
    base_risk_multiplier = Column(Float, default=1.0, nullable=False)

    # Relationships
    workers = relationship("Worker", back_populates="zone")
    trigger_events = relationship("TriggerEvent", back_populates="zone")

    def __repr__(self) -> str:
        return f"<Zone id={self.id} name='{self.name}' pincode={self.pincode}>"
