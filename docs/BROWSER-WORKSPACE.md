# Browser Local-First Workspace

The GitHub Pages app is now a client-side project manager. It stores project data in browser localStorage and never needs a cloud database for the core workflow.

## Features
- Multiple local book projects
- Project brief and lifecycle state
- Research source ledger with URL, source type, finding, supported claim, and checked date
- Gap scorecards for demand evidence, complaint frequency, competitor weakness, specificity, and expansion potential
- Pipeline stage tracking
- Human publication approval gate
- Full backup export/import
- Individual project JSON export
- Offline shell via a service worker

## Data model
The browser database key is `bre.v1`. A project contains its brief, lifecycle status, stage state, source ledger, gap scorecards, notes, timestamps, and approval state.

## Privacy
The app does not send project data to a server. Browser storage is local to the device/browser. Users should still export backups and should not store passwords, API keys, payment credentials, or sensitive customer information here.

## Research integrity
The ledger records evidence; it does not automatically treat a source as proof. Verify important claims and record dates. Gap scores are prioritization aids, not predictions of sales or income.

## Publishing gate
The approval checkbox is intentionally local and non-publishing. It does not connect to KDP or Gumroad and cannot publish automatically.
