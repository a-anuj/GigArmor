# HustleHalt — Backend API

> **AI-powered parametric income insurance for gig economy workers.**
> Built for the **Guidewire DEVTrails Hackathon** — Theme: *Protect Your Worker*

HustleHalt pays out delivery workers automatically when something goes wrong — extreme rain, hazardous AQI, platform outage, civil disruption, or a heat wave. The worker never files a claim. They open the app and the money is already there.

---

## Table of Contents

1. [How It Works](#how-it-works)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Getting Started](#getting-started)
5. [Environment Variables](#environment-variables)
6. [API Reference](#api-reference)  
   - [Auth](#auth)  
   - [Zones](#zones)  
   - [Workers](#workers)  
   - [Policies](#policies)  
   - [Claims](#claims)  
   - [Admin](#admin)
7. [Core Business Logic](#core-business-logic)  
   - [Premium Formula](#premium-formula)  
   - [Payout Scaling](#payout-scaling)  
   - [Trust Score Engine](#trust-score-engine)  
   - [Zero-Touch Claim Flow](#zero-touch-claim-flow)  
   - [Shield Credits Loyalty](#shield-credits-loyalty)
8. [Background Jobs](#background-jobs)
9. [For Flutter Developers](#for-flutter-developers)
10. [Running the Smoke Test](#running-the-smoke-test)
11. [Database & Migrations](#database--migrations)

---

## How It Works

```
Worker enrolls weekly → pays ₹19–₹99 premium → gets ₹1,000–₹1,500 coverage
        ↓
Environmental event fires in their zone (rain, AQI, outage, etc.)
        ↓
Backend detects trigger → calculates payout % → runs fraud check
        ↓
Auto-Approved: UPI payout fires instantly, worker sees money in app
Soft-Hold:     Admin reviews, approves/rejects with one tap
Blocked:       Worker can appeal within 72 hours
```

No claim form. No phone call. No wait. That's the product.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | FastAPI 0.111 |
| ORM | SQLAlchemy 2.0 (synchronous) |
| Database | PostgreSQL via Supabase (SQLite works for local dev) |
| Validation | Pydantic v2 |
| Server | Uvicorn |
| Auth | JWT (python-jose) + Argon2id password hashing |
| Background Jobs | APScheduler 3.10 |
| Weather API | OpenWeatherMap (free tier) |
| AQI API | AQICN (free tier) |

---

## Project Structure

```
backend/
├── app/
│   ├── main.py                   # FastAPI app, lifespan, CORS, router registration, zone seeding
│   ├── config.py                 # All settings via Pydantic-settings (reads from .env)
│   ├── database.py               # Smart engine factory — PostgreSQL vs SQLite, no crash
│   ├── auth.py                   # JWT creation/verification + Argon2id hashing
│   ├── dependencies.py           # get_current_worker FastAPI dependency
│   │
│   ├── models/                   # SQLAlchemy ORM — one file per table
│   │   ├── zone.py               # Dark store location with lat/lon for weather API
│   │   ├── worker.py             # Gig worker profile + cold_start_active computed property
│   │   ├── policy.py             # Weekly insurance policy (Active / Expired)
│   │   ├── trigger_event.py      # Parametric event record (duration, raw value, confidence)
│   │   └── claim.py              # Auto-generated payout record (never worker-submitted)
│   │
│   ├── schemas/                  # Pydantic v2 request/response models
│   │   ├── worker.py             # WorkerRegister, WorkerOut (includes nested ZoneOut)
│   │   ├── policy.py             # PremiumQuote (includes live weather fields), PolicyOut
│   │   ├── claim.py              # ClaimOut (includes payout_percentage, appeal_deadline)
│   │   └── trigger.py            # SimulateTriggerRequest (includes duration_hours)
│   │
│   ├── routers/                  # HTTP route handlers
│   │   ├── auth.py               # /api/v1/auth/* — register, login, /me
│   │   ├── workers.py            # /api/v1/workers/* + /api/v1/zones
│   │   ├── policies.py           # /api/v1/policies/*
│   │   ├── claims.py             # /api/v1/claims/*
│   │   └── admin.py              # /api/v1/admin/*
│   │
│   └── services/                 # Business logic — no HTTP framework coupling
│       ├── premium_engine.py     # Dynamic premium formula using live OWM weather
│       ├── weather_service.py    # OpenWeatherMap integration + wet-bulb calculation
│       ├── aqi_service.py        # AQICN integration + T2 threshold check
│       ├── trigger_service.py    # Zero-touch claim orchestrator + payout scaling
│       ├── trust_engine.py       # 3-layer fraud detection (0–100 trust score)
│       ├── webhook_service.py    # UPI payout webhook (mock, swap for Razorpay in prod)
│       └── scheduler.py          # APScheduler — policy expiry + weather cache jobs
│
├── migrate_v1_1.sql              # Run once against Supabase to add new columns
├── smoke_test.py                 # 11-step end-to-end API verification script
├── requirements.txt
├── .env.example                  # Copy this to .env and fill in your keys
└── README.md
```

---

## Getting Started

### Prerequisites
- Python 3.11+
- A Supabase project (or SQLite for local dev — zero setup)

### 1. Install dependencies
```bash
cd GigArmor/backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Configure environment
```bash
cp .env.example .env
```

Edit `.env` with your values. The only required variable is `DATABASE_URL`. Everything else has a working default.

```env
# Supabase PostgreSQL (production)
DATABASE_URL=postgresql://postgres:yourpassword@db.yourproject.supabase.co:5432/postgres

# Local SQLite (simplest for first run)
DATABASE_URL=sqlite:///./hustlehalt.db

# OWM and AQICN — free tier, no credit card
OPENWEATHERMAP_API_KEY=your-key-here
AQICN_API_TOKEN=your-token-here
```

### 3. Run the migration (PostgreSQL / Supabase only)
```bash
python -c "
import psycopg2, os
conn = psycopg2.connect(os.getenv('DATABASE_URL'))
cur = conn.cursor()
cur.execute(open('migrate_v1_1.sql').read())
conn.commit()
conn.close()
print('Done')
"
```

Skip this step for SQLite — `create_all()` on startup handles it automatically.

### 4. Start the server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

On first boot the server:
- Creates all 5 database tables
- Seeds 8 dark store zones with real Bengaluru + Coimbatore coordinates
- Warms the weather cache (one OWM call per zone)
- Starts background jobs (policy expiry every hour, weather refresh every 15 min)

### 5. Explore the API
```
http://localhost:8000/docs    ← Swagger UI — try every endpoint here
http://localhost:8000/redoc   ← ReDoc (cleaner for reading)
http://localhost:8000/health  ← Quick sanity check
```

---

## Environment Variables

| Variable | Default | Required | Description |
|---|---|---|---|
| `DATABASE_URL` | — | **Yes** | Supabase PostgreSQL or `sqlite:///./hustlehalt.db` |
| `SECRET_KEY` | `changeme` | **Yes in prod** | JWT signing key — generate with `openssl rand -hex 32` |
| `OPENWEATHERMAP_API_KEY` | `""` | Recommended | Free at openweathermap.org/api — drives M_weather |
| `AQICN_API_TOKEN` | `""` | Recommended | Free at aqicn.org/api — drives AQI trigger |
| `USE_REAL_WEATHER_API` | `true` | No | Set `false` to use hardcoded mock data (CI / offline demo) |
| `REDIS_URL` | `redis://localhost:6379/0` | No | Reserved — not used in current demo build |
| `UPI_WEBHOOK_URL` | Mock URL | No | Real Razorpay Payout URL in production |
| `UPI_API_KEY` | Mock key | No | Real Razorpay API key in production |
| `DEBUG` | `false` | No | Enables SQLAlchemy query logging |
| `APP_ENV` | `development` | No | Label shown in `/health` response |

If `OPENWEATHERMAP_API_KEY` is empty or `USE_REAL_WEATHER_API=false`, the premium engine falls back to hardcoded per-zone mock weather data. The server will not crash — this is intentional.

---

## API Reference

Base URL: `http://localhost:8000`  
Interactive docs: `http://localhost:8000/docs`

---

### Auth

Auth is handled by our own JWT layer (Argon2id hashing + HS256 tokens). The Flutter app calls these endpoints directly — not Supabase Auth.

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | None | Register with name, phone, password, UPI ID, zone |
| `POST` | `/api/v1/auth/login` | None | Login with phone + password, returns JWT token |
| `GET` | `/api/v1/auth/me` | Bearer JWT | Get the currently logged in worker's profile |

**Register request:**
```json
{
  "name": "Arjun Sharma",
  "phone": "9876543210",
  "password": "securepass123",
  "upi_id": "arjun@upi",
  "zone_id": 1
}
```

**Login response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
  "token_type": "bearer",
  "worker": { "id": 1, "name": "Arjun Sharma", "zone_id": 1 }
}
```

Pass the token as `Authorization: Bearer <token>` on protected endpoints.

---

### Zones

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/zones` | None | List all 8 dark store zones with coordinates |

**Sample response:**
```json
[
  {
    "id": 1,
    "name": "Koramangala Dark Store",
    "pincode": "560034",
    "city": "Bengaluru",
    "latitude": 12.9352,
    "longitude": 77.6245,
    "base_risk_multiplier": 1.2
  }
]
```

The `base_risk_multiplier` scales the coverage amount: a 1.2x zone gives ₹1,200 coverage on ₹1,000 base. Zones with higher multipliers are in historically riskier delivery corridors.

---

### Workers

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/workers/register` | None | Legacy no-password registration (smoke test / demo) |
| `GET` | `/api/v1/workers` | None | List all workers |
| `GET` | `/api/v1/workers/{id}` | None | Worker profile |
| `PATCH` | `/api/v1/workers/{id}/zone` | None | Switch active delivery zone |
| `GET` | `/api/v1/workers/{id}/dashboard` | None | Full home screen data in one call |

#### Worker Dashboard — the Flutter home screen endpoint

`GET /api/v1/workers/{id}/dashboard` returns everything the home screen needs in one round trip:

```json
{
  "worker": {
    "id": 1, "name": "Arjun Sharma", "cold_start_active": true
  },
  "zone": {
    "id": 1, "name": "Koramangala Dark Store", "risk_level": "HIGH"
  },
  "active_policy": {
    "id": 2, "coverage_amount": 1200.0, "premium_paid": 19.0,
    "valid_until": "2026-04-20T23:59:59Z", "status": "Active"
  },
  "live_weather": {
    "rainfall_mm_hr": 38.5, "temperature_c": 23.1,
    "wet_bulb_c": 21.8, "humidity_pct": 88.0,
    "condition": "Heavy Rain", "aqi": 144, "aqi_category": "Unhealthy",
    "data_source": "openweathermap"
  },
  "last_claim": {
    "id": 3, "status": "Auto-Approved",
    "payout_amount": 300.0, "payout_pct": 25.0,
    "event_type": "Rain", "created_at": "2026-04-15T18:30:00Z"
  },
  "loyalty": {
    "consecutive_quiet_weeks": 3,
    "shield_credits_eligible": false,
    "weeks_until_eligible": 1
  }
}
```

#### Dynamic Zone Switch

`PATCH /api/v1/workers/{id}/zone` — handles the case where a worker picks up a guest shift at a different dark store. Their insurance coverage follows them immediately.

```json
{ "zone_id": 3 }
```

---

### Policies

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/policies/quote/{worker_id}` | None | Live premium quote with weather breakdown |
| `POST` | `/api/v1/policies/enroll` | None | Enroll for this week's coverage |
| `GET` | `/api/v1/policies/worker/{worker_id}` | None | Policy history |

**Enroll request:**
```json
{ "worker_id": 1 }
```

**Quote response — shows full calculation breakdown:**
```json
{
  "worker_id": 1,
  "zone_name": "Koramangala Dark Store",
  "r_base": 5.0,
  "m_weather": 2.8,
  "m_social": 1.0,
  "m_coldstart": 1.2,
  "h_expected": 1.0,
  "base_risk_multiplier": 1.2,
  "raw_premium": 20.16,
  "premium": 20.16,
  "coverage_amount": 1200.0,
  "weather_condition": "Heavy Rain (25-40 mm/hr, depression forming)",
  "weather_source": "openweathermap",
  "live_rainfall_mm_hr": 38.5,
  "live_temperature_c": 23.1,
  "live_wet_bulb_c": 21.8,
  "live_humidity_pct": 88.0,
  "cold_start_active": true,
  "shield_credits_applied": false,
  "discount_amount": 0.0,
  "message": "Cold-start active (first 14 days). M_coldstart = 1.2 applied."
}
```

A worker cannot enroll twice in the same week. The endpoint returns 409 if an active policy already exists.

---

### Claims

> **There is no POST /claims endpoint.** Claims are generated entirely server-side when a trigger fires. This is the zero-touch experience — the worker never submits anything.

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/v1/claims/worker/{worker_id}` | None | All claims for a worker |
| `GET` | `/api/v1/claims/{claim_id}` | None | Single claim detail |
| `GET` | `/api/v1/claims/{claim_id}/status` | None | Lightweight status poll (just status + payout) |
| `POST` | `/api/v1/claims/{claim_id}/appeal` | None | Dispute a Blocked claim (72-hour window) |

**Worker claims response:**
```json
{
  "worker_id": 1,
  "worker_name": "Arjun Sharma",
  "total_claims": 2,
  "total_payout": 300.0,
  "claims": [
    {
      "id": 3,
      "status": "Auto-Approved",
      "payout_amount": 300.0,
      "payout_percentage": 25.0,
      "trust_score": 82.4,
      "event_type": "Rain",
      "event_severity": "Extreme",
      "zone_name": "Koramangala Dark Store",
      "upi_webhook_fired": true,
      "appeal_deadline": null,
      "created_at": "2026-04-15T18:30:00Z"
    }
  ]
}
```

**Appeal a blocked claim:**
```json
POST /api/v1/claims/3/appeal
{
  "worker_id": 1,
  "reason": "I was actively delivering in Zone 1 at the time of the event."
}
```
The claim moves to `Under-Appeal` and appears in the admin review queue.

**Lightweight status poll (Flutter polls this every 60s during Soft-Hold):**
```json
GET /api/v1/claims/3/status
→ { "claim_id": 3, "status": "Auto-Approved", "payout_amount": 300.0, "appeal_deadline": null }
```

---

### Admin

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/admin/simulate-trigger` | None | Force-fire a parametric trigger |
| `GET` | `/api/v1/admin/triggers` | None | Full trigger history |
| `GET` | `/api/v1/admin/stats` | None | Platform-wide statistics + loss ratio |
| `GET` | `/api/v1/admin/claims/soft-hold` | None | Review queue of Soft-Hold and Under-Appeal claims |
| `PATCH` | `/api/v1/admin/claims/{id}/resolve` | None | Approve or reject a held claim |
| `GET` | `/api/v1/admin/zones/risk-map` | None | Live per-zone weather risk map |

#### Simulate Trigger

```json
POST /api/v1/admin/simulate-trigger
{
  "zone_id": 1,
  "event_type": "Rain",
  "severity": "Extreme",
  "duration_hours": 0.75,
  "raw_value": 38.5
}
```

`duration_hours` is required for Rain because payout scales with how long it lasts:

| Rain Duration | Payout |
|---|---|
| 45 min – 2 hr | 25% of coverage |
| 2 hr – 4 hr | 50% of coverage |
| > 4 hr | 100% of coverage |

**Response:**
```json
{
  "trigger_event_id": 5,
  "zone_name": "Koramangala Dark Store",
  "event_type": "Rain",
  "duration_hours": 0.75,
  "payout_percentage": 25.0,
  "claims_generated": 3,
  "deduped_skipped": 1,
  "auto_approved": 2,
  "soft_hold": 1,
  "blocked": 0,
  "total_payout": 600.0,
  "message": "Trigger processed. 2 instant UPI payouts (₹600 total), 1 on soft-hold, 0 blocked, 1 deduped/capped."
}
```

#### Resolve a Soft-Hold Claim

```json
PATCH /api/v1/admin/claims/7/resolve
{
  "decision": "approve",
  "reason": "Location data confirmed worker was in zone at event time."
}
```

`approve` → fires UPI webhook instantly, marks `Auto-Approved`.  
`reject` → marks `Blocked`, reason is logged for ML feedback loop.

#### Platform Stats

```json
GET /api/v1/admin/stats
{
  "workers": { "total": 25, "active": 22 },
  "policies": { "active": 18, "total_premiums": 842.0 },
  "claims": {
    "auto_approved": 12, "soft_hold": 3, "blocked": 1,
    "under_appeal": 1, "total_payout": 4500.0
  },
  "financial": {
    "loss_ratio_pct": 53.44,
    "loss_ratio_target": 55.0,
    "reserve_healthy": true
  }
}
```

`loss_ratio_pct` is total payouts ÷ total premiums collected × 100. Target is ≤ 55% to stay solvent.

---

## Core Business Logic

### Premium Formula

```
Premium = max(₹19, min(₹99, R_base × M_weather × M_social × H_expected × M_coldstart))
```

| Variable | Value | Source |
|---|---|---|
| `R_base` | ₹5 (fixed) | Constant |
| `M_weather` | 1.0 – 3.5 | **Live OpenWeatherMap API** (zone lat/lon call) |
| `M_social` | 1.0 – 2.0 | Mock per zone (no free API for Indian social disruption) |
| `H_expected` | 1.0 | Constant (part-time shift ratio hook available) |
| `M_coldstart` | 1.2 first 14 days, then 1.0 | Derived from `enrollment_date` |

**M_weather mapping from live rainfall:**

| Rainfall (mm/hr) | M_weather | Condition Label |
|---|---|---|
| 0 | 1.0 | Clear / No Precipitation |
| > 0 | 1.4 | Light Rain |
| ≥ 10 | 2.0 | Moderate Rain |
| ≥ 25 | 2.8 | Heavy Rain |
| ≥ 40 | 3.5 | Severe Monsoon / Cyclonic |

The Heat trigger uses **wet-bulb temperature** calculated via the Stull (2011) formula from OWM's temperature + humidity — threshold is 38°C wet-bulb.

### Payout Scaling

Every trigger type pays a fixed percentage of that week's coverage amount:

| Trigger | Condition | Payout |
|---|---|---|
| Rain | 45 min – 2 hr | 25% |
| Rain | 2 hr – 4 hr | 50% |
| Rain | > 4 hr | 100% |
| AQI | AQI > 300 | 50% |
| Outage | 0 orders ≥ 45 min | 25% |
| Social | Bandh / Curfew | 75% |
| Heat | Wet-bulb ≥ 38°C | 50% |

**Simultaneous trigger dedup:** If multiple triggers fire within a 6-hour window for the same policy, only the highest-value one pays. A second lower-value trigger returns `deduped_skipped`.

**Weekly cap:** Total payouts across all triggers in one policy week cannot exceed 100% of coverage. Further triggers return `deduped_skipped` once the cap is reached.

### Trust Score Engine

Three-layer fraud detection produces a score from 0–100:

```
final_score = (stochastic_signal × 0.70) + (worker_baseline × 0.30)
```

| Score | Status | Action |
|---|---|---|
| ≥ 75 | Auto-Approved | UPI webhook fires immediately |
| 40 – 74 | Soft-Hold | Goes to admin review queue |
| < 40 | Blocked | Worker notified, 72-hr appeal window opens |

The three signal layers (device fingerprint, behavioral analytics, referral network graph) are structurally implemented but currently use stochastic proxies — the right inputs come from a mobile SDK in production.

### Zero-Touch Claim Flow

```
POST /admin/simulate-trigger (or real event daemon)
         │
         ▼
TriggerEvent written to DB (with duration_hours, raw_value)
         │
         ▼
Find all Active Policies for workers in that zone
         │
         ▼
For each policy:
  1. Check 6-hour dedup window — skip if higher trigger already paid
  2. Check weekly cap — skip if 100% coverage already committed
  3. Calculate payout: coverage_amount × payout_percentage
  4. Run trust score engine
  5. Write Claim record (Auto-Approved / Soft-Hold / Blocked)
  6. If Auto-Approved → fire UPI webhook immediately
         │
         ▼
Worker opens Flutter app → GET /claims/worker/{id}
→ Money is already there. Worker did nothing.
```

### Shield Credits Loyalty

- After **4 consecutive claim-free weeks**, the 5th premium is discounted **20%** (capped at ₹20 off)
- A "quiet week" = an expired policy with no Auto-Approved or Soft-Hold claims
- A single week with a payout **resets the counter to zero**
- Shield Credits **do not apply during the 14-day cold-start period**
- The consecutive count is recalculated live from expired policy history on every quote

---

## Background Jobs

Two jobs run automatically on startup via APScheduler:

| Job | Schedule | What it does |
|---|---|---|
| Policy expiry | Every hour | Marks all policies where `end_date < now` as `Expired` — enables the Shield Credits streak logic |
| Weather cache refresh | Every 15 min | Pre-fetches OWM + AQICN data for all 8 zones and stores in memory so dashboard and risk map endpoints are instant |

The weather cache is what makes `GET /admin/zones/risk-map` fast — it reads from memory instead of making 8 serial OWM calls per request.

---

## For Flutter Developers

### Recommended call sequence on app open:

```
1. POST /api/v1/auth/login         → get JWT token
2. GET  /api/v1/workers/{id}/dashboard  → everything for the home screen in one call
3. GET  /api/v1/claims/{id}/status      → poll every 60s during a Soft-Hold claim
```

### Key things to know:

- **No claim submission.** Never show a "file claim" button. Claims appear automatically in `GET /claims/worker/{id}` after a trigger fires.
- **payout_percentage** is always present on claims. Use it to explain to the worker why they got 25% instead of 100% (e.g. "Rain lasted 45 minutes — 25% payout applied").
- **appeal_deadline** is non-null on Blocked claims. Show a countdown and a dispute button that calls `POST /claims/{id}/appeal`.
- **weather_source** in the quote response tells you if the data is from `openweathermap` (live), `mock` (fallback), or `mock_fallback` (API failed). Show a small indicator in the UI.
- **cold_start_active** on the worker object — show an onboarding banner explaining the higher premium during the first 14 days.
- **risk_level** in the dashboard zone object — LOW / MEDIUM / HIGH. Use this to drive a color-coded home screen banner.

### Auth header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6...
```

---

## Running the Smoke Test

The smoke test hits every major endpoint and asserts correctness (including payout percentages). It is idempotent — safe to run multiple times against a live database.

```bash
# Server must be running first
uvicorn app.main:app --host 127.0.0.1 --port 8000

# Then in a new terminal
python smoke_test.py
```

Expected output:
```
[1]  Health .............. HEALTHY | db=postgresql | real-weather
[2]  Zones ............... 8 seeded | coords=yes
[3]  Register Worker ..... ID=5 | cold_start=True | zone=Koramangala Dark Store
[4]  Premium Quote ....... INR19.0 | M_weather=1.0 | source=openweathermap
[5]  Enroll Policy ....... policy_id=5 | premium=INR19.0 | coverage=INR1200.0
[6a] Rain 45min ......... payout_pct=25.0%
[6b] Heat 4hr ........... payout_pct=50.0%
[7]  Worker Dashboard .... risk=LOW | aqi=144 | coverage=INR1200.0
[8]  Worker Claims ....... 2 claim(s) | total_paid=INR300.0
[9]  Soft-Hold Queue ..... N pending
[10] Zone Risk Map ....... 8 zones | 0 HIGH risk
[11] Platform Stats ..... loss_ratio tracked

ALL 11 TESTS PASSED
```

---

## Database & Migrations

The backend is connected to **Supabase PostgreSQL** via the `DATABASE_URL` in `.env`.

For local development, swap `DATABASE_URL` to `sqlite:///./hustlehalt.db` — no other changes needed. The engine factory in `database.py` handles both automatically.

### Schema migrations

When new columns are needed, they are tracked in versioned SQL files:

| File | What it adds |
|---|---|
| `migrate_v1_1.sql` | `latitude`, `longitude`, `city` on zones; `duration_hours`, `raw_value`, `confidence_score` on trigger_events; `payout_percentage`, `goodwill_credit_applied`, `appeal_deadline` on claims |

Run a migration once against Supabase using `psycopg2` — the SQL file uses `ADD COLUMN IF NOT EXISTS` so it is safe to re-run.

---

## Hackathon Demo Script

Run these in Swagger UI at `http://localhost:8000/docs`:

1. `GET /api/v1/zones` — show 8 dark store zones with real coordinates
2. `POST /api/v1/auth/register` — register Arjun in Zone 1 (Koramangala)
3. `GET /api/v1/policies/quote/1` — live premium quote showing OWM weather source
4. `POST /api/v1/policies/enroll` — activate this week's coverage
5. `POST /api/v1/admin/simulate-trigger` — fire Rain trigger with `duration_hours: 0.75` → 25% payout
6. `POST /api/v1/admin/simulate-trigger` — fire the same zone with `duration_hours: 4.5` → 100% payout, notice `deduped_skipped`
7. `GET /api/v1/workers/1/dashboard` — Arjun's phone, money already there
8. `GET /api/v1/admin/claims/soft-hold` — show the admin review queue
9. `GET /api/v1/admin/stats` — platform stats with live loss ratio

---

Built for the **Guidewire DEVTrails Hackathon 2026** · Theme: *Protect Your Worker*
