"""
HustleHalt — WorkerActivityLog Model

Records delivery sessions logged by workers (or the platform API in production).
Used by the admin claim-review interface to show how active the worker was
during the week a trigger event occurred.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class WorkerActivityLog(Base):
    __tablename__ = "worker_activity_logs"

    id            = Column(Integer, primary_key=True, index=True)
    worker_id     = Column(Integer, ForeignKey("workers.id", ondelete="CASCADE"), nullable=False, index=True)
    policy_id     = Column(Integer, ForeignKey("policies.id", ondelete="SET NULL"), nullable=True, index=True)
    logged_at     = Column(DateTime, nullable=False, default=datetime.utcnow)
    activity_type = Column(String(50), nullable=False, default="delivery_session")
    zone_id       = Column(Integer, ForeignKey("zones.id", ondelete="SET NULL"), nullable=True)
    latitude      = Column(Float, nullable=True)
    longitude     = Column(Float, nullable=True)
    orders_count  = Column(Integer, nullable=False, default=0)
    session_hours = Column(Float, nullable=False, default=0.0)
    notes         = Column(Text, nullable=True)

    # Relationships — lazy loaded to avoid N+1 on bulk queries
    worker = relationship("Worker", backref="activity_logs")
    policy = relationship("Policy", backref="activity_logs")
    zone   = relationship("Zone",   backref="activity_logs")
