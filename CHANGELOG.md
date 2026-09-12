## v3.23 — Person-page Save Confirmation

Date: 2026-09-12

### Requested change

Replace automatic saving on an individual person's page with an explicit Save Changes process.

### Required behavior

- Person-page edits remain temporary until Save Changes is clicked.
- Save Changes saves all edits for the current person.
- Discard Changes restores the original values.
- Leaving the page with unsaved changes requires confirmation.
- Failed saves keep the unsaved draft visible.
- Dashboard and admin automatic-save behavior remains unchanged initially.
- No database migration is expected.

### Scope

- Person information
- Planner/Schedule course information
- Test-method evaluation information
- Person-page navigation and refresh warnings

### Testing person

Use a temporary test person only. Do not test first on a real employee.

### Status

Planning completed. Implementation not started.
