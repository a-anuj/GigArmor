"""Quick smoke test for HustleHalt API — runs against http://127.0.0.1:8000"""
import urllib.request
import json
import sys

BASE = "http://127.0.0.1:8000"


def get(path):
    r = urllib.request.urlopen(BASE + path, timeout=5)
    return json.loads(r.read())


def post(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(
        BASE + path,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    r = urllib.request.urlopen(req, timeout=5)
    return json.loads(r.read())


errors = []

print("=" * 50)
print("  HustleHalt API — End-to-End Smoke Test")
print("=" * 50)

try:
    h = get("/health")
    print(f"[1] Health .............. {h['status'].upper()}")
except Exception as e:
    errors.append(f"Health: {e}")
    print(f"[1] Health .............. FAIL — {e}")

try:
    zones = get("/api/v1/zones")
    print(f"[2] Zones ............... {len(zones)} seeded")
except Exception as e:
    errors.append(f"Zones: {e}")
    print(f"[2] Zones ............... FAIL — {e}")

try:
    w = post("/api/v1/workers/register", {
        "name": "Arjun Sharma",
        "phone": "9876543210",
        "upi_id": "arjun@upi",
        "zone_id": 1,
    })
    worker_id = w["id"]
    print(f"[3] Register Worker ..... ID={worker_id}, cold_start={w['cold_start_active']}")
except Exception as e:
    errors.append(f"Register: {e}")
    print(f"[3] Register Worker ..... FAIL — {e}")
    worker_id = 1

try:
    q = get(f"/api/v1/policies/quote/{worker_id}")
    print(f"[4] Premium Quote ....... INR{q['premium']} | weather={q['weather_condition']} | coldstart={q['cold_start_active']}")
except Exception as e:
    errors.append(f"Quote: {e}")
    print(f"[4] Premium Quote ....... FAIL — {e}")

try:
    p = post("/api/v1/policies/enroll", {"worker_id": worker_id})
    pol = p["policy"]
    print(f"[5] Enroll Policy ....... policy_id={pol['id']}, premium=INR{pol['premium_amount']}, status={pol['status']}")
except Exception as e:
    errors.append(f"Enroll: {e}")
    print(f"[5] Enroll Policy ....... FAIL — {e}")

try:
    t = post("/api/v1/admin/simulate-trigger", {
        "zone_id": 1,
        "event_type": "Rain",
        "severity": "Extreme",
    })
    print(f"[6] Rain Trigger ........ trigger_id={t['trigger_event_id']}, claims={t['claims_generated']}, auto_approved={t['auto_approved']}, payout=INR{t['total_payout']}")
except Exception as e:
    errors.append(f"Trigger: {e}")
    print(f"[6] Rain Trigger ........ FAIL — {e}")

try:
    c = get(f"/api/v1/claims/worker/{worker_id}")
    print(f"[7] Worker Claims ....... {c['total_claims']} claim(s), total_payout=INR{c['total_payout']}")
    for cl in c["claims"]:
        icon = "✅" if cl["status"] == "Auto-Approved" else ("⏳" if cl["status"] == "Soft-Hold" else "🚫")
        print(f"    {icon} Claim#{cl['id']} | {cl['status']} | trust={cl['trust_score']} | INR{cl['payout_amount']}")
except Exception as e:
    errors.append(f"Claims: {e}")
    print(f"[7] Worker Claims ....... FAIL — {e}")

try:
    s = get("/api/v1/admin/stats")
    print(f"[8] Platform Stats ...... workers={s['workers']['total']}, active_policies={s['policies']['active']}, total_payout=INR{s['claims']['total_payout']}")
except Exception as e:
    errors.append(f"Stats: {e}")
    print(f"[8] Platform Stats ...... FAIL — {e}")

print("=" * 50)
if errors:
    print(f"FAILED: {len(errors)} error(s)")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
else:
    print("ALL 8 TESTS PASSED")
    sys.exit(0)
