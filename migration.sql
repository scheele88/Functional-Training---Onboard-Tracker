-- ══════════════════════════════════════════════════════════════
--  Olefins Onboarding Tracker — initial schema
--  Tables prefixed onb_ so they sit alongside the ISO 17025
--  tracker's tables (requirements/row_state/settings/...) in the
--  same Supabase project without colliding.
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS onb_people (
  id                TEXT PRIMARY KEY,
  name              TEXT NOT NULL,
  employee_id       TEXT NOT NULL DEFAULT '',
  position_key      TEXT NOT NULL,
  start_date        TEXT NOT NULL DEFAULT '',
  notes             TEXT NOT NULL DEFAULT '',
  employment_status TEXT NOT NULL DEFAULT 'Active',
  end_date          TEXT NOT NULL DEFAULT '',
  items             JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE onb_people ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname='allow_all_onb_people' AND tablename='onb_people'
  ) THEN
    CREATE POLICY allow_all_onb_people ON onb_people FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS onb_settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL DEFAULT ''
);
ALTER TABLE onb_settings ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname='allow_all_onb_settings' AND tablename='onb_settings'
  ) THEN
    CREATE POLICY allow_all_onb_settings ON onb_settings FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- course_edits / custom_courses hold the admin panel's staged-then-applied
-- dated revisions and admin-added courses, exactly mirroring the JSON
-- shape the Artifact version already used (courseEdits / customCourses).
INSERT INTO onb_settings (key, value) VALUES ('course_edits', '{}') ON CONFLICT (key) DO NOTHING;
INSERT INTO onb_settings (key, value) VALUES ('custom_courses', '[]') ON CONFLICT (key) DO NOTHING;

-- Auto-maintain updated_at on every row change (used for last-writer-wins
-- conflict awareness / a "someone else just edited this" indicator later).
CREATE OR REPLACE FUNCTION onb_touch_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS onb_people_touch ON onb_people;
CREATE TRIGGER onb_people_touch BEFORE UPDATE ON onb_people
  FOR EACH ROW EXECUTE FUNCTION onb_touch_updated_at();
