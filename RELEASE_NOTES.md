# Release Notes

## v0.1.0 draft

Initial public draft.

Features:

- Native macOS menu bar app built with SwiftPM + AppKit.
- Reads Hermes Agent `state.db` in SQLite read-only mode.
- Shows today's token total in the status bar.
- Dropdown shows Today/Month totals, Input/Output breakdowns, top models, DB path, and refresh time.
- Restrained color coding for key rows.
- Supports `HERMES_TOKENBAR_DB` for custom database paths.
- No TokenTracker runtime dependency.
- No network calls, hooks, uploads, or Hermes config writes.

Known limits:

- macOS only.
- Token view is model-side activity, not exact billing.
- Current build script creates an unsigned local app bundle.
- Release asset should be zipped and SHA256 checked before publishing.
