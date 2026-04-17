-- HustleHalt — Migration v1.3
-- Adds worker_activity_logs table for weekly delivery session tracking.
-- This data is used by the admin claim review system to contextualise
-- Soft-Hold / Blocked claims: "Worker logged 4.5 hrs / 18 orders before event."

CREATE TABLE IF NOT EXISTS worker_activity_logs (
    id              SERIAL PRIMARY KEY,
    worker_id       INTEGER NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    policy_id       INTEGER REFERENCES policies(id) ON DELETE SET NULL,
    logged_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    activity_type   VARCHAR(50) NOT NULL DEFAULT 'delivery_session',
                    -- 'delivery_session' | 'app_heartbeat' | 'zone_checkin'
    zone_id         INTEGER REFERENCES zones(id) ON DELETE SET NULL,
    latitude        DOUBLE PRECISION,
    longitude       DOUBLE PRECISION,
    orders_count    INTEGER NOT NULL DEFAULT 0,
    session_hours   DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    notes           TEXT
);

CREATE INDEX IF NOT EXISTS idx_activity_worker_id   ON worker_activity_logs(worker_id);
CREATE INDEX IF NOT EXISTS idx_activity_logged_at   ON worker_activity_logs(logged_at);
CREATE INDEX IF NOT EXISTS idx_activity_policy_id   ON worker_activity_logs(policy_id);
