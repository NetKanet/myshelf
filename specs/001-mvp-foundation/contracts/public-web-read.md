# Contract: Public Web Read (profile website → Supabase)

The public profile site (`admyhusky.dev`) reads the owner's finished books with the
anon key, through the `public_finished_shelf` view only.

## Request

```
GET {SUPABASE_URL}/rest/v1/public_finished_shelf?select=*&order=date_finished.desc
Headers:
  apikey: {SUPABASE_ANON_KEY}
```

- No auth token (anonymous).
- Ordering by `date_finished` descending (FR-027) is requested by the client.

## Response (200)

Array of finished books, owner-scoped, safe columns only:

```json
[
  {
    "cover_url": "https://books.google.com/.../cover.jpg",
    "title": "Project Hail Mary",
    "author": "Andy Weir",
    "published_year": 2021,
    "date_finished": "2026-05-30",
    "rating": 4.5
  }
]
```

## Guarantees (enforced server-side)

- Only rows with `status = 'finished'` appear (FR-028).
- Only the profile owner's rows appear — never another signed-in user's (FR-028a).
- `review` is never present in the payload (FR-028).
- No non-finished data (reading / want-to-read) is reachable via this key.

## Negative checks (must hold)

- `GET {SUPABASE_URL}/rest/v1/user_books?...` with the anon key MUST NOT return rows
  (anon has no read policy on the base table).
- No query against the view can surface `review` or non-finished rows.
