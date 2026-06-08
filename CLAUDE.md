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

**Stack (fixed):** Flutter + Riverpod + GoRouter + Supabase (Postgres + Auth + RLS +
Storage). Mobile app lives in `app/`. Covers prefer a URL; users may also upload one to a
public Storage bucket (5 MB / image-only). Stay in free tier.

**Status (2026-06-09) — MVP complete, tagged `v1.1.0`:** All 38 spec tasks done (US1–US5).
Mobile app: Google sign-in, year-grouped shelf + filters, ISBN scan (cache-first → Google
Books → manual), book detail (status/dates/rating/review, cover link/upload), profile
dashboard (year filter with All toggle, status breakdown + avg rating, cumulative pace
chart), full dark mode. Public web reads finished books live from `public_finished_shelf`
(deployed via Cloudflare, tag `v2.2.0`); privacy verified (anon can't read `user_books`,
review never exposed). `flutter analyze` 0 issues, `flutter test` 16 pass.
**Remaining:** on-device install (deferred — needs a cable or paid Apple Developer) +
on-device camera-scan smoke test. See [docs/prd.md](docs/prd.md) "Implementation status".

**Spec Kit flow:** `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
`/speckit-implement`. Each feature on its own `NNN-name` branch.
<!-- SPECKIT END -->
