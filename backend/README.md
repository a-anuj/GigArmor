# GigArmor Backend API

> **AI-powered parametric income insurance for gig economy workers.**  
> Built for the **Guidewire DEVTrails Hackathon** — Theme: *Protect Your Worker*

---

## What is GigArmor?

GigArmor provides **zero-touch parametric insurance** for gig delivery workers (Zomato, Swiggy, Blinkit, etc.).  
When a qualifying environmental event occurs in a worker's zone — extreme rain, bad AQI, platform outage, social disruption, or heat wave — **claims are generated automatically and money is credited to the worker's UPI ID without them having to do anything.**

---

## Architecture

```
GigArmor/backend/
├── app/
│   ├── main.py                   # FastAPI app, lifespan, CORS, router registration
│   ├── config.py                 # Pydantic-settings (reads from .env)
│   ├── database.py               # SQLAlchemy engine + session factory
│   │
│   ├── models/                   # SQLAlchemy ORM models
│   │   ├── zone.py               # Dark Store zones
│   │   ├── worker.py             # Gig workers (with cold_start_active property)
│   │   ├── policy.py             # Weekly parametric policies
│   │   ├── trigger_event.py      # Parametric event records
│   │   └── claim.py              # Auto-generated claims (no worker submission)
│   │
│   ├── schemas/                  # Pydantic v2 request/response schemas
│   │   ├── worker.py
│   │   ├── policy.py             # Includes detailed PremiumQuote schema
│   │   ├── claim.py
│   │   └── trigger.py
│   │
│   ├── routers/                  # FastAPI route handlers
│   │   ├── workers.py            # /api/v1/workers/* + /api/v1/zones
│   │   ├── policies.py           # /api/v1/policies/*
│   │   ├── claims.py             # /api/v1/claims/*
│   │   └── admin.py              # /api/v1/admin/*
│   │
│   └── services/                 # Business logic (pure Python, no HTTP deps)
│       ├── premium_engine.py     # Dynamic premium formula + loyalty logic
│       ├── trust_engine.py       # Fraud detection trust score (0–100)
│       ├── trigger_service.py    # Zero-touch claim orchestrator
│       └── webhook_service.py    # Mock UPI payout webhook
│
├── requirements.txt
├── .env.example
├── .gitignore
├── smoke_test.py                 # End-to-end API test script
└── README.md
```

**Tech Stack:**

| Layer | Technology |
|---|---|
| Framework | FastAPI 0.111 |
| ORM | SQLAlchemy 2.0 (synchronous) |
| Database | SQLite (default) / PostgreSQL (env switch) |
| Validation | Pydantic v2 |
| Server | Uvicorn |
| Background Tasks | FastAPI BackgroundTasks |

---

## Quick Start

### Prerequisites
- Python 3.11+
- No database setup needed (SQLite is zero-config)

### 1. Clone & navigate
```bash
cd GigArmor/backend
```

### 2. Create virtual environment
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure environment (optional)
```bash
cp .env.example .env
# Edit .env if you want to switch to PostgreSQL
```

### 5. Start the server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The server auto-creates the SQLite database (`gigarmor.db`) and seeds **7 Bengaluru dark store zones** on first startup.

### 6. Open the interactive API docs
```
http://localhost:8000/docs    ← Swagger UI (recommended for demo)
http://localhost:8000/redoc   ← ReDoc
```

---

## API Reference

### Health

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Service info |
| `GET` | `/health` | Health check |

---

### Zones

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/zones` | List all dark store zones |

**Sample response:**
```json
[
  {"id": 1, "name": "Koramangala Dark Store", "pincode": "560034", "base_risk_multiplier": 1.2},
  {"id": 3, "name": "Whitefield Spoke",        "pincode": "560066", "base_risk_multiplier": 1.5}
]
```

---

### Workers — Phase 2

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/workers/register` | Register a new gig worker |
| `GET`  | `/api/v1/workers` | List all workers |
| `GET`  | `/api/v1/workers/{worker_id}` | Get worker profile |

**Register request body:**
```json
{
  "name": "Arjun Sharma",
  "phone": "9876543210",
  "upi_id": "arjun@upi",
  "zone_id": 1
}
```

**Cold-Start Logic:**  
Workers enrolled for ≤ 14 days receive `cold_start_active: true` and a `M_coldstart = 1.2` premium multiplier automatically derived from their `enrollment_date`. No separate flag is stored.

---

### Policies — Phase 3 & 4

| Method | Endpoint | Description |
|---|---|---|
| `GET`  | `/api/v1/policies/quote/{worker_id}` | Dynamic premium quote |
| `POST` | `/api/v1/policies/enroll` | Enroll in this week's policy |
| `GET`  | `/api/v1/policies/worker/{worker_id}` | Worker's policy history |

#### Premium Calculation Formula

```
Premium = max(₹19, min(₹99, R_base × M_weather × M_social × H_expected × M_coldstart))
```

| Variable | Description | Range |
|---|---|---|
| `R_base` | Base rate | ₹5 (fixed) |
| `M_weather` | Mock weather forecast per zone | 1.0 (Clear) → 3.5 (Severe Monsoon) |
| `M_social` | Mock social disruption per zone | 1.0 (Normal) → 2.0 (Bandh/Curfew) |
| `H_expected` | Expected hours multiplier | 1.0 (constant for demo) |
| `M_coldstart` | Cold-start multiplier | 1.2 (first 14 days), 1.0 afterwards |

**Floor:** ₹19 · **Ceiling:** ₹99

#### Shield Credits (Loyalty)
- **4 consecutive claim-free weeks** → **20% discount** on the 5th week's premium
- Discount is **capped at ₹99 maximum**
- Quiet week = expired policy with no Auto-Approved or Soft-Hold claims
- Shield Credits are **not applied during cold-start period**

**Quote sample response:**
```json
{
  "worker_id": 1,
  "worker_name": "Arjun Sharma",
  "zone_id": 1,
  "zone_name": "Koramangala Dark Store",
  "r_base": 5.0,
  "m_weather": 2.8,
  "m_social": 1.0,
  "m_coldstart": 1.2,
  "h_expected": 1.0,
  "base_risk_multiplier": 1.2,
  "raw_premium": 20.16,
  "premium": 20.16,
  "weather_condition": "Heavy Rain",
  "social_condition": "Normal",
  "cold_start_active": true,
  "consecutive_quiet_weeks": 0,
  "shield_credits_applied": false,
  "discount_amount": 0.0,
  "coverage_amount": 1200.0,
  "message": "🆕 Cold-start premium (first 2 weeks, M=1.2 applied)"
}
```

---

### Claims — Phase 5 (Zero-Touch)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/claims/worker/{worker_id}` | Worker polls for claims (zero-touch mobile endpoint) |
| `GET` | `/api/v1/claims/{claim_id}` | Get a specific claim |

> ⚠️ **There is no `POST /claims` endpoint.** Claims are generated entirely server-side when a trigger fires. This is the "Zero-Touch" experience.

**Worker view response:**
```json
{
  "worker_id": 1,
  "worker_name": "Arjun Sharma",
  "total_claims": 1,
  "total_payout": 1200.0,
  "claims": [
    {
      "id": 1,
      "policy_id": 1,
      "trigger_event_id": 1,
      "payout_amount": 1200.0,
      "trust_score": 85.13,
      "status": "Auto-Approved",
      "event_type": "Rain",
      "event_severity": "Extreme",
      "zone_name": "Koramangala Dark Store",
      "upi_webhook_fired": true,
      "created_at": "2026-04-04T08:04:57Z"
    }
  ]
}
```

---

### Admin / Demo — Phase 5

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/admin/simulate-trigger` | ⚡ Force-fire a parametric trigger |
| `GET`  | `/api/v1/admin/triggers` | List all trigger events |
| `GET`  | `/api/v1/admin/stats` | Platform-wide statistics |

#### The 5 Parametric Triggers

| Event Type | Threshold |
|---|---|
| `Rain` | Extreme Rainfall > 35 mm/hr for ≥ 45 minutes |
| `AQI` | Severe AQI > 300 for ≥ 3 hours |
| `Outage` | Platform Outage: 0 orders dispatched for ≥ 45 min |
| `Social` | Bandh / Curfew — weighted news + traffic API consensus |
| `Heat` | Extreme Heat > 38°C wet-bulb for ≥ 4 hours |

**Simulate trigger request:**
```json
{
  "zone_id": 1,
  "event_type": "Rain",
  "severity": "Extreme"
}
```

**Simulate trigger response:**
```json
{
  "trigger_event_id": 1,
  "zone_id": 1,
  "zone_name": "Koramangala Dark Store",
  "event_type": "Rain",
  "severity": "Extreme",
  "threshold_description": "Extreme Rainfall >35 mm/hr sustained for ≥45 minutes",
  "active_policies_found": 1,
  "claims_generated": 1,
  "auto_approved": 1,
  "soft_hold": 0,
  "blocked": 0,
  "total_payout": 1200.0,
  "message": "Trigger processed. 1 UPI payouts fired instantly, 0 on soft-hold, 0 blocked."
}
```

---

## Zero-Touch Claim Flow

```
Admin fires simulate-trigger
         │
         ▼
TriggerEvent created in DB
         │
         ▼
Query: All Active Policies in Zone
         │
         ▼
For each policy → Trust Score Engine
  ├── Score ≥ 75  → Auto-Approved → UPI Webhook fired 🚀
  ├── Score 40–74 → Soft-Hold    → Awaiting re-verification ⏳
  └── Score < 40  → Blocked      → Suspected fraud 🚫
         │
         ▼
Claim records written to DB
         │
         ▼
Worker opens app → GET /claims/worker/{id}
→ Money already there, no action taken
```

---

## Trust Score Engine

The fraud detection engine blends a **stochastic signal** (live data proxy) with the worker's **historical baseline**:

```
final_score = (stochastic × 0.70) + (baseline × 0.30)
```

**Demo distribution (biased towards legitimacy):**
- 70% chance → Score 75–100 → Auto-Approved
- 20% chance → Score 40–74 → Soft-Hold
- 10% chance → Score < 40  → Blocked

---

## Hackathon Demo Script (2-minute video flow)

Run these in order via Swagger UI at `http://localhost:8000/docs`:

1. **`GET /api/v1/zones`** — show available dark store zones
2. **`POST /api/v1/workers/register`** — register worker Arjun in Zone 1
3. **`GET /api/v1/policies/quote/1`** — show dynamic premium (note cold-start, weather multiplier)
4. **`POST /api/v1/policies/enroll`** — enroll for the week, coverage ₹1,200 activated
5. **`POST /api/v1/admin/simulate-trigger`** — fire extreme rain event in Zone 1
6. **`GET /api/v1/claims/worker/1`** — show money already credited, worker did nothing!
7. **`GET /api/v1/admin/stats`** — platform dashboard summary

---

## Switching to PostgreSQL

Change one line in `.env`:

```env
DATABASE_URL=postgresql://gigarmor:secret@localhost:5432/gigarmor_db
```

Install PostgreSQL driver:
```bash
pip install psycopg2-binary
```

Then restart the server. All tables are created automatically on startup.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DATABASE_URL` | `sqlite:///./gigarmor.db` | Database connection string |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis URL (reserved for production) |
| `APP_ENV` | `development` | Environment name |
| `SECRET_KEY` | `gigarmor-dev-secret-key` | Change in production |
| `DEBUG` | `true` | Enables SQLAlchemy query logging |
| `UPI_WEBHOOK_URL` | *(mock)* | Real UPI gateway URL in production |
| `UPI_API_KEY` | *(mock)* | Real UPI gateway API key |

---

## Git Branch

This backend lives on the `backend-hari` branch.

```
git checkout backend-hari
```

### Commit History

| Commit | Description |
|---|---|
| Phase 1 | Foundation & DB schema — models, FastAPI app, lifespan zone seeding |
| chore | `.gitignore` — excludes pyc, db, venv files |
| Phase 2 | Worker registration with cold-start logic |
| Phase 3 | Dynamic premium calculation engine |
| Phase 4 | Policy enrollment & Shield Credits loyalty |
| Phase 5 | Zero-touch claims, 5 parametric triggers & trust engine |
| docs | Comprehensive backend README |

---

## License

Built for the **Guidewire DEVTrails Hackathon 2026** · Theme: *Protect Your Worker*
