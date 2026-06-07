<!--
Sync Impact Report
==================
Version change: 1.0.0 → 1.3.0
Rationale: 1.1.0 added the Cache-First & Free-Tier principle and expanded the
Technology/Workflow sections. 1.2.0 redefined P1 to Google-only sign-in and added a
"propose a better approach" clause to P7. 1.3.0 refines P1 to "Personal-First,
Sharing-Free": open Google sign-in with per-user isolation and owner-scoped public
profile (resolved via spec 001 clarification on 2026-06-07).
Re-established after a clean repository reset on 2026-06-07; principle content refined
from docs/prd.md v2.0.

Modified principles:
  - P1 Personal-First, Sharing-Free (was "Small-Scale, Auth-Ready" → "Single-User";
    now open sign-in + per-user isolation + owner-scoped public profile, no social features)
  - P2 Public Read = Finished Books Only (kept, NON-NEGOTIABLE)
  - P3 Cache-First & Free-Tier Discipline (added in 1.1.0)
  - P4 No Over-Engineering (was P3 in 1.0.0)
  - P5 Clean Code & Quality (was P4 in 1.0.0)
  - P6 Living Documentation (was P5 in 1.0.0)
  - P7 No Guessing, Always Discuss (was P6; added "propose better approach" clause)
Added sections: none (Section 2/3 expanded, not added)
Removed sections: none
Templates requiring updates:
  - .specify/templates/spec-template.md ✅ aligned (privacy + scope constraints honored)
  - .specify/templates/plan-template.md ✅ aligned (Constitution Check gate references these)
  - .specify/templates/tasks-template.md ✅ aligned (test + docs task types covered)
Follow-up TODOs: none
-->

# My Shelf Constitution

**Project:** My Shelf — a personal digital bookshelf for Net (admyhusky): scan an ISBN,
track reading status with ratings and reviews, and surface finished books live on the
public profile at `admyhusky.dev`.

This constitution defines the non-negotiable principles that govern every design,
implementation, and review decision. Every contributor — human or AI — MUST follow it.

## Core Principles

### P1: Personal-First, Sharing-Free

My Shelf is a personal app built for one owner (Net), not a social platform.

- Authentication is via **Google (Gmail) sign-in** only — no email/password and no public
  registration. Additional providers MAY be added later but are not required.
- Sign-in is NOT restricted to a single account; any Google account may sign in and each
  user's data MUST be fully isolated by per-user access rules. The public profile MUST
  show only the profile owner's finished books.
- MUST NOT build social or sharing features (following, comments, shared shelves, etc.)
  or large-scale infrastructure.
- MUST stay within the free-tier limits of every service.
- Rationale: isolation comes free from per-user access rules, so open sign-in costs
  nothing; effort is reserved for the owner's reading experience, not social or scale
  concerns.

### P2: Public Read = Finished Books Only (NON-NEGOTIABLE)

The public web profile fetches data using the anonymous key. Row Level Security MUST
enforce that only books with `status = 'finished'` are publicly readable.

- This is a SECURITY constraint, not a preference.
- MUST NOT expose reading lists, want-to-read, ratings, reviews, or any private data to
  unauthenticated requests.
- Any change to RLS policies MUST be reviewed against this principle before it ships.

### P3: Cache-First & Free-Tier Discipline

Staying inside the free tier of every service is a hard constraint that outranks
feature convenience.

- Point lookups (scan / ISBN) MUST check the local `books` cache first; an external
  catalog MUST be contacted only on a cache miss.
- Re-scanning a known book MUST NOT trigger an external API call.
- Cover images MUST be stored as a URL only; image files MUST NOT be downloaded into the
  database or object storage.
- External catalog calls MUST be fault-isolated and time-bounded; a failing source
  advances the fallback chain rather than blocking or crashing the flow.
- Rationale: the project survives only if it never exceeds free quotas.

### P4: No Over-Engineering

Build the simplest thing that satisfies the spec (YAGNI).

- MUST prefer a feature-first folder structure and direct service calls over speculative
  abstractions, custom backends, or premature generalization.
- New complexity MUST be justified in the plan's Complexity Tracking section.

### P5: Clean Code & Quality

Code MUST be readable, consistent with surrounding code, and verifiably correct.

- Static analysis MUST pass with zero warnings before a change is considered done.
- Services and state logic MUST have unit tests; critical flows MUST have integration
  tests. Tests MUST pass before merging.
- Changes SHOULD be verified against real behavior (run the app or its tests), not
  assumed to work.

### P6: Living Documentation

The spec, plan, tasks, PRD, and agent guidance MUST reflect reality.

- When behavior or scope changes, the corresponding document MUST be updated in the same
  unit of work.
- Documentation that has gone stale is treated as a defect.

### P7: No Guessing, Always Discuss

Ambiguity MUST be resolved with the owner, not guessed.

- Decisions that change scope, data shape, security, or user experience MUST be confirmed
  before implementation.
- Irreversible or outward-facing actions MUST be confirmed before they are taken.
- When a better approach than the one requested exists, the contributor MUST propose it
  rather than silently following the original instruction.
- Rationale: a wrong assumption is more expensive than a question.

## Technology Constraints

- Stack is fixed: **Flutter (Dart)** mobile app, **Riverpod** state, **GoRouter**
  routing, **Supabase** (Postgres + Auth + RLS) backend. The stack MUST NOT be changed.
- The Flutter project lives in `app/`; the public web profile consumes Supabase via its
  REST API with the anon key.
- External catalog sources (Google Books primary, Open Library fallback) are free and
  key-less for the volumes used. Calls MAY originate from the client today; the design
  MUST allow relocating them behind a server/edge function later without changing
  user-facing behavior.
- Secrets (Supabase credentials, signing keys) MUST be gitignored and never committed.
- The Supabase project is separate from any other project's backend.

## Development Workflow

- Work is spec-driven via Spec Kit: `/speckit-specify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`, with `/speckit-clarify` and
  `/speckit-analyze` used as needed.
- Each feature is developed on its own feature branch named `NNN-short-name`.
- Every plan MUST pass the Constitution Check gate before implementation begins.
- A change is "done" only when: static analysis is clean, relevant tests pass, behavior
  is verified, and affected documentation is updated.
- Commits and pushes happen only when the owner asks.

## Governance

- This constitution supersedes other practices; where guidance conflicts, the
  constitution wins.
- Amendments MUST be recorded here with a version bump and a Sync Impact Report, and MUST
  propagate to dependent templates and guidance files in the same change.
- Versioning follows semantic rules: MAJOR for incompatible governance/principle changes,
  MINOR for added or materially expanded principles/sections, PATCH for clarifications.
- Every plan and review MUST verify compliance with these principles; violations MUST be
  fixed or explicitly justified in Complexity Tracking.

**Version**: 1.3.0 | **Ratified**: 2026-06-06 | **Last Amended**: 2026-06-07
