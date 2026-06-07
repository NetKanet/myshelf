# Contract: Google Books ISBN Lookup (app → Google Books)

Called by the app **only on a cache miss** (the `books` table is checked first, FR-012/013).

## Request

```
GET https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}
```

- No API key required for this read volume (free tier, P3).
- `{isbn}` is the normalized digits of the scanned/entered barcode.
- The call is wrapped with a timeout; failure falls through to manual entry (FR-016, P3).

## Response handling

Use the first item in `items[]`; from its `volumeInfo` map to the `books` shape:

| books field | source |
|-------------|--------|
| isbn | the queried ISBN |
| title | `volumeInfo.title` (fallback "Unknown Title") |
| author | `volumeInfo.authors` joined with ", " |
| cover_url | `volumeInfo.imageLinks.thumbnail`, with `http://` → `https://` |
| description | `volumeInfo.description` |
| publisher | `volumeInfo.publisher` |
| published_year | first 4 chars of `volumeInfo.publishedDate` |
| page_count | `volumeInfo.pageCount` |
| source | `'google'` |

## Outcomes

- `totalItems == 0` or empty `items` → treat as **not found** → offer manual entry.
- HTTP non-200 / timeout / network error → **not found path** (fault-isolated, never
  crashes the flow).
- On success → upsert into `books` (warm the cache) and proceed to add to the shelf.

## Cache guarantee

A second lookup of the same ISBN is served from `books` and makes **no** request to this
endpoint (FR-013, SC-003).
