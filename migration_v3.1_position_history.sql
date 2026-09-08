-- Olefins Onboarding Tracker — v3.1 schema addition: position/rotation history.
--
-- This has ALREADY been applied to your live Supabase project (wybpexwcrngodkvrrifr) and the
-- existing 24 people have already been backfilled. You do NOT need to run this — it's kept here,
-- alongside migration.sql, purely as a record / for disaster recovery.
--
-- What it adds:
--   - position_effective_date: the date a person's CURRENT position started. This is what course
--     schedules (Phase 1/2/3 target dates) are now computed from — NOT start_date. For someone who
--     has never rotated, it's the same as start_date.
--   - position_history: a JSON array logging every past position a person held, e.g.
--       [{"positionKey":"oil","effectiveDate":"2024-01-17","endDate":"2026-09-07","note":"rotated from Oil Analyst"}]
--     start_date itself is never modified — it stays the person's original hire date, always.

ALTER TABLE onb_people
  ADD COLUMN IF NOT EXISTS position_effective_date TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS position_history JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Backfill: for everyone who has never changed position, treat their hire date as their
-- position-effective date too.
UPDATE onb_people
SET position_effective_date = start_date
WHERE position_effective_date = '';
