"""
HustleHalt API — End-to-End Smoke Test
Runs against http://127.0.0.1:8000 — idempotent, safe to re-run on a live DB
"""
import urllib.request
import urllib.error
import json
import sys
import time

BASE = "http://127.0.0.1:8000"

# Use a timestamp-based phone so re-runs never collide on the unique constraint
_PHONE = f"98{int(time.time()) % 100000000:08d}"


def get(path):
    r = urllib.request.urlopen(BASE + path, timeout=8)
    return json.loads(r.read())


def post(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(
        BASE + path,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    r = urllib.request.urlopen(req, timeout=8)
    return json.loads(r.read())


def patch(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(
        BASE + path,
        data=body,
        headers={"Content-Type": "application/json"},
        method="PATCH",
    )
    r = urllib.request.urlopen(req, timeout=8)
    return json.loads(r.read())


errors = []
worker_id = None

print("=" * 54)
print("  HustleHalt API -- End-to-End Smoke Test")
print("=" * 54)

# 1 — Health
try:
    h = get("/health")
    src = "real-weather" if h.get("real_weather_api") else "mock-weather"
    print(f"[1] Health .............. {h['status'].upper()} | db={h['database']} | {src}")
except Exception as e:
    errors.append(f"Health: {e}")
    print(f"[1] Health .............. FAIL -- {e}")

# 2 — Zones
try:
    zones = get("/api/v1/zones")
    has_coords = all(z.get("latitude") for z in zones)
    print(f"[2] Zones ............... {len(zones)} seeded | coords={'yes' if has_coords else 'MISSING'}")
except Exception as e:
    errors.append(f"Zones: {e}")
    print(f"[2] Zones ............... FAIL -- {e}")

# 3 — Register worker (timestamp phone avoids 409 on re-runs)
try:
    w = post("/api/v1/workers/register", {
        "name": "Rajan Kumar",
        "phone": _PHONE,
        "upi_id": "rajan@upi",
        "q_commerce_platform": "Blinkit",
        "zone_id": 1,
    })
    worker_id = w["id"]
    print(f"[3] Register Worker ..... ID={worker_id} | cold_start={w['cold_start_active']} | zone={w['zone']['name']}")
except Exception as e:
    errors.append(f"Register: {e}")
    print(f"[3] Register Worker ..... FAIL -- {e}")

# 4 — Premium quote (should show real OWM weather source)
try:
    q = get(f"/api/v1/policies/quote/{worker_id}")
    print(
        f"[4] Premium Quote ....... INR{q['premium']} | "
        f"M_weather={q['m_weather']} | weather={q['weather_condition']} | "
        f"source={q.get('weather_source','?')} | rain={q.get('live_rainfall_mm_hr',0)}mm/hr"
    )
except Exception as e:
    errors.append(f"Quote: {e}")
    print(f"[4] Premium Quote ....... FAIL -- {e}")

# 5 — Policy enroll
try:
    p = post("/api/v1/policies/enroll", {"worker_id": worker_id})
    pol = p["policy"]
    print(f"[5] Enroll Policy ....... policy_id={pol['id']} | premium=INR{pol['premium_amount']} | coverage=INR{pol['coverage_amount']}")
except Exception as e:
    errors.append(f"Enroll: {e}")
    print(f"[5] Enroll Policy ....... FAIL -- {e}")

# 6a — Rain trigger at 45 min (should pay 25%)
try:
    t = post("/api/v1/admin/simulate-trigger", {
        "zone_id": 1,
        "event_type": "Rain",
        "severity": "Extreme",
        "duration_hours": 0.75,
        "raw_value": 38.5,
    })
    print(
        f"[6a] Rain 45min ......... trigger_id={t['trigger_event_id']} | "
        f"payout_pct={t['payout_percentage']}% | "
        f"claims={t['claims_generated']} | auto_approved={t['auto_approved']} | "
        f"INR{t['total_payout']}"
    )
    if t["payout_percentage"] != 25.0:
        errors.append(f"Rain 45min payout should be 25%, got {t['payout_percentage']}%")
except Exception as e:
    errors.append(f"Rain Trigger 45min: {e}")
    print(f"[6a] Rain 45min ......... FAIL -- {e}")

# 6b — Heat trigger (should pay 50%)
try:
    t2 = post("/api/v1/admin/simulate-trigger", {
        "zone_id": 1,
        "event_type": "Heat",
        "severity": "Extreme",
        "duration_hours": 4.0,
        "raw_value": 39.2,
    })
    print(
        f"[6b] Heat 4hr ........... trigger_id={t2['trigger_event_id']} | "
        f"payout_pct={t2['payout_percentage']}% | deduped={t2['deduped_skipped']}"
    )
    if t2["payout_percentage"] != 50.0:
        errors.append(f"Heat payout should be 50%, got {t2['payout_percentage']}%")
except Exception as e:
    errors.append(f"Heat Trigger: {e}")
    print(f"[6b] Heat 4hr ........... FAIL -- {e}")

# 7 — Worker dashboard (single call for Flutter home screen)
try:
    dash = get(f"/api/v1/workers/{worker_id}/dashboard")
    print(
        f"[7] Worker Dashboard .... risk={dash['zone']['risk_level']} | "
        f"rain={dash['live_weather']['rainfall_mm_hr']}mm/hr | "
        f"aqi={dash['live_weather']['aqi']} | "
        f"coverage=INR{dash['active_policy']['coverage_amount'] if dash['active_policy'] else 'none'}"
    )
except Exception as e:
    errors.append(f"Dashboard: {e}")
    print(f"[7] Worker Dashboard .... FAIL -- {e}")

# 8 — Worker claims (shows payout_percentage now)
try:
    c = get(f"/api/v1/claims/worker/{worker_id}")
    print(f"[8] Worker Claims ....... {c['total_claims']} claim(s) | total_paid=INR{c['total_payout']}")
    for cl in c["claims"]:
        icon = "[OK]" if cl["status"] == "Auto-Approved" else ("[HOLD]" if cl["status"] == "Soft-Hold" else "[BLOCKED]")
        print(f"    {icon} Claim#{cl['id']} | {cl['status']} | {cl.get('payout_percentage',100):.0f}% | INR{cl['payout_amount']}")
except Exception as e:
    errors.append(f"Claims: {e}")
    print(f"[8] Worker Claims ....... FAIL -- {e}")

# 9 — Admin soft-hold queue
try:
    q = get("/api/v1/admin/claims/soft-hold")
    print(f"[9] Soft-Hold Queue ..... {q['total_pending']} pending claim(s)")
except Exception as e:
    errors.append(f"Soft-hold queue: {e}")
    print(f"[9] Soft-Hold Queue ..... FAIL -- {e}")

# 10 — Zone risk map
try:
    rm = get("/api/v1/admin/zones/risk-map")
    high_risk = [z for z in rm["zones"] if z["risk_level"] == "HIGH"]
    print(f"[10] Zone Risk Map ...... {len(rm['zones'])} zones | {len(high_risk)} HIGH risk")
except Exception as e:
    errors.append(f"Risk map: {e}")
    print(f"[10] Zone Risk Map ...... FAIL -- {e}")

# 11 — Platform stats (check loss ratio field exists)
try:
    s = get("/api/v1/admin/stats")
    lr = s["financial"]["loss_ratio_pct"]
    print(
        f"[11] Platform Stats ..... workers={s['workers']['total']} | "
        f"active_policies={s['policies']['active']} | "
        f"total_payout=INR{s['claims']['total_payout']} | "
        f"loss_ratio={lr}%"
    )
except Exception as e:
    errors.append(f"Stats: {e}")
    print(f"[11] Platform Stats ..... FAIL -- {e}")

print("=" * 54)
if errors:
    print(f"FAILED: {len(errors)} error(s)")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
else:
    print("ALL 11 TESTS PASSED")
    sys.exit(0)
