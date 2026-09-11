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
  (v3.21) version — see "Position changes / rotations", "Per-person Status", "Progress scope (new)",
  "Export Report", **"Test Methods — Competency & Re-evaluation Tracking (v3.6)"**, **"Re-evaluation
  tab, editable dates & Excel import (new, v3.7)"**, **"Test methods now scope to your current
  position, and Excel import now updates the Planner/Schedule tab too (v3.8)"**, **"Test-method
  relevance now uses your real curriculum data, Excel import now matches on either column, and the
  Flag/Methods columns are merged (v3.9)"**, **"Test-method relevance now also excludes
  Polyolefins-section methods entirely (v3.10)"**, **"Phase 3 (Continuing Plan) courses now
  compute overdue status correctly, and the admin panel guards against adding one with no due date
  (v3.11)"**, **"Removing a custom course now removes it everywhere it applies, and the
  Progress-basis choice now survives a reload (v3.12)"**, **"Course/document codes are now
  enforced unique, and test-method re-evaluation warnings are now truly Analyst-only (v3.13)"**,
  **"Non-Analyst positions now get a Test Methods completion-record tab too (v3.14)"**,
  **"All courses now get a completion-record tab too, for every position including Analysts
  (v3.15)"**, **"Courses and Test Methods are now one merged table, and a genuine duplication
  is now eliminated (v3.16)"**, **"Test Methods now show only what's actually in a position's
  own curriculum, and the tick/assign checkbox is gone (v3.17)"**, **"Methods you've already
  completed under a previous position now stay visible, just marked inactive (v3.18)"**,
  **"Excel import now matches document courses by their real Document No., not just the Lab-code
  (v3.19)"**, **"Manage courses" now has a plan-revision import and a per-row Edit button,
  including applies-to editing (v3.20)"**, and **"Plan-revision import no longer re-flags Trainer as
  changed on every re-import (v3.21)"** below for what's new.
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

## Re-evaluation tab, editable dates & Excel import (new, v3.7)

Three changes, all based on your feedback after v3.6 shipped — no database schema change, so there's
no new `migration_*.sql` file for this round.

**1. Re-evaluation tracking is now Analyst-only.** You clarified that CL-D-1000-0010 competency
re-evaluation only applies to the three Analyst roles (Gas / Oil / Utility) — not Section Manager,
Supervisor (SS), or Lead/Senior Engineer. Everything below (the tabs, the Re-evaluation panel, the
Excel import) only ever shows on an Analyst's own page; everyone else's page looks exactly like it
did before v3.6 — just their course schedule, no tabs.

**2. Each analyst's page is now two tabs, not one long page.** Previously "Test Methods —
Competency & Re-evaluation" was appended below the course schedule on every page, and the header
buttons (Export report / Manage courses / Manage test methods / 🔒 / the save indicator) showed on
every page including a person's own — redundant, since they're already on the main dashboard. Now:

- Those header buttons only show on the dashboard / admin screens. On an analyst's own page they're
  hidden — the page just shows their name/position/status fields, then the tabs.
- **"Planner / Schedule"** is the first tab and the default — this is the same course-schedule Gantt
  view as before, unchanged.
- **"Re-evaluation"** is the second tab — this is where the Test Methods panel now lives. Click it to
  see/edit test-method assignments and evaluations for that person; the schedule table isn't rendered
  while this tab is open (and vice versa), so switching tabs is instant.

**3. Completed date is now directly editable, and Next Due follows automatically.** In the
Re-evaluation tab's table, the "Last evaluated" column is now a date field you can click and change
directly — no need to open "Log eval." for a simple date correction. Editing it updates that
method's most recent evaluation record in place (creating a first, Pass-result record if the person
had no history for that method yet) and recomputes "Next due" as Completed date + the method's
re-evaluation frequency. If a Next Due date had previously come from an Excel import (see below)
rather than being computed, editing the Completed date by hand clears that and goes back to the
computed date — a manual edit always wins going forward.

**4. Import from Excel — one file, any number of people, from two entry points.** The parser reads
the same competency-evaluation export format you use for real training-report downloads — verified
directly against one of your actual exported files, not just a synthetic example:

- **Dashboard button:** a new **"Import test results (Excel)"** button sits in the main header
  (next to "Manage test methods"). Use this whenever a file covers more than one person — which is
  the normal case for a training-report export, since one file commonly bundles several people's
  records. It isn't behind the admin password, the same as logging an evaluation from a person's own
  page.
- **Per-person button:** the **"Import from Excel…"** button inside a person's Re-evaluation tab
  still works the same way — it's just not the only entry point anymore. Both buttons run the exact
  same parser and update **every** person the file matches, not only the person whose page happens
  to be open; use whichever is more convenient.
- It expects repeating blocks, one per person, each starting with a `Name:` cell followed by a
  course table with columns **No. / Course / Description / Complete Date / Re-Training Date**. The
  small "Competency" summary table (General/Functional rows) above each person's course table is
  recognized and skipped automatically — it has no method-row data in it. Name detection tolerates
  the merged-cell layout real exports use — where "Name:" and its value sit in separate merged
  ranges with a blank cell in between — by scanning forward past any blank cells rather than only
  checking the very next one.
- Name matching **ignores Vietnamese diacritics** on both sides (e.g. "Trần Thành Đạt" and
  "Nguyễn Quốc Thịnh" match roster entries stored as plain-ASCII "Tran Thanh Dat" / "Nguyen Quoc
  Thinh"), so it works whichever way a given export happens to spell a name.
- **The join key is the Description column**, not Course — it holds the CL-T-XXXX-XXXX Document No.
  that matches this tracker's test-method catalog directly. Rows for non-test-method courses (e.g.
  Description values starting HS-K-, CL-P-, CL-W-, IM-P-) are recognized as not matching that
  pattern and silently skipped, same as the Course column's `Lab-xx-xx-xxx` codes — exactly what you
  flagged as being mixed into the same export.
- **Dates are read as DD/MM/YY(YY)** — day-first, confirmed against your real file's date-typed
  cells. If a Complete Date is present, it updates that person+method's Completed date; if a
  Re-Training Date is also present in the same row, it's stored as that evaluation's explicit
  next-due date (overriding the frequency-based calculation) — this matters because your export's
  Re-Training Date is consistently one day before what `Complete Date + frequency` would compute
  (e.g. a Complete Date of 22/07/25 with a 1-year frequency computes to 22/07/26, but the file says
  21/07/26) — read as "valid through the day before the next anniversary." Importing preserves that
  exact date rather than silently overriding it with the computed one.
- After importing, a summary banner shows how many test-method records were updated and for how many
  people, plus any names in the file that didn't match anyone in the roster and any Document No.s
  that didn't match anything in the test-method catalog. A name landing in "not found" is expected
  and not necessarily a problem — as you noted, a real export can include people who've since
  resigned, rotated to another section, or been promoted out of the roster this tracker covers; it
  can also mean a spelling mismatch worth checking against "Manage test methods"/the People table.
- A row with a Document No. but no recognizable Complete Date, or that appears before any `Name:`
  cell has been seen, is skipped — nothing is guessed.

This all runs entirely in your browser (via a small library, SheetJS, loaded the same way as the
existing PowerPoint-export library) — the file never leaves your machine except to save the parsed
results to the database, same as any other edit in the tracker.

**A bug from the first version of this feature, found and fixed against your real export.** When
you tried the very first version of Excel import against one of your actual training-report
downloads, it reported 0 records updated and recognized no "Name:" rows at all. The cause: that
version only checked the cell immediately after a "Name:" label for the name value, but a real
export's "Name:" label and its value sit in separate merged cell ranges with a blank cell in
between — so the immediately-next cell was always empty and no name was ever picked up, anywhere in
the file. Fixed by scanning forward past blank cells (see above). Testing against your real file
after the fix also surfaced the diacritics issue described above, fixed the same round. Both fixes
were verified directly against the file you sent — it now correctly reports every person and every
test-method record it contains.

## Test methods now scope to your current position, and Excel import now updates the Planner/Schedule tab too (v3.8)

Two changes, both from the Ninh Minh Hai example you flagged (rotated Oil → Gas, but his page kept
warning about an Oil test method) plus your request to also update course status from an import, not
just test methods.

**1. A test method last evaluated under a previous position no longer counts as a warning.** If
someone has ever used "Change position" (i.e. they show a Position History), any assigned method
whose most recent evaluation happened *before* their current position's effective date was treated
as "from a previous position." **Superseded in v3.9 below** — this approach depended on Position
History being logged through "Change Position," and your real roster's long-tenured, already-rotated
people never went through that flow (their rotations only ever existed as free-text notes), so in
practice this fix never actually applied to anyone. See the v3.9 section for the real fix.

**2. Excel import now also updates the Planner/Schedule tab — for every position, not just
Analysts.** Your training-report export's **Course** column (e.g. `Lab-05-03-002`) turns out to be a
second, independent join key: it lines up directly with this tracker's own curriculum course codes
(confirmed against your real file — 99 of its 111 distinct Course-column values matched an existing
course outright). Previously only the Description column (the CL-T Document No., for test methods)
was used; now both are read from the same row:

- If the Course-column code matches a course in the matched person's **current** curriculum, that
  course is marked **Passed** on their Planner/Schedule tab, with its Completed date set from the
  same Complete Date cell — regardless of position, so this now also updates Section Manager,
  Supervisor, and Lead/Senior/QC Engineer pages, which don't have a Re-evaluation tab at all.
- Matching is scoped to their current position's curriculum only — a course code that only exists in
  a position someone has since rotated out of correctly falls through to "not found" rather than
  being silently applied to the wrong curriculum.
- The import summary banner reports both halves separately: how many test-method records were
  updated (and for how many people), and how many Planner/Schedule courses were marked Passed (and
  for how many people) — plus, alongside the existing unmatched-name/unmatched-Document-No. lines, a
  new line for course codes that didn't match anyone's current curriculum. A course code not matching
  is normal and expected for rows that are company-wide training (HR, general safety, etc.) this
  tracker was never meant to track — it isn't an error.
- Both entry points (the dashboard's "Import test results (Excel)" button and the per-person "Import
  from Excel…" button on an Analyst's Re-evaluation tab) do both halves of the update from the same
  file in one pass. **Extended further in v3.9 below** — a row can now update a Planner/Schedule
  course via the Description (CL-T code) column too, not just the Course column, which is what fixes
  an OJT course that never had a matching Course-column entry.

## Test-method relevance now uses your real curriculum data, Excel import now matches on either column, and the Flag/Methods columns are merged (v3.9)

Three changes, all from your latest feedback after v3.8 shipped — again, no database schema change.

**1. The Oil/Poly warnings for Ninh Minh Hai, Nguyen Thanh Tuan, and Nguyen Dinh Vinh are now
actually fixed.** You were right that they were still showing — the v3.8 fix above genuinely never
worked for any of your real people, because it only kicked in for someone with a logged Position
History (i.e. run through "Change Position" at least once), and none of your long-tenured, already-
rotated Gas analysts have one — their rotations only exist as notes. I confirmed this directly
against your live database rather than guessing.

The real fix doesn't need Position History at all. It turns out your own curriculum data already
contains an authoritative answer to "which of the 179 CL-D-1000-0010 methods does this position
actually need" — every "Test Method (OJT)" course in each position's onboarding curriculum embeds
the exact CL-T Document No. it trains for. Checked directly: Gas's 37 OJT courses are *exactly* its
CL-T-2000-xxxx methods, Oil's 26 are *exactly* CL-T-3000-xxxx, and Utility's 29 are *exactly*
CL-T-4000-xxxx — no overlap, no guessing, no admin setup needed. (This also corrects something I got
wrong in the v3.8 notes above — I'd concluded no such mapping existed because a naive
numeric-prefix grouping looked contradictory; the real, curriculum-derived mapping doesn't have that
problem, and in fact explains the same evidence correctly: a Gas analyst evaluated on Oil-prefixed
methods is exactly what you'd expect from someone who used to be an Oil analyst.)

So now, for **any** Gas/Oil/Utility analyst, an assigned method that belongs to a *different*
position's curriculum — regardless of whether they ever logged a position change — is labeled **"not
required for current position"** (naming which position it belongs to) wherever it's shown, and is
excluded from the dashboard's "Test methods needing attention" tile, the People table's combined
Flag, and the "needing attention" filter. It still shows on the person's own Re-evaluation tab with
its true status, and a **"Not required for current position"** option in that tab's filter isolates
just those, so nothing is hidden — you can still review and untick them if truly no longer relevant.
Methods outside all three curricula (mostly the 5000/6000-series Polymer/Film & Mechanical tests,
which aren't tied to any position's onboarding curriculum) are unaffected and always count normally,
same as before.

**2. Excel import now also matches Planner/Schedule courses through the Description column, not
just Course.** The v3.8 fix relied on the file's Course column (`Lab-xx-xx-xxx`) lining up with a
curriculum course code. But a "Test Method (OJT)" course's own topic already embeds the same CL-T
Document No. used to update the Re-evaluation record — so now that same match also finds and updates
the matching Planner/Schedule course, even on a row where the Course-column value is blank, wasn't
recognized, or wasn't filled in on your export. This is what fixes the case you screenshotted
(`CL-T-4000-0006`, stuck at "Not Started" / "OVERDUE" on the Planner/Schedule tab despite the
Re-evaluation tab already showing it imported). If a row's Course-column code and its Description
CL-T code both resolve to the same curriculum course, it's only counted and updated once, not twice.
As before, a row with no completion date at all is left alone — a course that's still genuinely due
is never touched by a "nothing to import here" row.

**3. The People table's Flag and Methods columns are now one combined column.** You asked whether
"Complete" and "On track" even mean anything different — they don't; both simply mean "nothing needs
attention," so they're now the same OK state (still showing "Complete" only once every probation
course is actually done, "On track" otherwise). A real warning from either domain — overdue courses
or overdue/failed-retrain test methods — now always wins and is shown together, worst-first, with
text naming which domain(s) it's coming from (e.g. "2 courses + 1 method overdue") instead of two
separate, sometimes-contradictory-looking chips. A failed-and-needing-retrain method always takes
priority over a merely-overdue course, since a failed evaluation is the more serious condition. The
Flag filter dropdown in the People table's filter bar now offers the same three merged buckets:
**Overdue / failed–retrain**, **Due soon / never evaluated**, and **On track / complete**.

## Test-method relevance now also excludes Polyolefins-section methods entirely (v3.10)

You reported that Nguyen Dinh Vinh and Van Minh Tien were still showing overdue warnings after v3.9,
this time for `CL-T-5000-xxx`/`CL-T-6000-xxx` methods — which you confirmed are Polyolefins-section
methods, not Olefins ones, and don't belong to their current positions (Gas and Oil analyst).

You were right, and the gap was narrower than v3.9's fix covered. CL-D-1000-0010 is a lab-wide list
spanning multiple sections, not just Olefins — and v3.9's curriculum check only excluded a method when
it belonged to a *different Olefins position's* curriculum (e.g. an Oil method on a Gas person). A
method that isn't tied to *any* of the 6 Olefins curricula fell back to "no curriculum signal, so
count it as relevant" — which was the right call for methods genuinely missing curriculum coverage,
but wrong for methods that are simply out of scope for the Olefins section entirely, like the
5000/6000-series ones. Checked directly against your curriculum data: zero of the 179 methods in the
5000/6000 range are referenced by any of the 6 Olefins curricula, confirming these are Polyolefins
(or other-section) methods with no Olefins relevance at all, exactly as you said.

Fixed by dropping that fallback: a method now reads as relevant only when it's part of the person's
own current position's curriculum — nothing else falls back to "count it anyway." A method excluded
this way still shows on the person's own Re-evaluation tab with its true status, now labeled "not
required for current position (not an Olefins-section method — belongs to another section, e.g.
Polyolefins)" when it isn't part of any Olefins curriculum at all (vs. naming the specific Olefins
position it belongs to, when it is).

## Phase 3 (Continuing Plan) courses now compute overdue status correctly, and the admin panel guards against adding one with no due date (v3.11)

You reported: you added a new course, `HS-K-4000-001`, and applied it to every position. It correctly
appeared on each person's own Planner/Schedule tab as "Not Started" — but on the main dashboard/People
table, it never warned anyone as overdue. You asked me to check it and put a preventive measure in
place for future course additions.

There were two separate things going on, and I want to be upfront about which one is a bug and which
one is working as designed:

**Working as designed:** the Progress-basis dropdown at the top of the dashboard defaults to
"Probation progress (Ph.1+2)" — Phase 1 and 2 only. Phase 3 ("Continuing Plan") courses — the ones
paced over the ~6 months after probation ends — have never counted toward the Progress %, the
People-table Flag column, or the dashboard tiles while that's selected. This isn't specific to your
new course; it's true of every existing Phase 3 course in every curriculum, and always has been. To
see Phase 3 courses (including this one) reflected in those figures, switch the dropdown to "Full
progress (all phases)".

**An actual bug, which I fixed:** even after switching to "Full progress (all phases)", Phase 3
courses still wouldn't compute a correct overdue date on the dashboard/People table. Your own
Planner/Schedule tab has always paced Phase 3 courses correctly — spreading them across ~6 months
post-probation based on their "Bucket" label (e.g. "Month 4-6"). But the dashboard-level calculation
(the one behind Progress %, the Flag column, and the Export Report) used a different, older code path
that read each course's raw `week` field instead — and every Phase 3 course, old or new, always stores
`0` there, because it was never meant to be read directly. That produced a meaningless date (always a
week before someone's start date) rather than the real bucket-based pacing, so Phase 3 courses could
never show up correctly there even under "Full progress" scope. I confirmed this against the exact
data behind your new course (read directly from the database: `postLabel: "Month 3 - 4"`, applied to
all 6 positions, effective 2026-01-01) — fixed by making the dashboard-level calculation use the same
bucket-pacing logic your Planner/Schedule tab already uses, so both now agree.

**Preventive action for future course additions**, in the "Manage courses" admin panel's "Add course"
form:

- The **Bucket** field (only relevant for Phase 3 courses) now shows the curriculum's existing bucket
  labels as suggestions as you type, so you can join an existing bucket (e.g. "Month 4-6") instead of
  accidentally typing a new, slightly different label (like "Month 3 - 4" vs. "Month 4-6") that splits
  the 6-month pacing window into an extra slice for everyone in that curriculum.
- **The Bucket field is now required** for a Phase 3 course. Previously it could be left blank, which
  silently meant that course would never be assigned a due date at all — not "always overdue," but
  permanently "unscheduled," with no way to notice from the dashboard. The form now blocks saving
  until it's filled in.
- The Bucket field's tooltip, and the Progress-basis dropdown's tooltip, both now spell out that Phase
  3 courses only count toward the dashboard/People-table overdue figures under "Full progress (all
  phases)" — not the default "Probation progress (Ph.1+2)" — so this doesn't catch you by surprise
  again.

Your existing `HS-K-4000-001` course itself needed no data changes — its stored bucket label ("Month
3 - 4") is valid, just not one shared with any existing bucket in the base curricula, so it now paces
as its own ~6-8 week slice within the 6-month window. Once you switch the dashboard to "Full progress
(all phases)", it will show correctly for anyone whose position started long enough ago for that slice
to have passed.

## Removing a custom course now removes it everywhere it applies, and the Progress-basis choice now survives a reload (v3.12)

You reported two follow-ups on `HS-K-4000-001`:

1. Even switched to "Full progress (all phases)", the Flag column still wasn't warning overdue.
2. Deleting the course in "Manage courses" only removed it from Luu Van Khue's (Section Manager) page —
   it stayed on everyone else's, and after a few attempts to fix it, the course started showing up
   *multiple times* on other people's own Planner/Schedule pages.

**On (1), the real cause turned out to be the Progress-basis dropdown resetting on every reload —
fixed.** Your screenshot's own column header ("PROGRESS (PROBATION (PH.1+2))") confirmed the page was
on the default scope, not "Full progress" — even though you'd switched it before. The dropdown never
remembered your choice; it silently reset to "Probation (Ph.1+2)" every time the page reloaded, which
is very easy to trigger without noticing (a refresh, reopening the tab, a Render redeploy). **It now
remembers your choice in the browser** (saved locally, so it'll need to be set once per browser/device
you use), so switching it once should stick from now on. To see this course's overdue warning on the
People table: at the top of the dashboard, find the dropdown currently reading **"Probation progress
(Ph.1+2)"** and change it to **"Full progress (all phases)"** — the column header will change to match,
and the Flag column will then show the course as overdue for anyone who's past its due date. (Your
second screenshot already showed this course correctly marked "OVERDUE" on the person's own
Planner/Schedule tab — that calculation was already right; only the dashboard/People-table view needed
the scope switched, and now needs it switched only once.)

**On (2), the actual bug — fixed:** the "Remove" button on a custom course only ever deleted it from
whichever curriculum tab was open when you clicked it (a pre-existing design from early on, meant for a
narrower case). Since `HS-K-4000-001` was added to all 6 positions in one "Applies to" action, deleting
it from the SM tab only cleared SM, leaving it live on SS/Eng/Gas/Oil/Utility — and each retry to fix
the missing SM assignment created another near-duplicate entry instead, which is why it started showing
up 2-3 times on some people's own pages (your second screenshot).

- **Remove now deletes the course from every curriculum it applies to, in one confirmed click** —
  matching the fact that it was added everywhere in one action.
- A new, separately-labeled **"Only remove from `<curriculum>`"** button appears next to Remove
  whenever a custom course applies to more than one curriculum, for the rarer case where you want to
  pare a course down to fewer curricula without deleting it everywhere.

**Data cleanup — done.** The three accumulated database entries for `HS-K-4000-001` have been
consolidated into one (I confirmed first, via a read-only check, that only the original entry carried
real recorded "Passed" statuses — the other two were still "Not Started" everywhere, so nothing was
lost). That one entry now correctly covers all 6 positions, including SM. You shouldn't see the
duplicate rows on anyone's Planner/Schedule tab any more — a hard refresh will confirm it.

## Course/document codes are now enforced unique, and test-method re-evaluation warnings are now truly Analyst-only (v3.13)

Three more follow-ups:

**1. Course and document codes are now enforced unique.** You pointed out that a training code (e.g.
`Lab-01-01-001`) and a Document/Test Method No. (e.g. `CL-T-2000-0001`, `CL-M-1000-0001`) should never
be reused for two different things — exactly the kind of mistake that produced the three near-duplicate
`HS-K-4000-001` entries fixed in v3.12. **"+ Add supplemental course" now checks both** the code you
type and the Document/Test Method No. embedded at the start of the Topic you type, against every course
already in the base curriculum and every custom course already added. If either one is already in use,
the save is blocked with an inline message naming the exact code and pointing you at the right fix: if
the course applies to another position too, cancel and check every position it belongs to in the
"Applies to" list in that same "Add course" action, rather than adding it a second time. (The v3.12 fix
already means Remove now cleans up every position in one click, so if you ever do need to redo an entry,
deleting and re-adding it correctly is safe.) The same case-insensitive uniqueness check was also added
to "+ Add custom method" in Manage Test Methods, which previously only checked for an exact-case match.

**2. Test-method re-evaluation warnings are now truly Analyst-only.** As agreed, re-evaluation tracking
(Doc. CL-D-1000-0010) only applies to the 3 Analyst positions (Gas/Oil/Utility) — QC Section Manager, QC
Supervisor (SS), QC Lead Engineer, and QC Senior Engineer never carry this requirement. Your screenshot
showed several of these higher-level people still triggering a "N methods overdue" warning on the Flag
column, even though their own Re-evaluation tab was correctly hidden. The root cause: the Flag column
and the dashboard's "Test methods needing attention" tile computed method status straight from each
person's raw records, without checking position — while historical Excel imports had, for some people in
these roles, quietly created method records that a stray import row happened to match against. **The
Flag column, the dashboard tile, and the "needing attention" filter now all correctly ignore test-method
data entirely for non-Analyst positions.** I did not delete any of the underlying historical records —
they're simply no longer counted for anyone outside Gas/Oil/Utility, so nothing needed to change in the
database itself. A future Excel import will also no longer write new re-evaluation records for a
non-Analyst person matched in the file; the import summary banner will say how many rows were skipped
for that reason (their Planner/Schedule course entries, which aren't Analyst-only, are still updated as
before).

**3. Target dates now show the end of the scheduled week, not the start.** You flagged this from a new
Gas analyst's page (Pham Vu Thanh, started 07 Sep 2026): the Week 1 course showed a target date of
07 Sep 2026 — identical to the Start Date — when it should read as the deadline by which that week's
course is due, i.e. one week later. The formula previously computed a course's target date as `Start
Date + (Week − 1) × 7 days`, which gives the date the week *begins* rather than the date it *ends* — so
every Week 1 course always showed the start date verbatim, Week 2 showed start+7, and so on, one week
earlier than you'd expect. **It's now `Start Date + Week × 7 days`** — Week 1 → start+7 days, Week 2 →
start+14 days, etc. — confirmed with you directly. This applies the same way to Phase 3's approximate
week-based pacing, so every phase now uses the same "end of the scheduled week" convention. This does
shift every course's target date one week later than before (and, correspondingly, the point at which
an unfinished course is flagged Overdue) — nothing else about the schedule changed: which week a course
falls in, its status, and the Gantt bar it's shown on are unaffected. The hint text on each person's page
("target date = that date + Week × 7 days (end of that week)") reflects this directly.

## Non-Analyst positions now get a Test Methods completion-record tab too (v3.14)

You asked for this directly, with two screenshots: *"only analysts have the tab Re-evaluation. Now I
want other positions have also, the purpose is not for tracking the re-evaluation date... I just wanted
to track that when is the last time/when the time they complete the course. Similarly to analysts',
this can be edited either manually or by importing data from such excel files."*

**Every position now has a second tab on their own page**, not just Gas/Oil/Utility Analysts. What's on
that tab depends on the position:

- **Analysts (Gas/Oil/Utility)** — unchanged: the tab is still labeled **"Re-evaluation"**, and shows
  the full re-evaluation panel per CL-D-1000-0010 (Freq., Next due, Status, Overdue/Due soon/etc.).
- **Everyone else (QC Section Manager, QC Supervisor, QC Lead Engineer, QC Senior Engineer)** — the tab
  is now labeled **"Test Methods"**, and opens a plainer panel titled **"Test Methods — Completion
  Record."** It's the same 179-method catalog, but with the re-evaluation-cadence columns removed —
  just Doc No., Test Method Name, an editable **Last completed** date, and Result. There's no Freq.,
  Next due, or Status column, because none of that applies to these positions.

**This is explicitly a record, not a requirement.** As you asked me to keep in mind: these positions
don't need re-evaluation, so nothing logged here ever creates a warning. The panel's own meta line says
so directly ("a completion log only... nothing here counts toward the Flag column or dashboard"), and I
re-confirmed with a dedicated test that recording a method for a non-Analyst — even backdating it so it
would look "overdue" if the re-evaluation rule applied — still leaves their Flag column clean and the
dashboard's "Test methods needing attention" tile unaffected. The Analyst-only gating from v3.13 is
untouched; this feature only changes what shows up on non-Analyst pages, not what counts toward anyone's
warnings.

**Editing works the same way as the Analyst tab:**

- **Manually** — tick a method to record it (or use "All 179 methods" / "Not yet recorded" in the
  filter to find it), then type or edit the Last completed date directly, the same inline-edit pattern
  as the Analyst Re-evaluation tab.
- **By Excel import** — the same "Import from Excel" button and file format Analysts use. Previously
  (as of v3.13), a person matched in an import file who held one of these non-Analyst positions had
  their test-method rows silently skipped, with the import summary reporting how many rows were skipped
  and why. **That skip is now retired** — import rows for non-Analyst people are written again, exactly
  like Analysts, and the summary banner no longer mentions skipping anyone for this reason. If you have
  an import file that includes Section Manager/Supervisor/Lead/Senior Engineer completion records, this
  will now capture them.

## All courses now get a completion-record tab too, for every position including Analysts (v3.15)

One round after v3.14, you asked to go further: *"Only test methods are listed on such a new tab, now
I want all courses appear there now, for all positions (including analysts), the purpose is also to
track the complete date."*

**That same second tab now shows a brand-new "Courses — Completion Record" table, above the Test
Methods table, for every position — including the 3 Analysts, who didn't get anything new from v3.14.**
It lists every course in that person's curriculum (the same ~90-180 courses you'd see on their
Planner/Schedule tab, grouped by phase the same way), with just four columns: Code, Course, Status, and
an editable **Completed date**.

Two things worth knowing about how it works, both confirmed with you before building:

**1. It's its own table, not merged into Test Methods.** Courses and test methods stay as two separate
lists on the tab — Courses first, Test Methods below it — rather than one combined table, so each stays
easy to scan on its own.

**2. The Completed date here is the exact same record as the Status dropdown on Planner/Schedule — not
a second, separate field.** Enter a date and the course is marked Passed as of that date (matching what
already happens when you switch the Status dropdown to Passed); clear the date and it reverts to Not
Started. Edit it from either tab and the other one shows the same result immediately — there's no way
for these two views to disagree about whether a course is done. This also means it's a genuine
improvement over the old flow: previously, marking a course Passed via the Status dropdown always
stamped *today's* date automatically, with no way to enter a real, possibly earlier completion date
directly — this tab is the first place you can do that.

A search box and a "Completed only / All / Not yet completed" filter (default: All) help narrow a long
list down, the same pattern as the Test Methods table next to it.

## Courses and Test Methods are now one merged table, and a genuine duplication is now eliminated (v3.16)

After seeing v3.15 live, you pushed back straight away: *"So inconsistent if you separate into 2 areas
like this. Even found the duplication for the test methods between top area and bottom area. I want all
in the same area at the bottom one."* You'd spotted something real — some of a position's curriculum
courses are literally the same document as a catalog test method (for example, a Gas analyst's course
"CL-T-2000-0001_Hydrocarbon Impurities in Ethylene Product by GC" *is* CL-D-1000-0010's method
CL-T-2000-0001), so v3.15's two tables were showing that one thing twice, under two separate,
independently-editable fields that could quietly disagree.

**v3.16 undoes the v3.15 split and fixes the underlying duplication, not just the layout:**

**1. One panel, one table.** The second tab (now titled "Courses & Test Methods — Competency &
Re-evaluation" for Analysts, "Courses & Test Methods — Completion Record" for everyone else) is back to
a single table, with two labeled sections inside it — "Courses (this position's curriculum)" then "Test
Methods (CL-D-1000-0010 catalog)" — sharing one search box, one status filter, and one Import button.

**2. A course that IS a catalog test method now shows once, not twice.** Whenever a curriculum's "Test
Method (OJT)" course embeds the exact Document No. of a CL-D-1000-0010 catalog entry, it's no longer
listed as its own row in the Courses section — it appears only as that one Test Methods row. A course
that's genuinely just a document/procedure (not a catalog method) still gets its own row exactly as
before. Nothing is hidden or dropped — it's the same underlying record, shown once instead of twice.

**3. Editing that merged row now keeps both sides in sync automatically.** Previously, only an Excel
import updated a matching Planner/Schedule course when you logged a test-method result manually; a
manual edit to a method's date on this tab left the matching course stale. Now, entering a Completed
date on a merged method row also marks the matching Planner/Schedule course Passed with that same date
— so a manual edit and an Excel import behave the same way, and the two tabs can no longer disagree.

**4. The default filter now shows everything.** The status filter defaults to "All courses & N methods"
(previously "Assigned/Recorded only"), so opening the tab shows the full picture first, matching your
"I want all in the same area" request; the Overdue/Failed-retrain/Never-evaluated/Due-soon/Not-required
filters are still there for Analysts, now labeled "(test methods only)" since they don't apply to plain
courses.

A plain, non-method-linked course row still works exactly as it did in v3.15 — editable Completed date,
linked to the Planner/Schedule Status dropdown, same as before.

## Test Methods now show only what's actually in a position's own curriculum, and the tick/assign checkbox is gone (v3.17)

**Note: point 2 below was loosened one round later — see "Methods you've already completed under a
previous position now stay visible, just marked inactive (v3.18)" further down.** This section is kept
as-written for history.

After seeing v3.16 live, you sent a screenshot of a Shift Supervisor's page with a red box around
CL-T-6000-0027 through CL-T-6000-0031 — Polyolefins-section methods (Seal Strength, Spiral flow, and
similar), all inactive, all sitting unticked in the Test Methods section — and wrote: *"Why these
courses (these test methods in particular) is in the profile of Olefins QC Supervisor (as they're test
methods of Polyolefins), and many other positions as well they're mis-functioning, I understand you
might let me use tick function to select and unselect but I don't want it. I just want courses which
actually belong to the functional training plan of each position appear in their profile
accordingly."*

That was a fair read of what v3.16 (and everything before it) actually did: the Test Methods section
always listed the full 179-method CL-D-1000-0010 catalog for every position, with a checkbox to
manually tick a method "in" or "out." Nothing stopped a method with zero connection to a position —
like a Polyolefins method on an Olefins Supervisor's page — from sitting there, tickable, forever.

**v3.17 removes that catalog-wide list and the tick function entirely. A position's Test Methods
section now shows only the methods that are genuinely part of that position's own curriculum** — the
same real CL-D-1000-0010 mapping already used since v3.9/v3.10 to exclude irrelevant methods from
overdue warnings, now used to decide what's shown at all, for every position, not just the three
Analyst ones:

**1. No more manual ticking, anywhere.** The checkbox column is gone from every Test Methods row, for
every position. A method's presence in the list is no longer something anyone selects — it's
automatic, driven purely by whether that position's curriculum actually includes it, exactly the way
Courses already worked.

**2. A method outside the position's curriculum can no longer appear at all.** Not unticked, not
greyed out — simply not in the list. The Polyolefins methods from your screenshot (and their
equivalents on every other position) are gone from every profile except the Polyolefins positions
that actually own them.

**3. "Log eval." is available immediately.** Since there's no more separate "assign" step, every
method listed for a position can have an evaluation logged straight away.

**4. The meta line, filter dropdown, and counts all now reflect the position's real curriculum size**
instead of the full 179-method catalog — e.g. "92 test methods in this position's curriculum" for a
Shift Supervisor, not "179."

**Nothing was deleted from the database.** If a position had a stray method record from before this
fix — assigned, with history, the way CL-T-6000-0027 was on the Shift Supervisor in your screenshot —
that record is untouched in the database; it simply doesn't render anywhere anymore. If a genuine
process reason ever comes up to look at that old record again, it's still there.

## Methods you've already completed under a previous position now stay visible, just marked inactive (v3.18)

You came back after v3.17 with: *"Ok, that's better, but you deleted/removed way too much, or I forgot
telling you. For courses/test methods that do not belong to current position but if they were complete
previously (like before rotating or promoting or something else), please still keep them in the tab
with the sign/signal/mark that they're not active anymore (just like you did previously I guess), and
no remind for the evaluation for them (as said before)."*

Fair correction — v3.17 hid every method outside a position's current curriculum, full stop, which
also hid the legitimate case: a method you actually completed before a rotation or promotion, still a
real record worth keeping visible for reference, just not something anyone needs reminding about
anymore.

**v3.18 draws the line where you asked: a method now shows on the tab whenever either (a) it's part of
the position's own curriculum, or (b) this person already has a real record for it — assigned, with
history — even if it's from a different position's curriculum entirely.** A catalog method that's
*neither* in the curriculum *nor* ever recorded for this person still never appears — that part of
v3.17 (the original clutter complaint) is unchanged.

**1. A method with real history is marked, not hidden.** Its Code/Doc No. cell now carries a small
"(not required for current position)" tag (hover it for detail — it'll name which position's curriculum
it actually belongs to, or say it isn't part of any Olefins curriculum at all, e.g. a Polyolefins
method). The row itself renders slightly dimmed, the same visual treatment an inactive catalog method
already gets.

**2. No reminder, anywhere, for these.** The Next Due and Status columns read "—" and "Not required"
instead of a real due date or an Overdue/Due-soon chip — even if the underlying evaluation date is
genuinely years old. It also can't be pulled into view under the Overdue/Failed–retrain/Never
evaluated/Due soon filters, and it never counts toward the panel's own overdue/retrain figures, the
People-table Flag column, or the dashboard's "Test methods needing attention" tile — all of that was
already true before v3.18 (since v3.9/v3.10), this round only restores the *visibility* half.

**3. A dedicated filter finds them.** "Not required for current position (N)" is back in the status
filter dropdown, for every position — pick it to see exactly the methods that fall into this "kept for
the record, not required anymore" bucket, without paging through everything else.

**4. The meta line notes the count** — e.g. "…3 not required for current position (kept on record, no
reminder)" — only when there's at least one, so a person with a clean curriculum-only list sees no
change at all.

This applies to Courses too, in principle, but courses don't currently have a comparable "outside the
curriculum" concept the way test methods do (a course row only ever shows if it's in the position's own
curriculum list to begin with) — so this round's change is scoped to Test Methods, which is where the
gap actually was.

## Excel import now matches document courses by their real Document No., not just the Lab-code (v3.19)

You reported: *"The Course code (in this example Lab-04-03-003) is not correct for some actual courses
(for example CL-P-1000-0023 here respectively and others...), that's why the complete date is leave not
updated? Maybe something wrong when reading the file imported from excel? Check carefully for all and
fix."*

You were right, and it's a real bug in the Excel import, not a data-entry mistake on either side.
Confirmed directly against your files: the master curriculum plan document (which this app's course
list is built from) genuinely says `Lab-04-03-003` for `CL-P-1000-0023` — but the real HR/LIMS
training-report export you attached uses `Lab-04-03-001` for that exact same course. Two different
systems, two different Lab-code numbers, same real course. The import only ever matched a document-type
course (Chemicals/Glassware/Spare-parts-style courses — anything that isn't a Test Method (OJT)) by its
Course-column Lab-code, so whenever the two systems' Lab-codes disagreed, the row was silently skipped
and the Completed date on the Planner/Schedule tab never got touched — no error, no warning, it just
quietly didn't happen.

**The fix generalizes something this app already does correctly for test methods, since v3.9: match by
Document No. instead of Lab-code.** A course's own topic already carries its real Document No. at the
front (that's what shows in the course name on screen) — `CL-P-1000-0023`, `CL-W-1000-99-0010`, etc. —
and a real export's Description column carries that same Document No. by itself. Matching on that
sidesteps the Lab-code disagreement entirely, because the Document No. doesn't have the numbering-drift
problem the Lab-code does.

**1. Document-No. matching now covers every document course type**, not just CL-T test methods —
CL-P, CL-M, CL-W, CL-D and HS-K courses (Chemicals, Glassware, Spare parts, Gas/Oil/Utility-owned
document courses, etc.) are all covered now. This was the main fix, and it's the one that resolves the
`CL-P-1000-0023` case you flagged directly.

**2. The Course-column Lab-code match is more forgiving now too**, as a second, belt-and-suspenders
improvement: it used to require the Lab-code to be exactly digit-for-digit identical, including leading
zeros (`Lab-01-03-012`), and a real export using fewer digits (`Lab-01-03-12`) wasn't even recognized as
a course-code cell at all — the whole row was skipped before the matching logic ever ran. It now
tolerates that kind of digit-width difference.

**3. A row that matches via Document No. no longer shows a confusing "unmatched" warning** just because
its Lab-code alone didn't line up — the import summary only flags a code as unmatched when nothing on
that row matched through any path.

**What this doesn't change:** the Re-evaluation record for test methods themselves (the CL-T
competency/evaluation history) was never affected by this bug — that path already matched correctly.
This fix is specifically about the Planner/Schedule tab's Completed date for document-type courses.

**Since the underlying cause was genuine Lab-code divergence between two source systems, not a typo on
either side, it's worth re-running your last few Excel imports** (the same files, no changes needed) so
any Completed dates that were silently missed the first time get picked up now.

## "Manage courses" now has a plan-revision import and a per-row Edit button, including applies-to editing (v3.20)

You asked for two things on the "Manage courses" tab: *"There should be a function of importing data
from excel file, where I can import data from the Functional Training Plan CL-D-1000-0001 which I
have updated you from the beginning. This is to update when there is a new revision of
CL-D-1000-0001 in which there are changes (supplement/ position level application/ obsolete...) in
courses are up-to-date... You're still building the plan (P1, P2, P3..) automatically based on this
as previously right? At each course's row, there would be a EDIT button, where I can edit manually
the course. In addition to the info being shown, there would be the edit function for the position
level would be applied after editing."*

**1. Import a new revision of CL-D-1000-0001 and review it before anything changes.** A new **"Import
plan revision (CL-D-1000-0001)"** button sits in the "Manage courses" toolbar. Pick the updated plan
workbook and it reads the SM / SS / ENG / Gas Analyst / Oil Analyst / Utility Analyst sheets (the
same ones the app was originally built from — DM, ENG. and TECH-Day PCL. are out of this app's scope
and are skipped, not misapplied) and compares every row, by its real Document No. (not the Lab-code —
same reasoning as the v3.19 fix above), against what's currently on record for each curriculum:

- **New courses** ("supplement") — shown with their Phase auto-classified exactly the way the
  original plan document was: a `(*)`-suffixed Lab-code is Phase 2 (critical), a fixed set of
  universal Document Nos. is Phase 1 (plus three Gas-specific ones that are Phase 1 only within the
  Gas curriculum), and everything else defaults to Phase 3 — matching how you'd previously told me to
  classify them by hand. You can adjust the Phase and Week/Bucket for any new course right on the
  review screen before applying, the same fields you'd set on "Add course."
- **Changed courses** — a topic, hours, trainer, or evaluation-method difference from what's on
  record is shown as a plain diff. **A Lab-code difference is shown too, but for information only —
  it is never applied automatically.** Code is the one field this app has always treated as a fixed
  identifier (it's what course edits are filed under internally), so renaming it automatically risks
  silently losing track of a course's history; if a Lab-code genuinely needs correcting, that's a
  manual step for now (see the Edit panel below — Code isn't editable there either, on purpose).
- **Possibly obsolete courses** ("obsolete") — anything currently on record that the new file no
  longer lists is offered as **Deactivate**, per what you asked for: kept on record with full history,
  just marked inactive, exactly like removing a course has always worked in this app. Nothing is ever
  hard-deleted by an import.
- **Nothing is saved until you click Apply.** Every row has its own checkbox (all checked by default)
  so you can exclude anything the automatic read got wrong, and the whole batch shares one
  effective-date + scope choice — the same "apply to everyone now" vs. "newcomers only" control every
  other course edit in this app already uses.
- A new course that shows up as "supplement" for more than one position in the same import (a course
  taught to several roles at once) is added once, with every applicable position's box already
  checked — not as several near-duplicate entries.

**2. Every course row now has an Edit button**, next to the existing Remove/Deactivate action. It
opens a small panel with the fields that weren't editable inline before — Trainer and Evaluation
method — plus, per your fourth request, **which curricula this course applies to.** Each of the 6
positions gets its own checkbox with its own Phase and Week/Bucket right there: tick a curriculum the
course doesn't currently belong to and it extends there (auto-filling that curriculum's Phase/Week
from the course's own current values, so ticking alone is enough); untick one it does belong to and
it's dropped from just that curriculum, leaving it untouched everywhere else. Like every other course
edit, this stages into the same effective-date + scope "Apply" bar rather than saving immediately —
you can open the Edit panel, make changes across several courses, and apply them together. Code stays
read-only here too, for the same reason it's informational-only in the plan-revision review above.

Both features build entirely on the dated/scoped course-revision mechanism this app already had (the
same one behind every inline course edit since early on) — nothing new to migrate, and no schema
change, so there's no new `migration_*.sql` file for this round.

## Plan-revision import no longer re-flags Trainer as changed on every re-import (v3.21)

Right after trying v3.20's plan-revision import, you reported: *"Just 1 thing remains for this import
function: I changed the Trainer column (column G in the excel file), first time it appears on the
confirmation session to ask if I want to change or not, this was totally ok, but times after, I
uploaded other file, this G column stays unchanged but it still asked me for the confirmation like
this? More info: this info from column G currently has no role in the tracker, maybe in many cases,
the same training course has different trainer for each position, so it's get confusing?"*

You'd correctly spotted a real bug, and your own explanation of it is exactly right. **Trainer is
stored as one shared value per course code, not one value per curriculum** — the same as Topic,
Hours, and Evaluation method have always worked in this app (a course shared across positions, like
`CL-M-1000-0001`, has always been "one record" everywhere it's used). But your source plan document
can legitimately list a *different* trainer name on each position's own sheet for that same course.
So the first import you did picked up whichever curriculum's sheet happened to apply last and stored
that as the one shared trainer value — which then permanently disagreed with every *other*
curriculum's own sheet, so literally any later import (even the exact same file, unchanged) kept
finding a "difference" for that course's trainer, on and on, for a value that never actually needed
fixing.

**Trainer is no longer compared during plan-revision import at all.** The review screen's "Changed"
section now only ever flags a genuine Topic, Hours, or Evaluation-method difference (plus the
informational-only Lab-code note from v3.20) — a course that differs *only* in Trainer no longer shows
up as changed, and won't keep re-appearing on every future import either. This matches what you said:
since Trainer plays no role anywhere else in the tracker's logic (no scheduling, no warning depends on
it), it isn't worth a confirmation prompt that can't actually be satisfied consistently across
curricula. Trainer is untouched everywhere else — still shown and still hand-editable per course via
each row's Edit panel (v3.20) for anyone who wants one recorded there; this change only affects what
the plan-revision import compares and applies.

## Test Methods — Competency & Re-evaluation Tracking (v3.6)

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
- A new **"Test Methods — Competency & Re-evaluation"** panel, in the **Re-evaluation tab** on each
  Analyst's own page (see "Re-evaluation tab, editable dates & Excel import" below — as of v3.7 this
  only shows for the three Analyst positions, not Section Manager/Supervisor/Lead/Senior Engineer) —
  tick which of the 179 methods they're expected to be competent in (search/filter the full list, or
  view "Assigned only"), click **Log eval.** to record a date/type/result/evaluator/notes for any
  assigned method, edit the Completed date directly for a quick correction, or click **History** to
  see every past evaluation for that method. This is additive — nothing is overwritten, and the
  tracker always computes status from the most recent entry.
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
"Manage test methods" vs. "Manage courses" depending on which button was clicked; new for v3.7 —
the header buttons correctly hide on every analyst's own page, the Planner/Schedule and
Re-evaluation tabs render the right content and switch correctly, non-Analyst positions never show
a tab bar or the Re-evaluation panel at all, editing the Completed date directly updates Next Due
and clears a previously-imported override, and an Excel import against a synthetic file built in the
same layout as your sample screenshot correctly updates multiple people's records in one pass,
carries the imported Re-Training Date through as an explicit override, computes Next Due normally
when a row has no Re-Training Date, and reports unmatched names/Document No.s rather than silently
dropping them; and for the September 2026 import-bugfix round — re-tested against your actual
uploaded export file rather than a synthetic one, confirming it now correctly recognizes every
"Name:" block despite the merged-cell layout, matches diacritic and plain-ASCII spellings of the
same name, correctly reports the people in the file who aren't in the roster, updates every matched
person from a single import (checked for two different people from the same file, from both the
dashboard and the per-person entry points), and triggers a save; and for v3.8 — a mocked person
who rotated positions (evaluated on a method before the rotation, and a different method after)
correctly shows the pre-rotation method as excluded from the dashboard tile and People-table chip
while still visible with a "from previous position" label on their own page, the new filter isolates
it correctly, and a synthetic Section-Manager-position import (no test methods involved at all)
correctly marks a Planner/Schedule course Passed with the right completion date, entirely through the
Course-column join; and new for v3.9 — a mocked Gas analyst with an *empty* Position History (mirroring
your real roster) and a method genuinely from Oil's curriculum correctly reads "not required for
current position" everywhere it should (dashboard tile, combined Flag, filter) purely from curriculum
data, with no position-change history involved at all; an Excel import row matching a Planner/Schedule
course only through its Description CL-T code (no Course-column value present) correctly marks that
course Passed; a row matching the same course through *both* columns updates it exactly once, not
twice; and the People table's single combined Flag column correctly shows "On track"/"Complete" only
once every course and method warning is resolved, the right worst-first text otherwise, and the new
3-bucket filter dropdown narrows correctly — everything passed, and I re-ran the full pre-existing
test suite afterward (course schedules, position changes, Export Report, Progress scope, the v3.6
Test Methods panel, the v3.7 tab/date-edit behavior, the v3.7.1 import-bugfix suite against your real
file, and the v3.8 suite, the latter two updated where they exercised the exact behavior v3.9 changed
on purpose) to confirm nothing else regressed; and new for v3.10 — a mocked Gas analyst and a mocked
Oil analyst, each assigned CL-T-5000/6000-series methods (confirmed to be referenced by none of the 6
Olefins curricula) with real overdue evaluation history, both correctly read "not required for current
position" everywhere — the dashboard tile, the combined Flag, and the panel meta line — while a
genuinely curriculum-matched method for the same person still counts normally; the full pre-existing
suite (including the v3.9 suite, whose badge-status fixture was updated to use only genuine
Gas-curriculum method codes since it had been relying on 5000-series codes as a "no curriculum ties to
anyone" stand-in that v3.10 correctly retires) was re-run afterward and confirmed to still pass; and
new for v3.11 — a mocked veteran Gas analyst (position effective 2023, every Phase 1/2 course already
Passed) with the exact custom-course record read from your live database for `HS-K-4000-001`
(`postLabel: "Month 3 - 4"`, all 6 positions, effective 2026-01-01) correctly reads "Complete" under
the default "Probation (Ph.1+2)" scope (confirming Phase 3 exclusion there is by design, unchanged),
then correctly reads as overdue once switched to "Full progress (all phases)"; the same overdue date
also drives the "Overdue" chip on that person's own Planner/Schedule row, confirming both views now
agree; and in the "Manage courses" admin panel, the Bucket field's datalist correctly lists the Gas
curriculum's existing bucket labels, and attempting to save a new Phase 3 course with an empty Bucket
is correctly blocked while one with a Bucket fills in saves normally — the full pre-existing suite was
re-run afterward (v3.9 and v3.10's suites included) and confirmed to still pass; and new for v3.12 — I
first re-ran the v3.11 check against a mock built from the *current* live data (both duplicate
`HS-K-4000-001` entries as they exist in the database right now) and confirmed the dashboard already
correctly flags Nguyen Dinh Vinh and Pham Van Tuan as overdue on it under "Full progress (all phases)",
ruling out a remaining calculation bug; then, for the Remove fix, a custom course applied to three
curricula (SM/SS/Gas) correctly disappears from all three after one confirmed click of "Remove" on any
one of them, while a second course clicked through the new "Only remove from `<curriculum>`" action
instead disappears from just that curriculum and stays live on the other two; after the user's
follow-up screenshots showed the People-table Flag still not warning despite the person's own
Planner/Schedule tab correctly showing "OVERDUE," the column header in the screenshot itself confirmed
the page had reset to the default scope, which traced to the Progress-basis dropdown never persisting
its value — fixed by saving it to `localStorage` on change and reading it back (guarded, so a browser
that blocks storage just falls back to the old always-reset behavior) — the full pre-existing suite
(v3.9, v3.10, v3.11 included) was re-run afterward and confirmed to still pass; and new for v3.13 —
attempting to add a course reusing a real base-curriculum Lab-code is correctly blocked with an inline
error naming that code, a second attempt reusing an existing topic-embedded Document No. under a
brand-new Lab-code is also correctly blocked, a genuinely unique code and topic still saves normally,
and adding a custom test method whose Document No. differs from an existing one only by letter case is
correctly rejected as a duplicate; and for the Analyst-only fix — three mocked non-Analyst people (SS,
Lead Engineer, Senior Engineer), each carrying the same long-overdue test-method record a stray import
had left in their data, now correctly show no method-related warning on the Flag column, are correctly
excluded from the dashboard's "Test methods needing attention" tile and its click-to-filter list, while
a mocked Analyst (Gas) with the identical underlying data still correctly shows the warning — confirming
the fix is scoped by position, not by deleting or altering any of the underlying records; and for the
target-date fix — a mocked brand-new Gas analyst starting 07 Sep 2026 (matching your own screenshot)
now correctly shows the Week 1 course's target date as 14 Sep 2026 (start + 7 days) instead of
07 Sep 2026 (the start date itself), correctly carries through to Week 2 and beyond, and the course
correctly isn't flagged Overdue while its new, later target date hasn't passed yet; and new for v3.14 —
a mocked Section Manager now correctly gets a second tab labeled "Test Methods" (not "Re-evaluation")
showing the simplified completion-record panel with no Freq./Next due/Status columns, a manual edit to
their Last completed date saves correctly, an Excel import correctly writes a completion record for
them (reverting the v3.13 skip), and — the part most at risk of a silent regression — their Flag column
and the dashboard's "needing attention" tile both stay completely unaffected even after that import,
while a control check confirms the Analyst (Gas) tab, its columns, and its panel title are all
unchanged; and new for v3.15 — a mocked Section Manager's second tab now shows a "Courses — Completion
Record" table listing their whole curriculum, editing a course's Completed date there correctly marks it
Passed and that exact change is reflected on the Planner/Schedule tab's Status dropdown for the same
course (and saved with the exact date entered, not today's date), clearing the date correctly reverts it
to Not Started, and a mocked Gas analyst confirms the same new Courses table appears for Analysts too
without touching their existing Re-evaluation panel; and new for v3.16 — after your follow-up feedback,
a mocked Gas analyst's curriculum course that embeds a real catalog Document No. (CL-T-2000-0001)
correctly shows just once, as its Test Methods row, with no separate Courses row for it; entering a
Completed date on that merged row correctly also marks the matching Planner/Schedule course Passed with
the same date (confirmed both in the UI and in the exact record saved); the reeval tab correctly shows
exactly one panel and one table again (not two); a mocked Section Manager confirms the same merge and
correct panel title for non-Analysts; and a plain, non-method-linked course row still saves correctly
through its own Completed-date field, unaffected by the merge. Several pre-existing tests needed small
selector updates (not behavior changes) — the v3.15-era ones that had been updated to target "the second
of two panels" now correctly target "the" panel again since there's only one; a few also needed their
expected header/panel-title text updated to match the new "Courses & Test Methods —" wording and merged
column headers. The full pre-existing suite (v3.9–v3.15 included) was re-run afterward and confirmed to
still pass; and new for v3.17 — a mocked Shift Supervisor built to mirror your exact screenshot (a
Polyolefins method, CL-T-6000-0027, left over from before this fix with `assigned: true` and real
evaluation history, plus a second Polyolefins method that was never assigned at all) now correctly shows
neither method anywhere on their page under any filter including "All," while a genuine
Shift-Supervisor-curriculum method appears automatically with no tick required; no checkbox/tick control
exists anywhere in the merged table for any position; "Log eval." is available immediately for a listed
method with no separate assign step first; and — checked directly against the mocked database rather
than just the screen — the stray CL-T-6000-0027 record is confirmed still present and completely
unmodified underneath, with zero database writes triggered by simply viewing the page, proving the fix
is a display filter, not a data deletion. The full pre-existing suite (v3.9–v3.16 included, with the
shared Excel-import fixture regenerated using real curriculum-matched Document Nos. for the mocked Gas
and Oil people it exercises, since the old fixture had been using Document Nos. that happened not to
belong to either mocked person's actual curriculum) was re-run afterward and confirmed to still pass;
and new for v3.18 — a mocked Gas analyst with real, dated evaluation history on both an Oil-curriculum
method and a Polyolefins method with no Olefins-curriculum ties at all (the exact "before rotating"
case you described) now correctly shows both, each carrying the "(not required for current position)"
tag on its Code cell, with Next Due reading "—" and Status reading "Not required" instead of a real
overdue chip despite genuinely old evaluation dates underneath; neither shows up under the Overdue
filter; the dedicated "Not required for current position" filter correctly isolates exactly these rows
and nothing else; a genuinely curriculum-matched, never-evaluated method still appears normally,
unaffected; a catalog method this same person has never touched and that isn't in their curriculum
still correctly stays hidden entirely, confirming v3.17's original clutter fix is untouched; and a
control person with no stray records at all shows no "not required" badge or count anywhere on their
page. The three pre-existing test files whose fixtures happened to include a real, dated evaluation on
a curriculum-irrelevant method (`_pw_v39_curriculum.js`, `_pw_v310_polyolefins_methods.js`,
`_pw_v314_nonanalyst_completion_record.js`) had their assertions updated from "correctly hidden" to
"correctly shown, marked not required" — not because anything regressed, but because those fixtures
exercise exactly the display behavior this round intentionally restored; the rest of the full
pre-existing suite was re-run unchanged and confirmed to still pass; and new for v3.19 — built directly
against your bug report: a mocked Section Manager import row for `CL-P-1000-0023` carrying a
deliberately-wrong Course-column Lab-code (mirroring your real screenshots, where the plan document's
`Lab-04-03-003` and the real export's `Lab-04-03-001` disagree for the same course) now correctly gets
its Completed date written to the Planner/Schedule tab anyway, matched by Description-column Document
No. instead; a row for `CL-P-1000-0022` with *no* Course-column value at all (only a Description-column
Document No.) — previously silently skipped in full, before ever reaching the match logic — now
correctly updates too; a row for `CL-W-1000-99-0010` (a Document No. with an extra dash-segment beyond
the CL-T-style 2-segment shape) also correctly updates, confirming the fix isn't accidentally narrowed
to 2-segment codes; the import summary correctly stops flagging the deliberately-wrong Lab-code as
"unmatched" once the row matched through the Document No. path instead; and, checked separately, the
loosened Course-column regex plus its new leading-zero-tolerant comparison correctly matches
`Lab-01-03-12` against a stored `Lab-01-03-012`-style code on their own, independent of the Document-No.
path. The full pre-existing suite (v3.9–v3.18 included) was re-run afterward and confirmed to still
pass, with no fixture changes needed this round — the fix only adds new matching paths, it doesn't
change any existing one's behavior. `node --check` clean throughout; and new for v3.20 — for the
per-row Edit panel: opening it on a real course (`sm-10` / `Lab-03-03-001`, which the live data has
applying to Section Manager and Lead/Senior/QC Engineer only) correctly pre-fills Trainer and
Evaluation method and shows the Applies-to checkboxes matching that real data exactly; extending it
to Gas auto-seeds that curriculum's Phase/Week-or-Bucket from the course's own current values the
moment the box is checked; narrowing it by dropping Eng stages a "Pending" chip the same way any
other field edit does; committing through the existing effective-date/scope Apply bar correctly
shows the course on the Gas tab and removes it from the Eng tab, leaves the untouched SM tab alone,
and the panel — which stays open across tab switches by design — immediately reflects the
post-commit checkbox state without needing to be closed and reopened. For the plan-revision import: a
synthetic workbook seeded directly from the app's own real SM and Gas COURSE_DATA (not invented data)
with a deliberate set of changes — a Lab-code + hours + trainer change on `CL-M-1000-0001`, an
existing course (`CL-P-1000-0002`) dropped from the file entirely, and four new rows exercising every
branch of the auto-classification rule (a `(*)`-suffixed new course → correctly P2; a universal
Phase-1 Document No. new to SM → correctly P1; that same Gas-only Phase-1 Document No. imported under
SM instead of Gas → correctly stays P3, confirming the Gas-only scoping doesn't leak into other
curricula; an unremarkable new document → correctly defaults to P3) — correctly produces a review
screen showing only the SM curriculum (Gas, imported byte-for-byte unchanged, produces zero diff and
never appears); the changed row's Lab-code diff is shown but labeled informational-only; unchecking
one of the four new courses before Apply correctly excludes only that one; and after Apply, the
Lab-code on record for `CL-M-1000-0001` is confirmed unchanged (never auto-applied) while its hours
change is, `CL-P-1000-0002` is confirmed still present but now inactive, all three included new
courses appear with the correct auto-classified Phase, the excluded one does not appear at all, and
the Gas tab (81 courses) is confirmed completely unaffected by the SM-side import, byte-for-byte. The
full pre-existing suite (28 files, all rounds through v3.19) was re-run afterward and confirmed to
still pass — one older, position-rotation test file (`_pw_poschange.js`) turned out to have a stale
mock database missing the `onb_methods` table (predating that table's introduction, unrelated to this
round's changes), which surfaced as the mock's initial data fetch failing; fixed the fixture and
confirmed the actual rotation logic it tests is unaffected. `node --check` clean throughout; and new
for v3.21 — reproduced your report directly: the same `CL-M-1000-0001` change now also carries a
trainer-only difference (nothing else touched), and it no longer shows up on the review screen at all
— not under Changed, not anywhere — confirming a trainer-only difference is never flagged again, on
this import or any later one; the deliberate hours-change case above continues to show correctly as
Changed on its own; and after Apply, the on-record trainer for `CL-M-1000-0001` is confirmed
completely untouched (still whatever it was before the import, not the file's value) while the hours
change still applies as before, confirming Trainer editing itself (via the Edit panel) is unaffected —
only the plan-import comparison and apply path changed. The full pre-existing suite (29 files) was
re-run afterward and confirmed to still pass. `node --check` clean throughout.
However, this sandbox's network access doesn't
reach Supabase or GitHub directly, so I have not been able to load the page against your *real*
database over the internet. Please do a quick smoke test after you publish it: open the page,
confirm the 24 people and their Passed/Not Started course statuses look right, add a test person
and refresh the page to confirm it's still there, then delete the test person. Also worth trying
the new Change Position flow once on a test person before relying on it for a real rotation. For
v3.6, open "Manage test methods" and confirm all 179 methods and their frequencies look right, then
open a test person's page, assign a method, log an evaluation, refresh the page and confirm it's
still there. For v3.7, open an Analyst's page and confirm the header buttons are gone and the two
tabs work, try editing a Completed date directly, and try the dashboard's "Import test results
(Excel)" button on one of your own real export files to confirm it updates everyone the file covers
and the summary banner's counts look right before relying on it for routine use. For v3.8, check
Ninh Minh Hai's own page (or anyone else who's rotated) and confirm the pre-rotation method now reads
"from previous position" instead of driving an "Overdue" tile count, and try an import against a file
covering a Section Manager/Supervisor/Engineer to confirm their Planner/Schedule tab picks up the
Course-column matches correctly. For v3.9, check Ninh Minh Hai, Nguyen Thanh Tuan, and Nguyen Dinh
Vinh's own pages and confirm their Oil/Poly-era methods now read "not required for current position"
and no longer drive the dashboard tile or their People-table Flag — this should now hold even though
none of them have a logged Position History; re-run your real training-report export through either
Import button and spot-check that a course like `CL-T-4000-0006` that was previously stuck at "Not
Started"/"OVERDUE" on the Planner/Schedule tab now shows Passed with the right completion date; and
take a look at the People table's Flag column to confirm it now reads as one clear signal per person
instead of two. For v3.10, check Nguyen Dinh Vinh and Van Minh Tien's own pages and confirm their
`CL-T-5000-xxx`/`CL-T-6000-xxx` (Polyolefins-section) methods now read "not required for current
position" and no longer drive the dashboard tile or their People-table Flag, and spot-check a few
other Gas/Oil/Utility analysts with older evaluation history for the same pattern. For v3.11, switch
the Progress-basis dropdown to "Full progress (all phases)" and confirm `HS-K-4000-001` now shows up
correctly in the Progress %/Flag figures for people whose position started long enough ago, and try
adding a test Phase 3 course in "Manage courses" with the Bucket field left blank to confirm it's
now blocked from saving. For v3.14, open a Section Manager/Supervisor/Lead/Senior Engineer's own page
and confirm the second tab is labeled "Test Methods" (not "Re-evaluation") and opens a plain completion
record with no Status column; try recording one manually and via a real Excel import file that covers
one of these positions, and confirm their Flag column and the dashboard tile stay unaffected either way.
For v3.15, open anyone's second tab (any position) and confirm the new "Courses — Completion Record"
table appears above the existing methods table, enter a Completed date on a course there and switch to
Planner/Schedule to confirm the same course now shows Passed with that same date, then clear the date
and confirm it reverts to Not Started on both tabs. For v3.17, open the Shift Supervisor's page from
your screenshot (or any Supervisor/Engineer/Section Manager) and confirm the Polyolefins CL-T-6000-xxx
rows are gone entirely — not unticked, just absent — under every filter including "All"; confirm there's
no checkbox anywhere in the table for any position; and spot-check a couple of other positions
(Gas/Oil/Utility Analysts, Lead/Senior Engineer) to confirm each one's Test Methods list now looks like
a real, position-specific curriculum rather than the full catalog. For v3.18, check anyone who's
actually rotated or been promoted (Ninh Minh Hai, Nguyen Dinh Vinh, Van Minh Tien are the real
long-tenured examples) and confirm a method they completed under their earlier position is back —
marked "(not required for current position)," no due date, no status chip, not selectable under
Overdue/Due soon — and that the new "Not required for current position" option in the status-filter
dropdown isolates exactly those rows; then check a newer hire with no rotation history to confirm they
see no such tag or count anywhere. For v3.19, re-run one of your real Excel import files (the same one
from the bug report is ideal) against the affected Section Manager and confirm `CL-P-1000-0023` (and
any other course whose Completed date stayed blank before) now picks up its date on the Planner/
Schedule tab; then check the import result banner for any remaining "Course code(s) not found"
entries — those are genuinely not in that person's current curriculum (company-wide training, or a
position they've since rotated out of), not this bug. For v3.20, in "Manage courses" try the Edit
button on a course that applies to more than one position and confirm the Applies-to checkboxes match
what you already know is true; try extending it to a new position and dropping it from an existing
one, apply, and confirm both tabs updated correctly. Then get a real, up-to-date copy of the
Functional Training Plan CL-D-1000-0001 and try "Import plan revision" against it — before clicking
Apply, read through every section on the review screen carefully (this is exactly why it's a review
screen and not an immediate apply): check that new courses landed in the Phase you'd expect, that
anything marked "possibly obsolete" is actually meant to be retired and not just a Lab-code rename
that should instead be a manual Edit, and that changed items' diffs look right — then apply and
spot-check a few of the affected people's own pages. For v3.21, this is the same "Import plan
revision" flow — just confirm that a course whose only difference from what's on record is its
Trainer name no longer shows up in the Changed section at all (it used to, every time, even for a
file you'd already imported before).

## Everyday use

Nothing about how you use the tracker day-to-day changes — same dashboard, same course lists, same
"Manage courses" admin panel. The only difference is that every edit now saves straight to the
shared database instead of "publishing" a new version of the page, so there's no more save/share
button to think about — it just always reflects the latest data, for everyone.
