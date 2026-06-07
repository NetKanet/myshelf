# Quickstart & Validation: My Shelf MVP

How to run the app and prove the feature works end-to-end. Implementation details live in
`tasks.md`; data shapes in `data-model.md`; interfaces in `contracts/`.

## Prerequisites

- Flutter (stable) + Xcode (iOS simulator) and/or Android SDK.
- A Supabase project with `books`, `user_books`, `app_config`, and the
  `public_finished_shelf` view (see `data-model.md`).
- Google sign-in configured (see `research.md` R1): OAuth client IDs in Google Cloud,
  Google provider enabled in Supabase, iOS URL scheme added.
- `app/lib/core/config/supabase_config.dart` with the Supabase URL + anon key (gitignored).

## Run

```bash
cd app
flutter pub get
flutter run            # pick the iOS simulator or an Android device
```

## Validation scenarios

Each maps to a user story / success criterion in `spec.md`.

1. **Sign in (US1 / SC-001)**: Launch signed out → tap "Sign in with Google" → land on the
   shelf. Kill and relaunch → still signed in. Sign out → back to sign-in.

2. **Shelf filters (US2 / SC-005)**: With books in mixed states, open the shelf; tap each
   chip (All / Reading / Finished / Want to Read / Rated / Reviewed) and confirm the list
   matches. Confirm empty states for filters with no matches.

3. **Scan a known book (US3 / SC-002)**: Scan a book with a catalog ISBN → details appear
   and it lands on the shelf as "Want to Read" within a few seconds.

4. **Cache hit (US3 / SC-003)**: Re-scan the same ISBN → it resolves instantly and opens
   the existing entry; confirm no Google Books call is made (check logs / network).

5. **Manual fallback (US3 / SC-004)**: Scan/enter an ISBN absent from the catalog → manual
   title+author form appears → saving adds the book.

6. **Detail, dates, rating, review (US4 / SC-006)**: Open a book → set Finished → start &
   finish dates auto-fill → set a half-star rating (e.g. 4.5) and a review → Save → reopen
   and confirm both persisted; confirm 4.5 shows on the shelf card.

7. **Un-finish keeps rating/review (US4, clarification Q3)**: Change the finished book back
   to Reading → rating/review editor hides but data is kept → set Finished again → values
   reappear unchanged.

8. **Public web shows finished only (US5 / SC-007, SC-008)**: Mark a book finished → load
   the profile site → the book appears with cover/title/author/finish date/rating, **no
   review**. Run the negative check in `contracts/public-web-read.md`: an anon query on
   `user_books` returns nothing.

## Quality gates

```bash
cd app
flutter analyze        # expect: zero warnings
flutter test           # expect: all tests pass
```

Done when every validation scenario passes and both gates are green.
