"""
HustleHalt — Activity Router

Endpoints:
  POST /api/v1/activity/log                      — Worker logs a delivery session
  GET  /api/v1/activity/{worker_id}/week         — Current-week activity entries
  GET  /api/v1/activity/{worker_id}/summary      — Aggregated: hours, orders, active days
"""
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.worker import Worker
from app.models.policy import Policy
from app.models.worker_activity_log import WorkerActivityLog

router = APIRouter(prefix="/api/v1/activity", tags=["Activity"])


# ── Request / Response schemas ─────────────────────────────────────────────────

class LogSessionRequest(BaseModel):
    worker_id:     int = Field(..., ge=1, description="Worker's ID")
    policy_id:     Optional[int] = Field(None, description="Active policy ID (auto-resolved if omitted)")
    activity_type: str = Field("delivery_session", description="One of: delivery_session, app_heartbeat, zone_checkin")
    zone_id:       Optional[int] = Field(None, description="Zone the worker is operating in")
    latitude:      Optional[float] = Field(None)
    longitude:     Optional[float] = Field(None)
    orders_count:  int = Field(0, ge=0, description="Number of orders completed in this session")
    session_hours: float = Field(0.0, ge=0.0, description="Hours spent on the road")
    notes:         Optional[str] = Field(None, max_length=500)


# ── Helpers ────────────────────────────────────────────────────────────────────

def _week_bounds():
    """Returns (monday_00:00, next_monday_00:00) for the current ISO week."""
    today = datetime.utcnow()
    monday = today - timedelta(days=today.weekday())
    week_start = monday.replace(hour=0, minute=0, second=0, microsecond=0)
    week_end   = week_start + timedelta(days=7)
    return week_start, week_end


# ── Endpoints ──────────────────────────────────────────────────────────────────

@router.post(
    "/log",
    status_code=status.HTTP_201_CREATED,
    summary="Log a worker delivery session",
)
def log_session(data: LogSessionRequest, db: Session = Depends(get_db)):
    """
    Records a delivery session for a worker.
    In production this would be called automatically by the platform API integration.
    For the demo it is triggered manually from the Flutter app's profile screen.
    """
    worker = db.query(Worker).filter(Worker.id == data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {data.worker_id} not found.")

    # Auto-resolve active policy if not provided
    policy_id = data.policy_id
    if policy_id is None:
        active_policy = (
            db.query(Policy)
            .filter(Policy.worker_id == data.worker_id, Policy.status == "Active")
            .first()
        )
        if active_policy:
            policy_id = active_policy.id

    log = WorkerActivityLog(
        worker_id     = data.worker_id,
        policy_id     = policy_id,
        activity_type = data.activity_type,
        zone_id       = data.zone_id or worker.zone_id,
        latitude      = data.latitude,
        longitude     = data.longitude,
        orders_count  = data.orders_count,
        session_hours = data.session_hours,
        notes         = data.notes,
        logged_at     = datetime.utcnow(),
    )
    db.add(log)
    db.commit()
    db.refresh(log)

    return {
        "id":            log.id,
        "worker_id":     log.worker_id,
        "policy_id":     log.policy_id,
        "activity_type": log.activity_type,
        "orders_count":  log.orders_count,
        "session_hours": log.session_hours,
        "zone_id":       log.zone_id,
        "logged_at":     log.logged_at,
        "message":       f"Session logged. {log.orders_count} orders · {log.session_hours}h recorded.",
    }


@router.get(
    "/{worker_id}/week",
    summary="All activity entries for the current week",
)
def get_week_activity(worker_id: int, db: Session = Depends(get_db)):
    """
    Returns raw activity log entries for the current ISO week (Mon–Sun).
    Used by the Flutter dashboard card.
    """
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found.")

    week_start, week_end = _week_bounds()

    logs = (
        db.query(WorkerActivityLog)
        .filter(
            WorkerActivityLog.worker_id == worker_id,
            WorkerActivityLog.logged_at >= week_start,
            WorkerActivityLog.logged_at <  week_end,
        )
        .order_by(WorkerActivityLog.logged_at.desc())
        .all()
    )

    return {
        "worker_id":   worker_id,
        "week_start":  week_start.isoformat() + "Z",
        "week_end":    week_end.isoformat() + "Z",
        "entry_count": len(logs),
        "entries": [
            {
                "id":            l.id,
                "logged_at":     l.logged_at,
                "activity_type": l.activity_type,
                "orders_count":  l.orders_count,
                "session_hours": l.session_hours,
                "zone_id":       l.zone_id,
                "notes":         l.notes,
            }
            for l in logs
        ],
    }


@router.get(
    "/{worker_id}/summary",
    summary="Aggregated weekly activity summary for a worker",
)
def get_activity_summary(worker_id: int, db: Session = Depends(get_db)):
    """
    Returns the aggregated weekly totals: total hours on road, total orders,
    unique active days, and most recent session timestamp.
    The admin sees this alongside any Soft-Hold claim from this worker.
    """
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found.")

    week_start, week_end = _week_bounds()

    # SQLAlchemy aggregate query
    agg = (
        db.query(
            func.coalesce(func.sum(WorkerActivityLog.orders_count), 0).label("total_orders"),
            func.coalesce(func.sum(WorkerActivityLog.session_hours), 0.0).label("total_hours"),
            func.count(WorkerActivityLog.id).label("session_count"),
        )
        .filter(
            WorkerActivityLog.worker_id == worker_id,
            WorkerActivityLog.logged_at >= week_start,
            WorkerActivityLog.logged_at <  week_end,
        )
        .one()
    )

    # Count unique active days
    day_logs = (
        db.query(func.date(WorkerActivityLog.logged_at))
        .filter(
            WorkerActivityLog.worker_id == worker_id,
            WorkerActivityLog.logged_at >= week_start,
            WorkerActivityLog.logged_at <  week_end,
        )
        .distinct()
        .all()
    )
    active_days = len(day_logs)

    # Most recent session
    latest = (
        db.query(WorkerActivityLog)
        .filter(WorkerActivityLog.worker_id == worker_id)
        .order_by(WorkerActivityLog.logged_at.desc())
        .first()
    )

    # Derive activity level for UI badge
    total_hours = float(agg.total_hours)
    if total_hours >= 20:
        activity_level = "HIGH"
    elif total_hours >= 8:
        activity_level = "MEDIUM"
    elif total_hours > 0:
        activity_level = "LOW"
    else:
        activity_level = "NONE"

    return {
        "worker_id":         worker_id,
        "worker_name":       worker.name,
        "week_start":        week_start.isoformat() + "Z",
        "total_orders":      int(agg.total_orders),
        "total_hours":       round(float(agg.total_hours), 2),
        "session_count":     int(agg.session_count),
        "active_days":       active_days,
        "activity_level":    activity_level,
        "last_session_at":   latest.logged_at if latest else None,
        "claim_context_note": (
            f"Worker logged {int(agg.total_orders)} orders across "
            f"{round(float(agg.total_hours), 1)}h in {active_days} active day(s) this week."
            if agg.session_count > 0
            else "No activity logged this week — insufficient context for auto-approval."
        ),
    }
