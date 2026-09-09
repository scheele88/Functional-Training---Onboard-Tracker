# Olefins Onboarding Tracker — Online (Supabase-backed) version

## What this is

This is a rebuild of the onboarding tracker as a real, live, multi-user web app — architecturally
identical to the ISO 17025 compliance tracker you already have running: a single HTML page +
`config.js` + a Postgres database on Supabase, hosted on GitHub Pages.

This solves the problem the old version had: the old tracker was a self-contained page that saved
its data *into itself* (via claude.ai's Artifact "publish" mechanism), so two people editing it at
the same time could overwrite each other's changes, and a downloaded/local copy couldn't save at
all. This version saves every change straight to a shared database, so:

- Everyone who opens the page sees the same live data.
- Two people can edit different people's records at the same time without conflicts.
- It works identically whether it's hosted on GitHub Pages, opened as a local file, or opened from
  a shared drive — there's no more "read-only local copy" problem.

## Files in this delivery

- **`index.html`** — the app itself. All the UI/course logic lives here. This is the updated
  (v3.6) version — see "Position changes / rotations", "Per-person Status", "Progress scope
  (new)", "Export Report", and **"Test Methods — Competency & Re-evaluation Tracking (new)"** below
  for what's new.
- **`config.js`** — your Supabase project URL and public ("anon") key. This is what tells
  `index.html` which database to talk to. Safe to commit publicly — see the comment in the file.
  Unchanged from before — you don't need to re-copy it if you already have it in your repo.
- **`migration.sql`** — the original database schema (for reference / disaster recovery). **You do
  not need to run this** — it's already been applied to your Supabase project, and all 24 people's
  data has already been seeded into it.
- **`migration_v3.1_position_history.sql`** — the schema addition for the position-history feature.
  **Also already applied and backfilled** for you — kept for the same reference/disaster-recovery
  reason as `migration.sql`.
- **`migration_v3.3_status_override.sql`** — the schema addition for the new per-person Status
  field (see "Per-person Status" below). **Also already applied** for you.

## Position changes / rotations (new)

On a person's page, there's now a **"Change position"** button next to their position pill. Use it
whenever someone is promoted, moves between labs (e.g. Oil → Gas), or transfers in from another
section:

- Their **Start Date stays untouched** — it's always their original hire date, no matter how many
  times they rotate.
- You pick the new position and an **effective date** (their Day 1 in the new role). The course
  schedule for their new position counts from that date, not their original start date.
- Any course they'd already **Passed** that also exists (by course code) in the new position's
  curriculum carries its Passed status forward automatically — they don't lose credit for
  training they've already completed. Anything genuinely new to the new position starts fresh.
- A **Position history** line appears on their page showing every past role and the dates they
  held it.

## Per-person Status (new)

Every active person now has a **Status**: Newcomer / Rotation / Others. You'll see it as a new
column in the People table, and as a dropdown on each person's own page.

By default it's **Auto-detect** — nothing to set for anyone already in the tracker:
- **Rotation**, if they have a Position history entry (i.e. they've used Change Position at least
  once) — shown with a from → to summary like "Oil → Gas", pulled straight from that history.
- Otherwise **Newcomer**, if their Probation (Phase 1+2) completion is under 100%.
- Otherwise **Others**.

If you want a person's Status to read differently from what auto-detect would say — e.g. someone
who rotated years ago and you'd rather the report call "Others" now, or a rotation that happened
before this tracker existed and was never logged via Change Position — open their page and pick a
value from the Status dropdown instead of "Auto-detect." That choice sticks (it's saved to the
database like everything else) until you set it back to "Auto-detect." The People table shows a
small "· manual" tag whenever a person's Status has been hand-set this way. There's also a Status
filter in the People table's filter bar, next to Employment, so you can quickly see everyone in one
category.

This Status is what the Export Report's Newcomers/Rotated sections use to decide who's included —
see below.

## Progress scope (new)

There's now a **Progress** dropdown in the top-right header, next to "Export report". It decides
which courses count toward *every* completion percentage shown across the app — the dashboard KPI
tiles, the per-position average grid, the People table's Progress column and its "overdue"/"on
track" flag (and the flag filter), and the Export Report's KPIs, charts and tables all follow it.
Three choices:

- **Probation progress (Ph.1+2)** — the default, unchanged from before: just the probation-window
  courses (Phase 1 + Phase 2).
- **Full progress (all phases)** — every course across the whole curriculum (Phase 1 through
  Phase 4), test methods and documents alike.
- **Test methods only** — every course across the whole curriculum whose Type is a Test Method
  (OJT), i.e. the same "Test" vs "Doc" distinction already shown as a badge on each schedule row.
  This one also spans the full curriculum, not just the probation window.

It's a display-only choice — nothing is saved, and it resets to "Probation progress" on reload. It
also doesn't touch a person's own page (which still shows both "Probation courses" and "Full
training plan" side by side, as before) or the People table's multi-select comparison panel (same
reason). And it doesn't change who counts as Newcomer/Rotation/Others — that classification always
stays based on probation completion, regardless of what the dropdown is set to.

When you open **Export report**, the dialog shows a one-line reminder of which basis is currently
selected, so you can double-check before generating.

## Export Report (updated — now a Power BI–style dashboard)

The **"Export report"** button in the top bar builds a 16:9 PowerPoint (.pptx) straight from the
live data in your browser — no server involved, nothing round-trips to Supabase beyond the data
that's already loaded.

The report now reads like a Power BI report rather than a slide deck: a light canvas, white
bordered "visual" cards with a soft shadow and their own mini title, KPI cards, and each section
consolidated onto **one dashboard page** — a KPI row across the top, two chart cards below — with
the full detail table pushed to its own page(s) right after, the way a real Power BI report splits
an Overview page from a Details page.

Tick any combination of three sections (all three can go in one file):

- **Overall results** — one dashboard page (active headcount, avg. probation %, on-track/overdue
  KPIs; a **donut of Newcomer/Rotation/Others composition**; a **bar chart of average probation
  completion by position**, color-coded green/amber/red), then a **Position Breakdown** detail page
  and an **Active Roster** detail page with every active person's probation %.
- **Newcomers** — everyone whose Status (see above) resolves to Newcomer. One dashboard page (KPI
  row, an on-track-vs-overdue donut, and a "Newcomer Snapshot" mini progress-bar list of each
  person's probation %), then a **Newcomer Roster** detail page.
- **Rotated members** — everyone whose Status resolves to Rotation. One dashboard page (KPI row, a
  bar chart of rotations by destination position, and a "Recent Rotations" preview list), then a
  **Rotation History** detail page with a dedicated "Rotation" column (from → to) and the full
  history.

Because every section is driven by the same Status used in the People table, what you see there is
exactly who shows up in the report — including any manual overrides you've set. Only resigned people
are excluded from every section, same as the rest of the dashboard. The file downloads as
`Olefins-UT-Training-Report-<date>.pptx` and is safe to re-run as often as you like since it always
reflects whatever's on screen right now.

## Test Methods — Competency & Re-evaluation Tracking (new, v3.6)

This is the same page as everything above — I originally built this as a separate app and separate
database tables, then folded it into this tracker once it was clear that's how you wanted it used.
If you have `index_competency.html`, `config_competency.js`, `migration_cet.sql`, or
`SETUP_competency.md` from an earlier message in this conversation, **you can ignore/discard all
four** — there's no separate app to set up. Everything below lives in this same `index.html`, uses
the same login-free link, and shares the same 24-person roster and admin password as the course
tracker.

**The problem it solves.** CL-D-1000-0010 *Competency evaluation list for testing method (Rev.08)*
defines which of the lab's 179 routine test methods need periodic re-evaluation/retraining, how
often (1 / 2 / 3 years, or "-" for methods that don't require it), and which evaluation type
applies — but it's a static list, not a tracker. This adds the missing piece: assign each analyst
the methods they're expected to be competent in, log each evaluation as it happens, and the page
computes every next-due date and flags what's overdue, due soon, never evaluated, or failed and
needing retraining — automatically, section-wide.

**Where it shows up:**

- A new **"Test methods needing attention"** tile on the dashboard (overdue + failed-retrain +
  never-evaluated, active people only) — click it to filter the People table to just those people.
- A new **Methods** column in the People table, showing each person's worst-case status.
- A new **"Test Methods — Competency & Re-evaluation"** panel at the bottom of every person's own
  page — tick which of the 179 methods they're expected to be competent in (search/filter the full
  list, or view "Assigned only"), click **Log eval.** to record a date/type/result/evaluator/notes
  for any assigned method, and click **History** to see every past evaluation for that method. This
  is additive — nothing is overwritten, and the tracker always computes status from the most recent
  entry.
- A new **"Manage test methods"** button in the header (next to "Manage courses", behind the same
  admin password) — edit each method's re-evaluation frequency, type, remarks, or active/inactive
  status, or add a custom method not in CL-D-1000-0010.

**Status badges**, computed from each person's evaluation history for that method:

| Badge | Meaning |
|---|---|
| **N/A** | Frequency is "-" — no periodic re-evaluation required. |
| **Never evaluated** | Assigned, a frequency applies, but nothing has been logged yet. |
| **Overdue** | Past the computed next-due date (last evaluation date + frequency). |
| **Due soon** | Within 60 days of the next-due date (change `METHOD_DUE_SOON_DAYS` near the top of the script if the lab wants a different lead time). |
| **On track** | Comfortably before the next-due date. |
| **Failed — retrain** | The most recent logged evaluation was a **Fail**. Per the source document's own note ("If Tester fail re-evaluation, they shall be trained again"), this overrides date-based status entirely — the person doesn't read "on track" again until a new, passing evaluation is logged. |

**How the source list was read.** All 179 methods came from your `CLD10000010_Competency
evaluation list for testing method Rev.08.xlsx`: 6 methods at 1-year frequency, 12 at 2-year, 101
at 3-year, and 60 marked "-" (no periodic re-evaluation). 3 methods (Melt Flow Rate / density
tests) use **"Intralaboratory"** rather than a plain A–D letter as their re-evaluation type, per the
sheet's own note. One row (`CL-T-5000-0064`) is marked *Reference only* with no evaluation type — it
loaded in but inactive by default, so it won't show up as assignable unless you reactivate it from
"Manage test methods." The five method categories used to group the list (Gas Chromatography,
Petroleum & Physical Properties, Water & Environmental, Polymer/Raw Material & Catalyst, Film &
Mechanical Properties) are my own grouping by Document No. prefix, purely a navigation aid — not
something the source document itself states, so rename or regroup however suits the lab if these
don't match how you think about the test methods.

**Starts empty, on purpose.** No historical evaluation dates were seeded in — you asked to fill
those in yourselves once this was live, so every method starts as "Never evaluated" until it's
assigned and a first evaluation is logged.

## Setting it up on GitHub Pages

## Where the data lives

Your existing Supabase project — "LSP Lab ISO 17025 Tracker" (the same one behind your ISO 17025
tracker) — now has three tables for this app: `onb_people`, `onb_settings`, and (new in v3.6)
`onb_methods` (the 179-method catalog from CL-D-1000-0010; each person's method assignments and
evaluation history live in a `methods` column on `onb_people` itself, alongside their course data).
They're namespaced with an `onb_` prefix so they don't collide with the ISO tracker's own tables.
All 24 people currently in the tracker (including the 4 newcomers) have already been loaded in.

## Setting it up on GitHub Pages

Since I don't have GitHub access from this session, these last steps are yours to do — they're the
same steps you (or whoever set up the ISO 17025 tracker) already did for that app:

1. **Create a GitHub repository** (or reuse/add a folder to an existing one) — e.g.
   `olefins-onboarding-tracker`. It can be public; nothing in these files is a secret (see the note
   in `config.js`).
2. **Add `index.html` and `config.js`** to the repository, at the root (or in a `/docs` folder — see
   the next step). The `migration*.sql` files are reference-only, already applied — you don't need
   to upload them anywhere for the app to work.
3. **Enable GitHub Pages**: repository Settings → Pages → set the source branch (usually `main`)
   and folder (`/root` or `/docs`, matching where you put the files).
4. GitHub will give you a URL like `https://<your-username>.github.io/olefins-onboarding-tracker/`.
   That's the live link — share it with the team the same way you shared the ISO 17025 tracker's
   link.
5. Open the link and confirm you see the 24 people and their course data. If you set an admin
   password on the "Manage courses" panel in the old Artifact version, you'll need to set a new one
   here (via the 🔒 button next to "Manage courses") — passwords didn't carry over since they're
   stored per-app.

## A note on testing

I built and syntax-checked this app, and ran it through an automated test suite that simulates the
Supabase connection (add a person, remove a person, set an admin password, verify the course
dashboard renders, and — new for v3.1 — change a person's position and confirm the start date stays
put, the position history logs correctly, and a shared course keeps its Passed status while a
new-only course starts fresh; new for v3.5 — switch the Progress dropdown through all three scopes
and confirm the People table's column header and each person's percentage change accordingly, and
that the Export Report still generates correctly under a non-default scope; new for v3.6 — every
status badge (Overdue, Due soon, On track, N/A, Never evaluated, Failed–retrain) computed correctly
against known dates, the dashboard tile and its click-to-filter behavior, assigning a method and
logging an evaluation from a person's page, the evaluation history log, editing a method's frequency
in "Manage test methods" and confirming it round-trips and immediately updates that method's status
on every assigned person, adding a custom method, and the admin password gate correctly routing to
"Manage test methods" vs. "Manage courses" depending on which button was clicked) — everything
passed, and I re-ran the full pre-v3.6 test suite afterward to confirm nothing already working (course
schedules, position changes, Export Report, Progress scope) regressed. However, this sandbox's network access doesn't
reach Supabase or GitHub directly, so I have not been able to load the page against your *real*
database over the internet. Please do a quick smoke test after you publish it: open the page,
confirm the 24 people and their Passed/Not Started course statuses look right, add a test person
and refresh the page to confirm it's still there, then delete the test person. Also worth trying
the new Change Position flow once on a test person before relying on it for a real rotation. For
v3.6, open "Manage test methods" and confirm all 179 methods and their frequencies look right, then
open a test person's page, assign a method, log an evaluation, refresh the page and confirm it's
still there.

## Everyday use

Nothing about how you use the tracker day-to-day changes — same dashboard, same course lists, same
"Manage courses" admin panel. The only difference is that every edit now saves straight to the
shared database instead of "publishing" a new version of the page, so there's no more save/share
button to think about — it just always reflects the latest data, for everyone.
