# Implementation Plan: My Shelf MVP — Track & Share Reads

**Branch**: `001-mvp-foundation` | **Date**: 2026-06-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-mvp-foundation/spec.md`

## Summary

A Flutter mobile app where the owner signs in with Google, sees one shelf of all their
books with filter chips (status / rated / reviewed), adds books by scanning an ISBN
(cache-first lookup, manual fallback), and manages each book's status, dates, rating, and
review on a detail screen. Ratings and reviews exist only for finished books and are
preserved (hidden, not deleted) if a book leaves the finished state. A public profile
website reads finished books live — exposing cover, title, author, finish date, and
rating, but never the review — scoped to the profile owner only.

Backend is Supabase (Postgres + Auth + Row Level Security). External book data comes from
the free Google Books API, called client-side and cached in a shared `books` table.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (stable)

**Primary Dependencies**: `supabase_flutter`, `flutter_riverpod`, `go_router`,
`google_sign_in`, `mobile_scanner`, `cached_network_image`, `http`, `intl`;
dev: `flutter_test`, `mocktail`

**Storage**: Supabase Postgres — tables `books` (shared catalog) and `user_books`
(per-user shelf); a public read-only view for the website

**Testing**: `flutter_test` + `mocktail` (unit tests for providers/services, integration
tests for the scan→save flow); `flutter analyze` zero-warning gate

**Target Platform**: iOS and Android (mobile); the public profile is a separate static
website that reads Supabase via REST with the anon key

**Project Type**: Mobile app (`app/`) + a thin web-integration change to the existing
profile site

**Performance Goals**: Scan-to-detail within a few seconds on a catalog hit; 60 fps UI;
re-scan of a cached book makes zero external calls

**Constraints**: Must stay within Supabase + Google Books free tiers; cover images stored
as URL only; one primary user but per-user isolation enforced

**Scale/Scope**: ~5 screens (Sign-in, Shelf, Scan, Manual entry, Book detail); single
active user; low data volume

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | How the plan satisfies it |
|-----------|--------|---------------------------|
| P1 Personal-First, Sharing-Free | ✅ PASS | Google-only sign-in (open, per-user RLS isolation); owner-scoped public view; no social features |
| P2 Public Read = Finished Only | ✅ PASS | Public access via a view exposing only finished rows and safe columns (review excluded); anon has no direct table read |
| P3 Cache-First & Free-Tier | ✅ PASS | ISBN resolves from `books` cache before any API; cover_url only; Google Books free tier; lookups time-bounded |
| P4 No Over-Engineering | ✅ PASS | Feature-first folders, direct Supabase calls, no custom backend or speculative abstraction |
| P5 Clean Code & Quality | ✅ PASS | Unit + integration tests planned; `flutter analyze` zero warnings; verify on simulator |
| P6 Living Documentation | ✅ PASS | CLAUDE.md plan reference updated in Phase 1; PRD already aligned |
| P7 No Guessing, Always Discuss | ✅ PASS | Ambiguities resolved via `/speckit-clarify` (3 Q&A in spec) |

**Gate Result**: ALL PASS — proceed to Phase 0. Re-checked post-design: still ALL PASS
(no new complexity introduced).

## Project Structure

### Documentation (this feature)

```text
specs/001-mvp-foundation/
├── plan.md              # This file
├── research.md          # Phase 0 — decisions (Google sign-in, public view, scanner)
├── data-model.md        # Phase 1 — tables, view, RLS, state transitions
├── quickstart.md        # Phase 1 — how to run & validate end-to-end
├── contracts/           # Phase 1 — public web read + Google Books mapping
│   ├── public-web-read.md
│   └── google-books-lookup.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
app/                                 # Flutter project (flutter create)
└── lib/
    ├── core/
    │   ├── config/supabase_config.dart   # URL + anon key (gitignored)
    │   ├── router/app_router.dart        # GoRouter + auth redirect
    │   └── theme/app_theme.dart
    ├── models/
    │   ├── book.dart
    │   └── user_book.dart                # status, dates, rating, review
    ├── services/
    │   ├── supabase_service.dart         # books + user_books CRUD
    │   └── google_books_service.dart     # ISBN lookup (http→https covers)
    ├── features/
    │   ├── auth/                         # Google sign-in screen + provider
    │   ├── shelf/                        # combined list + filter chips
    │   ├── scan/                         # camera + manual fallback
    │   └── book_detail/                  # status/dates/rating/review/delete
    └── main.dart
└── test/
    ├── features/                        # provider unit tests
    └── ...                              # scan flow integration test

admyhusky-dev-template/                  # existing public site (web integration)
└── data.js                              # change: fetch the public view live
```

**Structure Decision**: Mobile app lives in `app/` (feature-first), per the constitution's
fixed stack. The web integration is a small change to the existing profile site's
`data.js`. No separate backend service — Supabase is the backend.

## Complexity Tracking

> No constitution violations. The one non-obvious piece — a public view to expose `rating`
> while hiding `review` — is required by FR-028 (column-level privacy) and is simpler than
> the alternatives (per-column grants, or an Edge Function), so it is not a violation.

| Decision | Why needed | Simpler alternative rejected because |
|----------|-----------|--------------------------------------|
| Public read-only view (not direct table) | Hide `review` while showing `rating`; scope to owner; finished-only | Direct anon table read cannot hide a single column; per-column grants are more fragile and harder to scope to owner |
