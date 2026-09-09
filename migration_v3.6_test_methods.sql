-- v3.6 — Test Methods (Competency & Re-evaluation Tracking), CL-D-1000-0010 Rev.08
-- Reference only: this has already been applied to your live "LSP Lab ISO 17025 Tracker" Supabase
-- project. You do not need to run this — kept here for disaster-recovery / reference, same as the
-- other migration_*.sql files in this delivery.
--
-- This feature was originally prototyped as a separate app with its own cet_methods/cet_people/
-- cet_settings tables, then merged into this same Olefins Onboarding Tracker (single page, single
-- roster) per your request. The merge migration renamed cet_methods -> onb_methods (keeping its 179
-- real rows), added a "methods" jsonb column to the existing onb_people table (each person's own
-- method assignments + evaluation history), and dropped cet_people/cet_settings (both were empty —
-- never held real data, only ever touched by automated tests during the standalone prototype).
--
-- Shown below as the resulting schema (idempotent create/alter), not the historical rename steps.

create table if not exists onb_methods (
  id text primary key,              -- Document No., e.g. CL-T-2000-0001
  name text not null,
  classroom boolean not null default true,
  training_type text,               -- 'A' | 'B' | 'C' | 'D' | null (evaluation type used for initial classroom/practical training)
  freq_years integer,               -- re-evaluation frequency in years; null = "-" = no periodic re-evaluation required
  reeval_type text,                 -- 'A' | 'B' | 'C' | 'D' | 'Intralaboratory' | null (evaluation type used at re-evaluation)
  remarks text not null default '', -- evaluation form reference, e.g. CL-F-1000-0052 / 0079
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table onb_people add column if not exists methods jsonb not null default '{}'::jsonb;
-- onb_people.methods[methodId] = { assigned: bool, history: [ { date, evalType, result, evaluator, notes } ] }
-- "assigned" means this person is expected/qualified to be evaluated on this method. The most recent
-- entry in "history" (by date) is what the tracker treats as the current evaluation — there's no
-- separate "current" field, to avoid it drifting out of sync with history.

alter table onb_methods enable row level security;
drop policy if exists onb_methods_allow_all on onb_methods;
create policy onb_methods_allow_all on onb_methods for all using (true) with check (true);

create or replace function onb_touch_updated_at_methods() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists onb_methods_touch on onb_methods;
create trigger onb_methods_touch before update on onb_methods
  for each row execute function onb_touch_updated_at_methods();

-- The 179 test methods themselves (seeded from CL-D-1000-0010 Rev.08) are not repeated here since
-- they're regular data, not schema — they're already live in onb_methods. If you ever need to
-- re-seed a fresh database, re-extract them from the source Excel file and insert into onb_methods.
