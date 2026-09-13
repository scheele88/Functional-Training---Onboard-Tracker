## v3.23 — Person-page Save Confirmation Completed

### Completed

- Name and Employee ID changes are detected immediately.
- Status and Notes changes are held as drafts.
- Position changes are held as drafts.
- The Change Position modal no longer saves directly.
- Save Changes commits the complete current person record.
- Discard Changes restores the original person record.
- Browser refresh warns when unsaved changes exist.
- No database migration was required.

### Verification

- Save multiple fields together: Passed
- Discard multiple fields together: Passed
- Refresh before saving: Passed
- Cancel refresh: Passed
- Position change without main Save: Passed
- Position change with main Save: Passed
- Console errors: None observed
