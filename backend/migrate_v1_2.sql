-- Database migration to add q_commerce_platform
-- Run this once against your Supabase Postgres database

ALTER TABLE workers ADD COLUMN IF NOT EXISTS q_commerce_platform VARCHAR(100) DEFAULT 'Zomato';
ALTER TABLE workers ALTER COLUMN upi_id DROP NOT NULL;
