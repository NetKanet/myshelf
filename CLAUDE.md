<!-- SPECKIT START -->
## Active Spec Kit feature

**Feature:** My Shelf MVP — Track & Share Reads
**Branch:** `001-mvp-foundation`

- **Plan:** [specs/001-mvp-foundation/plan.md](specs/001-mvp-foundation/plan.md) — read this first for stack, structure, and approach
- **Spec:** [specs/001-mvp-foundation/spec.md](specs/001-mvp-foundation/spec.md)
- **Research:** [specs/001-mvp-foundation/research.md](specs/001-mvp-foundation/research.md)
- **Data model:** [specs/001-mvp-foundation/data-model.md](specs/001-mvp-foundation/data-model.md)
- **Contracts:** [specs/001-mvp-foundation/contracts/](specs/001-mvp-foundation/contracts/)
- **Constitution:** [.specify/memory/constitution.md](.specify/memory/constitution.md) — 7 principles (v1.3.0)

## Project snapshot

**My Shelf** — personal Flutter bookshelf for Net (admyhusky). Sign in with Google, keep
one shelf of books filtered by status/rating/review, scan ISBN to add (cache-first via
Google Books, manual fallback), set status/dates/rating/review per book. A public profile
site shows finished books live (cover/title/author/finish-date/rating; never the review).

**Stack (fixed):** Flutter + Riverpod + GoRouter + Supabase (Postgres + Auth + RLS).
Mobile app lives in `app/`. Cover images = URL only. Stay in free tier.

**Status (2026-06-08):** Mobile app done (US1–US4) + v2 UI polish (bottom nav, profile
dashboard with charts, full dark mode). `flutter analyze` 0 issues, `flutter test` 16 pass.
**Remaining:** public web profile (US5 — `app_config.owner_user_id`, wire
`admyhusky-dev-template/data.js` to `public_finished_shelf`, verify privacy) + 8 quickstart
scenarios on simulator. See [docs/prd.md](docs/prd.md) "Implementation status".

**Spec Kit flow:** `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
`/speckit-implement`. Each feature on its own `NNN-name` branch.
<!-- SPECKIT END -->
