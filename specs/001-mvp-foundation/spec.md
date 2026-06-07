# Feature Specification: My Shelf MVP — Track & Share Reads

**Feature Branch**: `001-mvp-foundation`

**Created**: 2026-06-07

**Status**: Draft

**Input**: User description: "MVP foundation: Google sign-in, a single shelf of all books filtered by status/rating/review, scan an ISBN to add a book (with manual fallback), a book detail screen for status/dates/rating/review, and a public web profile that shows finished books live."

## Clarifications

### Session 2026-06-07

- Q: Should sign-in be restricted to the owner's Google account, or open to any Google account? → A: Open — any Google account may sign in; each user gets an isolated shelf via per-user access rules. The app is not publicly promoted, so this is acceptable. Consequence: the public profile MUST scope its finished-books list to the profile owner's account so other users' data never appears publicly.
- Q: Which fields of finished books are shown on the public profile? → A: Cover, title, author, finish date, and rating (stars). The review text MUST stay private and never be exposed publicly. (Hiding one column while exposing others is a column-level concern for the plan — e.g. a public view or column grants — since row-level rules alone do not hide columns.)
- Q: When a finished book is changed back to Reading or Want to Read, what happens to its rating and review? → A: Keep them stored; only hide the rating/review editor while the status is not Finished, and show them again unchanged if the book becomes Finished again. A non-finished book that has a stored rating/review still appears under the "Rated"/"Reviewed" filters.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign in with Google (Priority: P1)

Net opens the app and signs in with his Google account in one tap. The session is remembered so he doesn't sign in again every launch.

**Why this priority**: Nothing in the app can be personal or private without knowing who the user is. It is the gate for every other story and the smallest first slice.

**Independent Test**: Launch the app while signed out → complete Google sign-in → land on the shelf. Close and reopen the app → still signed in. Sign out → return to the sign-in screen.

**Acceptance Scenarios**:

1. **Given** the app is opened while signed out, **When** Net taps "Sign in with Google" and approves, **Then** he is taken to his shelf.
2. **Given** Net signed in previously, **When** he reopens the app, **Then** he goes straight to his shelf without signing in again.
3. **Given** Net is signed in, **When** he signs out, **Then** he returns to the sign-in screen and his shelf is no longer accessible.
4. **Given** sign-in is cancelled or fails, **When** the flow ends, **Then** a clear message is shown and Net stays on the sign-in screen.

---

### User Story 2 - See my shelf, filtered (Priority: P1)

Net views all his books in one list and narrows it with filter chips — by reading status, or by whether a book is rated or reviewed.

**Why this priority**: The shelf is the home surface Net returns to constantly. Combined with sign-in it already delivers value (a place to see his reading), even before adding new books.

**Independent Test**: With a known set of books in various states, open the shelf and tap each chip; confirm the visible list always matches the chip's meaning and the empty states appear when a filter has no books.

**Acceptance Scenarios**:

1. **Given** books exist in several states, **When** the shelf opens, **Then** the default "All" view lists every book with cover (or placeholder), title, and author.
2. **Given** the "All" view, **When** Net taps "Finished", **Then** only finished books show, ordered by finish date (most recent first), each showing its finish date and rating if set.
3. **Given** the "All" view, **When** Net taps "Reading" or "Want to Read", **Then** only books in that status show, ordered by date added (most recent first).
4. **Given** some books are rated, **When** Net taps "Rated", **Then** only books with a rating show.
5. **Given** some books are reviewed, **When** Net taps "Reviewed", **Then** only books with a review show.
6. **Given** any chip, **When** it is active, **Then** exactly one chip is active and it is visually distinct.
7. **Given** a filter with no matching books, **When** it is selected, **Then** a meaningful empty state is shown.

---

### User Story 3 - Add a book by scanning its ISBN (Priority: P2)

Net points the camera at a book's barcode; the app finds the book's details automatically and adds it to his shelf. If the book can't be found, he can type its title and author instead.

**Why this priority**: This is the primary way books get onto the shelf. It depends on having a shelf to land on (US2) but is the core "value-add" action of the app.

**Independent Test**: Scan a book whose ISBN is known to the catalog → its details appear and it is added. Re-scan the same book → it resolves from the local cache with no external lookup and opens the existing entry. Scan a book absent from the catalog → the manual title/author form appears and saving adds the book.

**Acceptance Scenarios**:

1. **Given** the scanner is open, **When** a barcode is detected, **Then** the app looks the ISBN up — checking its own cache first — and shows a loading state while resolving.
2. **Given** an ISBN already in the local cache, **When** it is scanned, **Then** the book resolves with no external lookup.
3. **Given** an ISBN not in the cache, **When** it is scanned and found externally, **Then** the book's details (title, author, cover, publisher, year, page count) are saved and added to the shelf.
4. **Given** an ISBN that already exists on Net's shelf, **When** it is scanned, **Then** the existing book's detail opens instead of creating a duplicate.
5. **Given** an ISBN that cannot be found anywhere, **When** lookup fails, **Then** a manual entry form (title + author) is offered and saving adds the book to the shelf and the catalog.
6. **Given** a newly added book, **When** it is created, **Then** its default status is "Want to Read".
7. **Given** the camera permission is denied, **When** Net opens the scanner, **Then** an explanation with a path to device settings is shown instead of a broken camera.

---

### User Story 4 - Manage a book's detail (Priority: P2)

Net opens a book to see its full information and to record where he is with it: change status, set start/finish dates, give a rating, write a review, or remove it from the shelf.

**Why this priority**: Tracking progress and opinions is the point of a personal shelf. It depends on books existing (US3) and feeds the shelf filters (US2) and the public web (US5).

**Independent Test**: Open a book, move it through each status and confirm date behavior, set a half-star rating and a review, save, reopen and confirm everything persisted; delete a book and confirm it leaves the shelf.

**Acceptance Scenarios**:

1. **Given** a book detail, **When** it opens, **Then** cover (or placeholder), title, author, publisher, year, page count, and a collapsible description are shown.
2. **Given** any status, **When** Net changes status in any direction, **Then** the change is allowed (e.g. Finished → Reading).
3. **Given** a change to "Reading" or "Finished", **When** there is no start date yet, **Then** the start date auto-fills with today and remains editable.
4. **Given** a change to "Finished", **When** it is set, **Then** the finish date auto-fills with today and remains editable.
5. **Given** a change back to "Want to Read", **When** it is set, **Then** start and finish dates are cleared.
6. **Given** a finished book, **When** Net sets a rating, **Then** ratings of whole and half values (0.5–5) can be chosen and cleared. Rating and review are available only when status is Finished.
7. **Given** a finished book, **When** Net writes or edits a review and saves, **Then** the review is stored and shown on reopen. The review field is available only when status is Finished.
8. **Given** unsaved edits, **When** Net leaves the screen, **Then** he is warned before losing them.
9. **Given** a finished book with a rating and review, **When** Net changes it back to Reading or Want to Read, **Then** the rating/review editor is hidden but the values are kept, and they reappear unchanged if the book is set to Finished again.
10. **Given** a book, **When** Net deletes it after confirming, **Then** it is removed from his shelf.

---

### User Story 5 - Public profile shows finished books live (Priority: P3)

Visitors to Net's public profile site see the books he has finished, updated automatically whenever he marks something finished — no redeploy needed.

**Why this priority**: This closes the loop that motivated the app (no more hand-editing the website), but it depends on finished books existing first (US4).

**Independent Test**: Mark a book finished in the app, refresh the public site, and confirm it appears with correct data and ordering; confirm an unauthenticated request can retrieve only finished books.

**Acceptance Scenarios**:

1. **Given** a book marked finished, **When** the public site is refreshed, **Then** the book appears without any redeploy.
2. **Given** the public list, **When** it renders, **Then** books are ordered by finish date (most recent first) and show cover, title, author, finish date, and rating — but never the review text.
3. **Given** an unauthenticated visitor, **When** data is fetched, **Then** only finished books are returned — never reading or want-to-read entries.
4. **Given** more than one user has signed into the app, **When** the public profile is fetched, **Then** it shows only the profile owner's finished books, never another user's.

---

### Edge Cases

- A book with no cover from any source → a placeholder is shown wherever the book appears.
- An ISBN that is malformed or fails checksum on scan → handled gracefully (rejected or routed to manual entry), never a crash.
- The external catalog is slow or unreachable on a cache miss → the lookup is time-bounded and falls through to manual entry rather than hanging.
- Switching filter chips rapidly → the list stays consistent with the active chip, no stale results.
- Average/derived displays when a book has no rating or review → those simply don't appear; no error.
- Sign-in token expires between launches → Net is returned to sign-in cleanly.

## Requirements *(mandatory)*

### Functional Requirements

**Authentication**

- **FR-001**: The system MUST let any user sign in with Google; sign-in is not restricted to a specific account.
- **FR-002**: The system MUST NOT offer public registration or email/password sign-in.
- **FR-003**: The system MUST keep the user signed in across app restarts and provide a sign-out action.
- **FR-004**: The system MUST show a clear message when sign-in is cancelled or fails.
- **FR-004a**: Each signed-in user MUST see and modify only their own shelf; one user's books MUST NOT be visible to or editable by another user.

**Shelf**

- **FR-005**: The system MUST present all of the user's books in a single list.
- **FR-006**: The system MUST provide filter chips: All, Reading, Finished, Want to Read, Rated, Reviewed, with exactly one active at a time and "All" as default.
- **FR-007**: "Rated" MUST show books that have a rating; "Reviewed" MUST show books that have a review.
- **FR-008**: Finished books MUST be ordered by finish date (most recent first); other status filters MUST be ordered by date added (most recent first).
- **FR-009**: Each book row MUST show cover (or placeholder), title, author, and — where present — finish date and rating.
- **FR-010**: Each filter with no matching books MUST show a meaningful empty state.

**Add a book (scan + manual)**

- **FR-011**: The system MUST provide an easily reachable way to scan an ISBN barcode with the camera.
- **FR-012**: On scan, the system MUST resolve the ISBN cache-first, contacting an external catalog only on a cache miss, and MUST show a loading state while resolving.
- **FR-013**: Re-scanning a known ISBN MUST NOT trigger an external lookup.
- **FR-014**: A resolved book MUST capture title, author, cover URL, publisher, published year, and page count where available.
- **FR-015**: Scanning an ISBN already on the user's shelf MUST open the existing book rather than create a duplicate.
- **FR-016**: When an ISBN cannot be resolved, the system MUST offer manual entry (title + author) and persist the result to both the catalog and the shelf.
- **FR-017**: Newly added books MUST default to status "Want to Read".
- **FR-018**: When camera permission is denied, the system MUST explain and link to device settings.

**Book detail**

- **FR-019**: The system MUST show cover (or placeholder), title, author, publisher, year, page count, and a collapsible description.
- **FR-020**: The system MUST allow status changes in any direction among Want to Read, Reading, Finished.
- **FR-021**: Changing to Reading or Finished MUST auto-fill the start date (if empty); changing to Finished MUST auto-fill the finish date; changing to Want to Read MUST clear both dates. All dates MUST remain editable. A status change MUST NOT clear an existing rating or review — they are retained and simply hidden from editing while the status is not Finished.
- **FR-022**: The system MUST allow setting and clearing a rating in half-star steps from 0.5 to 5, available only when the book's status is Finished.
- **FR-023**: The system MUST allow writing, editing, and clearing a free-text review, available only when the book's status is Finished.
- **FR-024**: The system MUST warn before discarding unsaved edits.
- **FR-025**: The system MUST allow deleting a book from the shelf after confirmation.

**Public web**

- **FR-026**: The public profile MUST fetch finished books live, with no redeploy when the shelf changes.
- **FR-027**: The public list MUST be ordered by finish date (most recent first).
- **FR-028**: Unauthenticated access MUST be limited to finished books only, and to the fields cover, title, author, finish date, and rating. The review text MUST NOT be exposed publicly, and no non-finished data may be exposed.
- **FR-028a**: The public profile MUST scope its list to the profile owner's account, so that finished books belonging to other signed-in users never appear on the owner's public profile.

**Cross-cutting**

- **FR-029**: Cover images MUST be referenced by URL only; image files MUST NOT be downloaded or stored.
- **FR-030**: The whole feature MUST operate within the free tier of every service used.

### Key Entities

- **Book (catalog entry)**: A shared, public record of a title — ISBN, title, author, cover URL, description, publisher, published year, page count, and the source it came from. One entry per ISBN, reused across scans.
- **Shelf entry (user's book)**: The user's relationship to a Book — reading status, start date, finish date, rating, and review. Exactly one per book for the user. Drives shelf filters and the public list.
- **Reading status**: One of Want to Read, Reading, Finished.
- **Derived filters**: "Rated" (has a rating) and "Reviewed" (has a review) are computed from the shelf entry, not stored as statuses.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Net can sign in and reach his shelf in one tap, and stays signed in across restarts.
- **SC-002**: From a barcode to a saved book on the shelf takes no more than a few seconds for a catalog hit.
- **SC-003**: Re-scanning a previously added book resolves with no external lookup.
- **SC-004**: A book that exists in the catalog is found automatically; manual entry is needed only when it is genuinely absent.
- **SC-005**: Net can filter his shelf to any of the six chip views in one tap, with results always matching the filter.
- **SC-006**: A rating set in half-star steps (e.g. 4.5) persists and displays correctly on the shelf and detail.
- **SC-007**: Marking a book finished makes it appear on the public site after a refresh, with no redeploy.
- **SC-008**: An unauthenticated request can retrieve only finished books and nothing else.

## Assumptions

- Primarily a personal app for Net, but sign-in is open to any Google account; each user's
  data is isolated. No sharing or social features. The public profile shows only the
  owner's finished books.
- Google account is available for sign-in; one provider is sufficient for the MVP.
- A free, key-less external catalog can supply book details for most scanned ISBNs; books it lacks are handled by manual entry.
- Statuses are Want to Read, Reading, Finished; "Rated"/"Reviewed" are derived.
- Ratings use half-star granularity (0.5–5); reviews are free text.
- The public profile site can be modified to fetch live instead of using hard-coded data.
- The backend already provides per-user data isolation and a public-read rule limited to finished books.

## Out of Scope

- Keyword search and an in-app discovery surface.
- A secondary catalog fallback beyond the primary source (added in a later feature).
- A profile/statistics dashboard.
- A multi-destination bottom navigation bar (the MVP needs only the shelf plus a way to scan).
- Additional sign-in providers (Facebook, Apple), reading progress, sharing, offline support, bestsellers, and categories.

## Dependencies

- A backend providing authentication, per-user storage, a public-read rule limited to finished books, and a catalog table for cached book data.
- A device camera for barcode scanning.
- An external book catalog reachable for ISBN lookups on cache misses.
- The public profile website, editable to consume live data.
