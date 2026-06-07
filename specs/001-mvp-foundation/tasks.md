---
description: "Task list for My Shelf MVP — Track & Share Reads"
---

# Tasks: My Shelf MVP — Track & Share Reads

**Input**: Design documents from `/specs/001-mvp-foundation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Branch**: `001-mvp-foundation`

**Tests**: Included — the constitution (P5) requires unit tests for services/providers and
integration tests for critical flows.

**Organization**: Tasks are grouped by user story (US1–US5) so each can be implemented and
verified independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[Story]**: US1–US5 (user-story phases only)
- File paths are relative to repo root; the Flutter app lives in `app/`

## Path Conventions

- Mobile app: `app/lib/...`, tests in `app/test/...`
- Public website change: `admyhusky-dev-template/data.js`
- Backend (Supabase): applied via dashboard/SQL per `data-model.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the Flutter project and wire core dependencies.

- [X] T001 Run `flutter create app` at repo root and confirm it builds on the iOS simulator
- [X] T002 Add dependencies to `app/pubspec.yaml`: supabase_flutter, flutter_riverpod, go_router, google_sign_in, mobile_scanner, cached_network_image, http, intl; dev: mocktail, flutter_lints
- [X] T003 [P] Configure `app/analysis_options.yaml` (flutter_lints, zero-warning target)
- [X] T004 Create `app/lib/core/config/supabase_config.dart` with SUPABASE_URL + SUPABASE_ANON_KEY placeholders and add it to `.gitignore`
- [X] T005 [P] Create `app/lib/core/theme/app_theme.dart` with the app color palette and typography
- [X] T006 Initialize Supabase and wrap the app in `ProviderScope` in `app/lib/main.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema, models, services, and routing that every story needs.

**⚠️ CRITICAL**: No user-story work can begin until this phase is complete.

- [X] T007 Apply the Supabase migration per `data-model.md`: ensure `books`/`user_books` columns, create `app_config` table, create the `public_finished_shelf` view, set RLS (`owner full access` on user_books, public read on books), GRANT SELECT on the view to `anon`, and ensure `anon` has NO direct read on `user_books`
- [X] T008 [P] Create `Book` model in `app/lib/models/book.dart` (fromJson/toJson; normalize cover `http://`→`https://`)
- [X] T009 [P] Create `UserBook` model in `app/lib/models/user_book.dart` (ReadingStatus enum, dates, `rating` double?, `review` String?, copyWith with clear flags)
- [X] T010 Create `SupabaseService` in `app/lib/services/supabase_service.dart` (books + user_books CRUD, watch/get by user, dedup helpers)
- [X] T011 [P] Create `GoogleBooksService` in `app/lib/services/google_books_service.dart` per `contracts/google-books-lookup.md`
- [X] T012 Set up GoRouter in `app/lib/core/router/app_router.dart` with routes `/login`, `/shelf`, `/scan`, `/book/:id` and an auth-redirect guard skeleton

**Checkpoint**: Foundation ready — user stories can begin.

---

## Phase 3: User Story 1 — Sign in with Google (Priority: P1) 🎯 MVP

**Goal**: The owner signs in with Google in one tap; the session persists; sign-out works.

**Independent Test**: Launch signed out → Google sign-in → land on shelf; relaunch → still in; sign out → back to sign-in.

### Tests

- [X] T013 [P] [US1] Unit test `AuthProvider` in `app/test/features/auth/auth_provider_test.dart` (sign-in success, failure, session state, sign-out)

### Implementation

- [X] T014 [US1] **Manual setup**: configure Google OAuth per `research.md` R1 — create iOS/Android/Web OAuth client IDs in Google Cloud, enable Google provider in Supabase with the Web client ID + secret, add the reversed-client-ID URL scheme to `app/ios/Runner/Info.plist`
- [X] T015 [US1] Create `AuthProvider` in `app/lib/features/auth/auth_provider.dart` (google_sign_in → `supabase.auth.signInWithIdToken`, auth-state stream, signOut)
- [X] T016 [US1] Build Auth screen in `app/lib/features/auth/auth_screen.dart` ("Sign in with Google" button, loading, error display, mascot)
- [X] T017 [US1] Implement the auth redirect in `app/lib/core/router/app_router.dart` (unauthenticated → `/login`, authenticated → `/shelf`)

**Checkpoint**: Sign-in works end-to-end and gates the rest of the app.

---

## Phase 4: User Story 2 — See my shelf, filtered (Priority: P1)

**Goal**: All books in one list with filter chips (All/Reading/Finished/Want to Read/Rated/Reviewed); correct sort and empty states.

**Independent Test**: With mixed-state books, tap each chip and confirm the list and sort; confirm empty states.

### Tests

- [X] T018 [P] [US2] Unit test `ShelfProvider` in `app/test/features/shelf/shelf_provider_test.dart` (each chip filter, finished sort by date_finished, others by created_at, empty state)

### Implementation

- [X] T019 [US2] Create `ShelfProvider` in `app/lib/features/shelf/shelf_provider.dart` (stream the user's user_books joined with books; filter by active chip; sort per FR-008)
- [X] T020 [US2] Build Shelf screen in `app/lib/features/shelf/shelf_screen.dart` (filter-chip row with single active chip, book list, per-filter empty states, header with sign-out)
- [X] T021 [P] [US2] Create `BookCard` widget in `app/lib/features/shelf/widgets/book_card.dart` (cached cover or placeholder, title, author, finish-date badge, mini half-star rating)
- [X] T022 [US2] Add the scan entry point (FAB) on the Shelf that navigates to `/scan`

**Checkpoint**: Shelf is usable and reactive to data.

---

## Phase 5: User Story 3 — Add a book by scanning its ISBN (Priority: P2)

**Goal**: Scan a barcode → cache-first lookup → add to shelf; duplicate opens existing; manual fallback when not found.

**Independent Test**: Scan known ISBN → added; re-scan → cache hit (no external call) → existing detail; scan unknown → manual form adds it.

### Tests

- [ ] T023 [P] [US3] Integration test scan flow in `app/test/features/scan/scan_flow_test.dart` (cache hit, API lookup, manual fallback, duplicate detection)

### Implementation

- [ ] T024 [US3] Create `ScanProvider` in `app/lib/features/scan/scan_provider.dart` (ISBN → check books cache → check shelf for duplicate → GoogleBooksService → insert book + user_book as `want_to_read`)
- [ ] T025 [US3] Build Scan screen in `app/lib/features/scan/scan_screen.dart` (mobile_scanner viewfinder, detected-ISBN + loading state, camera-permission-denied message with settings link)
- [ ] T026 [US3] Build manual input dialog in `app/lib/features/scan/widgets/manual_input_dialog.dart` (title + author; reuse existing catalog row by title+author; `source='manual'`)

**Checkpoint**: Books can be added by scan or manually; no duplicates.

---

## Phase 6: User Story 4 — Manage a book's detail (Priority: P2)

**Goal**: View info; change status any direction; auto dates; half-star rating + review (Finished-only, retained on un-finish); delete.

**Independent Test**: Move a book through statuses (confirm date behavior), set 4.5 + review while Finished, save, reopen → persisted; un-finish → editor hidden but values kept; delete → removed.

### Tests

- [ ] T027 [P] [US4] Unit test `BookDetailProvider` in `app/test/features/book_detail/book_detail_provider_test.dart` (status transitions all directions, date auto-fill/clear, rating/review save, rating/review retained on un-finish, delete)

### Implementation

- [ ] T028 [US4] Create `BookDetailProvider` in `app/lib/features/book_detail/book_detail_provider.dart` (load by id, `saveAll` for status/dates/rating/review, delete)
- [ ] T029 [US4] Build Book Detail screen in `app/lib/features/book_detail/book_detail_screen.dart` (cover/placeholder, info chips, collapsible description, status selector, date pickers, half-star rating + review **shown only when Finished**, Save button, unsaved-changes dialog)
- [ ] T030 [US4] Implement status-transition logic in the detail/provider (auto-fill/clear dates per FR-021; never clear rating/review on status change)
- [ ] T031 [P] [US4] Build delete-confirm dialog in `app/lib/features/book_detail/widgets/delete_confirm_dialog.dart`

**Checkpoint**: Full per-book tracking works and feeds the shelf filters.

---

## Phase 7: User Story 5 — Public profile shows finished books live (Priority: P3)

**Goal**: The website reads the owner's finished books live (cover/title/author/finish-date/rating, no review).

**Independent Test**: Mark finished → refresh site → appears with correct fields/order; anon query on `user_books` returns nothing.

### Implementation

- [ ] T032 [US5] Set `app_config.owner_user_id` to Net's `user_id` in Supabase (after his first sign-in)
- [ ] T033 [US5] Update `admyhusky-dev-template/data.js` to fetch `public_finished_shelf` per `contracts/public-web-read.md` (order by date_finished desc) and render grouped by year
- [ ] T034 [US5] Verify guarantees in `contracts/public-web-read.md`: view returns finished + owner-scoped + safe columns only; anon `user_books` query returns nothing; `review` never present

**Checkpoint**: The scan→web loop is closed with no redeploy.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T035 Run `flutter analyze` in `app/` — resolve to zero warnings
- [ ] T036 Run `flutter test` in `app/` — all tests pass
- [ ] T037 Run the 8 `quickstart.md` validation scenarios on the iOS simulator
- [ ] T038 [P] Update `CLAUDE.md` and `docs/prd.md` to mark the MVP complete (P6 Living Documentation)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** → **Foundational (P2)** → **User Stories (P3–P7)** → **Polish (P8)**
- US1 (auth) gates the app; US2–US4 build on the foundation and US1's session
- US5 (web) depends on US4 producing finished books and US1 establishing the owner id

### User Story Dependencies

- US1 (P1): after Foundational — no dependency on other stories
- US2 (P1): after Foundational — needs a signed-in session (US1) to load the user's shelf
- US3 (P2): after US2 — scan results land on the shelf and open the detail
- US4 (P2): after US3 — needs books to exist; feeds US2 filters and US5
- US5 (P3): after US4 — needs finished books and the owner id from US1

### Within Each User Story

- Tests first (write, see fail), then models → services → providers → screens → integration

---

## Parallel Opportunities

| Phase | Parallel tasks | Reason |
|-------|----------------|--------|
| Setup | T003, T005 | different files |
| Foundational | T008, T009, T011 | models + Google service, independent files |
| US1 | T013 (test) alongside T015 scaffolding | different files |
| US2 | T021 (BookCard) with T018 (test) | different files |
| US4 | T031 (dialog), T027 (test) | different files |

---

## Implementation Strategy

1. **MVP slice = US1 + US2**: sign in and see the shelf (even empty) — the app is usable.
2. **Core value = US3 + US4**: scan to add, track status/rating/review — the app delivers its purpose.
3. **Close the loop = US5**: the website shows finished books live.
4. **Ship = Phase 8**: analyze clean, tests pass, quickstart validated on device, docs updated.
