# Quickstart validation results (T037)

Run against the iOS simulator (iPhone 16e), the live Supabase project, and the test
suite. Date: 2026-06-08. Owner account: admyhusky@gmail.com (27 finished books).

| # | Scenario | Result | Evidence |
|---|----------|--------|----------|
| 1 | Sign in / persist / sign out (US1) | ✅ Pass | Signed in via Google; shelf loads; session persists across relaunch (Supabase session); sign-out in Settings. `auth_provider_test` covers success/failure/state. |
| 2 | Shelf filters + empty states (US2) | ✅ Pass¹ | Shelf shows books grouped by finish year; funnel filter All / Want to Read / Reading / Finished. `shelf_provider_test` covers each filter + sort + empty. |
| 3 | Scan a known book (US3) | ⚠️ Logic pass² | `scan_flow_test` covers ISBN→catalog→shelf as Want to Read. Camera scan UI can't run on the iOS simulator (no camera) — needs a real device. |
| 4 | Cache hit, no API call (US3) | ⚠️ Logic pass² | `scan_flow_test` proves cache-first resolves without a Google Books call. Camera N/A on simulator. |
| 5 | Manual fallback (US3) | ✅ Pass² | Manual-entry page adds a book (title+author → `source='manual'`); `scan_flow_test` covers the manual path. (Scan trigger itself needs a camera.) |
| 6 | Detail: dates, rating, review persist (US4) | ✅ Pass | `book_detail_provider_test` persists rating+review on save; half-star ratings render on shelf cards (see screenshots). |
| 7 | Un-finish keeps rating/review (US4) | ✅ Pass | `book_detail_provider_test`: `saveAll(wantToRead)` clears dates but keeps rating/review; re-finishing restores them. |
| 8 | Public web finished-only, no review (US5) | ✅ Pass | Live REST checks: `public_finished_shelf` returns 27 finished rows; anon `select` on `user_books` → `[]`; anon `select=review` on the view → `column does not exist` (42703). |

**Quality gates:** `flutter analyze` → 0 issues · `flutter test` → 16 passing.

¹ The original spec listed `Rated`/`Reviewed` filter chips; these were dropped during v2 UI
work (owner request) in favour of a single funnel sheet — All / Want to Read / Reading /
Finished. Rating/review now appear for every status, so dedicated chips were redundant.

² Scenarios 3–4 (and the scan trigger in 5) exercise the camera, which the iOS simulator
does not provide. Their end-to-end logic is fully covered by `scan_flow_test`
(cache hit, API lookup, manual fallback, duplicate detection). The on-device camera scan
should be smoke-tested once the app runs on physical hardware.

## Summary

6 / 8 scenarios fully validated on simulator + DB + tests. The remaining 2 are limited
only by the simulator lacking a camera; their logic is green in the test suite and they
are pending a one-time on-device check.
