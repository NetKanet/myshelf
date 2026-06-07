# Data Model: My Shelf MVP

**Phase 1 output.** Tables, the public view, RLS policies, and state rules.

---

## Entity Relationship

```
auth.users ──1:N──> user_books ──N:1──> books
                         │
                         └── exposed (finished + safe columns, owner only) ──> public_finished_shelf (view)

app_config (1 row) ── owner_user_id ──> used by the view to scope to the profile owner
```

---

## Table: `books` (shared catalog)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, default gen_random_uuid() | |
| isbn | text | UNIQUE | nullable for manual entries without a barcode |
| title | text | NOT NULL | |
| author | text | | multiple authors joined with ", " |
| cover_url | text | | URL only — never a file (P3) |
| description | text | | |
| publisher | text | | |
| published_year | int | | |
| page_count | int | | |
| source | text | | 'google' \| 'manual' (MVP) |
| created_at | timestamptz | default now() | |

One row per ISBN; reused across users. Cover is a URL; the app shows a placeholder when
null.

---

## Table: `user_books` (per-user shelf)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, default gen_random_uuid() | |
| user_id | uuid | FK → auth.users(id) ON DELETE CASCADE | owner |
| book_id | uuid | FK → books(id) ON DELETE CASCADE | |
| status | text | NOT NULL, CHECK in ('want_to_read','reading','finished') | |
| date_started | date | | auto-filled, editable |
| date_finished | date | | auto-filled on finished, editable |
| rating | numeric(2,1) | CHECK (rating >= 0.5 AND rating <= 5) | half-star; set only while finished |
| review | text | | set only while finished; never deleted on status change |
| created_at | timestamptz | default now() | shelf add time (sort key for non-finished) |
| updated_at | timestamptz | default now() | bump on every change |

**Unique**: `(user_id, book_id)` — one shelf entry per book per user.

**Indexes**: `(user_id, status)` for shelf queries.

---

## Table: `app_config` (single row)

| Column | Type | Notes |
|--------|------|-------|
| id | int | PK, always 1 (CHECK id = 1) |
| owner_user_id | uuid | the profile owner whose finished books the public site shows |

Holds the `user_id` whose shelf the public website surfaces. Set once after the owner's
first sign-in.

---

## View: `public_finished_shelf` (public, read-only)

Selects only safe columns for the owner's finished books:

- `book.cover_url`, `book.title`, `book.author`, `book.published_year`
- `user_books.date_finished`, `user_books.rating`

Filter: `status = 'finished'` AND `user_id = (SELECT owner_user_id FROM app_config)`.
Order is applied by the website (date_finished DESC).

**Excludes** `review` and every non-finished row (FR-028). `anon` is granted `SELECT` on
this view only — not on `user_books`.

---

## RLS Policies

**books**
- `public read books`: SELECT USING (true) — catalog is non-sensitive.
- Writes via authenticated users / service.

**user_books**
- `owner full access`: ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id)
  — each user only sees/edits their own rows (FR-004a). No anon policy.

**app_config**
- SELECT for the view's needs; no anon write.

**public_finished_shelf**
- `GRANT SELECT ... TO anon;` — the website's only public read path (P2).

---

## State Transitions (status)

```
        ┌───────────────┐
        ▼               │
Want to Read ⇄ Reading ⇄ Finished
        ▲                   │
        └───────────────────┘   (any direction allowed — FR-020)
```

**Rules**:
- → Reading or Finished: auto-fill `date_started` if empty (FR-021).
- → Finished: auto-fill `date_finished` (FR-021).
- → Want to Read: clear `date_started` and `date_finished` (FR-021).
- Status change MUST NOT clear `rating`/`review`; they are retained and hidden while not
  finished, shown again if re-finished (FR-021, clarification Q3).
- `updated_at` bumps on every change.
- `rating`/`review` are editable only while `status = 'finished'` (FR-022, FR-023).

---

## Derived shelf filters

| Chip | Predicate |
|------|-----------|
| All | (none) |
| Reading | status = 'reading' |
| Finished | status = 'finished' |
| Want to Read | status = 'want_to_read' |
| Rated | rating IS NOT NULL |
| Reviewed | review IS NOT NULL |

Sort: Finished → date_finished DESC; others → created_at DESC.

---

## Validation rules

- `rating` ∈ {0.5, 1.0, …, 5.0} (half steps), nullable.
- `status` constrained by CHECK.
- A book added by scan/search defaults to `want_to_read` (FR-017).
- Manual entry without ISBN: reuse an existing catalog row matching title+author if present
  (avoid duplicate catalog entries), else insert with `source = 'manual'` (assumption,
  carried from prior behavior).

---

## Migration note

The Supabase project already contains `books` and `user_books` with `rating numeric(2,1)`,
`review`, `source`, `page_count` applied in a prior session. The MVP adds the `app_config`
table and the `public_finished_shelf` view, and revokes any anon direct-read policy on
`user_books` in favor of the view. Exact SQL is produced in `/speckit-tasks`.
