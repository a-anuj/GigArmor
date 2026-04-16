-- HustleHalt — Schema Migration v1.1
-- Run this once against your Supabase Postgres database
-- Adds all new columns introduced in the Phase 1–5 backend upgrade
-- Safe to run on an existing database — uses ADD COLUMN IF NOT EXISTS

-- ── zones table: add lat/lon and city for real weather API calls ──────────────
ALTER TABLE zones ADD COLUMN IF NOT EXISTS latitude FLOAT;
ALTER TABLE zones ADD COLUMN IF NOT EXISTS longitude FLOAT;
ALTER TABLE zones ADD COLUMN IF NOT EXISTS city VARCHAR(100) NOT NULL DEFAULT 'Bengaluru';

-- Update existing seeded zones with real Bengaluru coordinates
UPDATE zones SET latitude = 12.9352, longitude = 77.6245, city = 'Bengaluru' WHERE id = 1;
UPDATE zones SET latitude = 12.9784, longitude = 77.6408, city = 'Bengaluru' WHERE id = 2;
UPDATE zones SET latitude = 12.9698, longitude = 77.7500, city = 'Bengaluru' WHERE id = 3;
UPDATE zones SET latitude = 12.9116, longitude = 77.6389, city = 'Bengaluru' WHERE id = 4;
UPDATE zones SET latitude = 12.9591, longitude = 77.7009, city = 'Bengaluru' WHERE id = 5;
UPDATE zones SET latitude = 12.8458, longitude = 77.6603, city = 'Bengaluru' WHERE id = 6;
UPDATE zones SET latitude = 12.9063, longitude = 77.5857, city = 'Bengaluru' WHERE id = 7;
UPDATE zones SET latitude = 11.0014, longitude = 76.9628, city = 'Coimbatore' WHERE id = 8;

-- ── trigger_events table: add duration and measurement fields ─────────────────
ALTER TABLE trigger_events ADD COLUMN IF NOT EXISTS duration_hours FLOAT DEFAULT 0.0;
ALTER TABLE trigger_events ADD COLUMN IF NOT EXISTS raw_value FLOAT;
ALTER TABLE trigger_events ADD COLUMN IF NOT EXISTS confidence_score FLOAT;

-- ── claims table: add payout scaling and appeal fields ────────────────────────
ALTER TABLE claims ADD COLUMN IF NOT EXISTS payout_percentage FLOAT NOT NULL DEFAULT 100.0;
ALTER TABLE claims ADD COLUMN IF NOT EXISTS goodwill_credit_applied BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE claims ADD COLUMN IF NOT EXISTS appeal_deadline TIMESTAMP;

-- Backfill payout_percentage for any existing claims (they were all 100%)
UPDATE claims SET payout_percentage = 100.0 WHERE payout_percentage IS NULL;
