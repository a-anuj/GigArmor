from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.policy import Policy
from app.models.worker import Worker
from app.services.trigger_service import process_trigger_event

db = SessionLocal()

print("ALL POLICIES:")
policies = db.query(Policy).all()
for p in policies:
    print(p.id, p.worker_id, p.status, p.worker.zone_id)

print("\nPROCESS TRIGGER ZONE 1:")
try:
    res = process_trigger_event(db, zone_id=1, event_type="Rain", severity="High")
    print(res)
except Exception as e:
    print("ERROR:", e)

db.close()
