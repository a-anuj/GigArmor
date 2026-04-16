"""
HustleHalt — Background Scheduler
Handles time-based jobs that need to run without a user request triggering them.
Uses APScheduler (lightweight, no Redis or Celery needed for demo).

Jobs:
  - Policy expiry: runs every hour, expires all policies where end_date has passed
  - Zone weather cache: runs every 15 minutes, pre-fetches OWM data so API requests are fast
"""
import logging
from datetime import datetime

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.policy import Policy

logger = logging.getLogger(__name__)

_scheduler = BackgroundScheduler(timezone="Asia/Kolkata")

# In-memory weather cache — keyed by zone_id, refreshed every 15 minutes
# Means the premium quote endpoint doesn't need to wait for OWM during a request
_weather_cache: dict[int, dict] = {}


def _expire_policies():
    """
    Marks all policies where end_date < now as Expired.
    Runs every hour so the longest a stale active policy can linger is 60 minutes.
    This is what enables the Shield Credits streak logic to work correctly.
    """
    db: Session = SessionLocal()
    try:
        now = datetime.utcnow()
        expired_count = (
            db.query(Policy)
            .filter(Policy.status == "Active", Policy.end_date < now)
            .update({"status": "Expired"})
        )
        db.commit()
        if expired_count > 0:
            logger.info(f"[Scheduler] Expired {expired_count} policy/policies at {now.isoformat()}")
    except Exception as exc:
        logger.error(f"[Scheduler] Policy expiry job failed: {exc}")
        db.rollback()
    finally:
        db.close()


def _refresh_weather_cache():
    """
    Pre-fetches OWM weather data for all zones every 15 minutes.
    Caches results in _weather_cache so premium quote API calls are instant.
    This is the simplified version of the HZI Engine from README Section 10.
    """
    from app.database import SessionLocal
    from app.models.zone import Zone
    from app.services.weather_service import fetch_zone_weather
    from app.services.aqi_service import fetch_zone_aqi

    db: Session = SessionLocal()
    try:
        zones = db.query(Zone).all()
        for zone in zones:
            if zone.latitude and zone.longitude:
                weather = fetch_zone_weather(zone.latitude, zone.longitude, zone.id)
                aqi = fetch_zone_aqi(zone.latitude, zone.longitude, zone.id)
                _weather_cache[zone.id] = {**weather, "aqi": aqi.get("aqi", 0)}
        logger.info(f"[Scheduler] Weather cache refreshed for {len(zones)} zones")
    except Exception as exc:
        logger.error(f"[Scheduler] Weather cache refresh failed: {exc}")
    finally:
        db.close()


def get_cached_weather(zone_id: int) -> dict:
    """Returns the last cached weather data for a zone — or empty dict if not yet cached."""
    return _weather_cache.get(zone_id, {})


def start_scheduler():
    """
    Registers all background jobs and starts the scheduler.
    Called from FastAPI's lifespan startup so it runs as long as the server is up.
    """
    _scheduler.add_job(
        _expire_policies,
        trigger=IntervalTrigger(hours=1),
        id="expire_policies",
        replace_existing=True,
        max_instances=1,
    )

    _scheduler.add_job(
        _refresh_weather_cache,
        trigger=IntervalTrigger(minutes=15),
        id="refresh_weather_cache",
        replace_existing=True,
        max_instances=1,
    )

    _scheduler.start()
    logger.info("[Scheduler] Background jobs started: policy expiry (1hr), weather cache (15min)")

    # Run an immediate first pass so cache is warm on startup
    _refresh_weather_cache()


def stop_scheduler():
    """Called during FastAPI shutdown to cleanly stop all jobs."""
    if _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("[Scheduler] Background scheduler stopped")
