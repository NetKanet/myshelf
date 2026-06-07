# Research: My Shelf MVP

**Phase 0 output** — resolves the unknowns in the plan's Technical Context.

---

## R1. Google sign-in with Supabase in Flutter

**Decision**: Use the native `google_sign_in` package to obtain Google `idToken` +
`accessToken`, then call `supabase.auth.signInWithIdToken(provider: OAuthProvider.google,
idToken: ..., accessToken: ...)`.

**Rationale**:
- Native account picker → best one-tap UX (no browser bounce), matches FR-001.
- Supabase creates/returns a session and persists it automatically, satisfying FR-003
  (session persists across restarts) with no extra storage code.
- Per-user `auth.uid()` flows straight into RLS, giving FR-004a isolation for free.

**Setup required (manual, one-time — out of code)**:
- Google Cloud Console: OAuth client IDs — an iOS client ID, an Android client ID, and a
  Web client ID (the Web client ID is used as `serverClientId` on the native call).
- Supabase Dashboard → Authentication → Providers → enable Google, paste the Web client
  ID + secret.
- iOS: add the reversed client ID URL scheme to `Info.plist`.

**Alternatives considered**:
- `supabase.auth.signInWithOAuth(OAuthProvider.google)` (browser redirect + deep link):
  rejected — needs custom URL-scheme redirect handling and shows a browser, worse UX.

---

## R2. Exposing `rating` but hiding `review` on the public profile

**Decision**: Create a Postgres **read-only view** (e.g. `public_finished_shelf`) that
selects only safe columns — book cover, title, author, finish date, rating — joined from
`user_books` + `books`, filtered to `status = 'finished'` AND the profile owner's
`user_id`. Grant `SELECT` on the view to the `anon` role; do **not** grant `anon` direct
`SELECT` on `user_books`.

**Rationale**:
- Row-level security cannot hide a single column; a view is the simplest way to expose
  `rating` while excluding `review` (FR-028).
- The view's `WHERE user_id = <owner>` enforces owner-scoping (FR-028a) in one place.
- The website keeps using a single REST call (`/rest/v1/public_finished_shelf`), no app
  changes when the shelf updates (FR-026).

**Owner identity**: store the owner's `user_id` so the view can reference it — simplest is
a one-row `app_config` table (or a hardcoded constant in the view during MVP). Recorded in
data-model.md.

**Alternatives considered**:
- Per-column `GRANT SELECT (col, …)`: works but is fragile and still can't filter to owner
  without RLS gymnastics.
- Supabase Edge Function returning curated JSON: more moving parts than a view; deferred.

---

## R3. Per-user isolation + public-finished policy on `user_books`

**Decision**: Two RLS policies on `user_books`:
1. `owner full access`: `auth.uid() = user_id` for ALL — each signed-in user reads/writes
   only their own rows (FR-004a).
2. No public/anon policy on the base table at all — the public path goes through the view
   only (R2). The view runs with the privileges needed to read finished rows of the owner.

**Rationale**: Keeps the base table strictly private per user; the only public surface is
the curated view. Satisfies P2 (public read = finished only) and FR-028 (no review leak).

---

## R4. Barcode scanning

**Decision**: `mobile_scanner` for camera + barcode detection on-device.

**Rationale**: Cross-platform (iOS + Android), reads EAN-13 (book ISBN) on-device with no
API cost (P3), actively maintained. Camera-permission denial is handled in-app with a
settings link (FR-018).

---

## R5. ISBN lookup, cache-first

**Decision**: On a detected ISBN: (1) query `books` by ISBN; if present, use it (no
external call, FR-013). (2) On miss, `GET https://www.googleapis.com/books/v1/volumes
?q=isbn:{isbn}`, map the first volume to the `books` shape, upsert, and use it. (3) On
no result, offer manual entry. Cover thumbnail URLs are normalized `http://` → `https://`
(iOS ATS / Android cleartext).

**Rationale**: Matches the cache-first principle (P3) and FR-012/014. Google Books is free
and key-less for this volume; the design keeps the call in one service so it can later
move behind an Edge Function without UI changes (constitution Technology Constraints).

**Out of scope for MVP**: Open Library as a secondary fallback (deferred to v2 per spec).

---

## R6. Shelf filtering & sort

**Decision**: Load the user's `user_books` (joined with `books`) and filter client-side by
chip: All (no filter), Reading/Finished/Want to Read (by `status`), Rated
(`rating IS NOT NULL`), Reviewed (`review IS NOT NULL`). Sort: Finished by
`date_finished DESC`; everything else by `created_at DESC` (FR-008). Default chip: All.

**Rationale**: Data volume is tiny (single user), so client-side filtering on one fetched
list is simplest (P4) and keeps the shelf reactive to edits. Indexed queries are available
if needed but not required at this scale.

---

## Resolved unknowns

All Technical Context items are resolved; no `NEEDS CLARIFICATION` remain. Spec-level
ambiguities were already resolved in `/speckit-clarify` (see spec.md §Clarifications).
