# Performance & lazy-loading design

My Shelf is read-heavy (a long, image-rich shelf) on a free tier. The shelf must stay
snappy and cheap as the library grows, so loading is **on-demand**: render and fetch only
what the user is actually looking at.

## Principles

1. **Don't build what isn't visible.** Lists render lazily; only rows near the viewport
   are built.
2. **Don't download what isn't seen.** Cover images load when their row scrolls into view,
   not up front.
3. **Don't decode bigger than you draw.** Cover bitmaps are decoded near display size, not
   full resolution.
4. **Pay for detail on demand.** The full description / large cover loads on the detail
   screen, not in the list.

## What the app does today

| Concern | Mechanism | Status |
|---------|-----------|--------|
| List rows | `ListView.builder` builds only visible (+small cache extent) rows | ✅ |
| Cover download | `CachedNetworkImage` fetches on first build (i.e. when scrolled into view) and caches to disk + memory | ✅ |
| Cover memory | `memCacheWidth` / `maxWidthDiskCache` = display width × devicePixelRatio, so a 1000px cover is not decoded for a 56px thumbnail | ✅ |
| Hotlink-protected hosts | a browser `User-Agent` header is sent so bookstore covers load | ✅ |

## What the public web does today

- Cover `<img>` tags use `loading="lazy"` — off-screen covers aren't requested.
- Each year shows `previewLimit` covers (3) behind a **Show more** button, so a long
  history doesn't render hundreds of images at once.
- Data is read once from the `public_finished_shelf` view (safe columns only).

## Future: pagination (when the library is large)

The shelf metadata query currently fetches **all** of the owner's `user_books` in one
request. For tens–low hundreds of books this is a few KB and is intentionally kept simple
(YAGNI). When a single shelf realistically exceeds a few hundred books, switch to keyset
pagination:

- Fetch a page (e.g. 30 rows) ordered by `date_finished` / `created_at`, then fetch the
  next page using `.range()` (or a keyset cursor) when the list nears its end
  (`ScrollController` threshold or a sentinel item).
- Keep filters server-side so a filtered view paginates too.
- The grouped-by-year section headers are derived client-side from the loaded pages.

This is documented but **not implemented** — adding it before it's needed would add
state/complexity for no user-visible benefit at the current scale.

## Trigger to revisit

Implement pagination + thumbnail variants once any of these is true:

- A shelf exceeds ~300 books, **or**
- First-paint of the shelf exceeds ~1s on a mid device, **or**
- Cover bandwidth becomes a free-tier concern.
