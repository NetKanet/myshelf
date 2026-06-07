# My Shelf — Product Requirements Document

**Owner:** Net (admyhusky)
**Version:** 2.0
**Date:** 2026-06-07

> v2.0 รวม PRD เดิม (MVP) เข้ากับ PRD "Discover & Scan" — เป็นเอกสารฉบับเดียว
> **อ่าน §0 ก่อนเริ่ม implement**

---

## Implementation status (อัปเดต 2026-06-08)

**Mobile app (Flutter) — ✅ เสร็จ + ผ่าน v2 UI polish**

- Google sign-in → Supabase, auth redirect (US1) ✅
- Combined shelf จัดกลุ่มตามปี + funnel filter sheet (All/Want to Read/Reading/Finished) (US2) ✅
- Scan ISBN cache-first → Google Books → manual entry แบบเต็มหน้า (US3) ✅
- Book detail: status/dates, rating + review **ทุกสถานะ**, delete (US4) ✅
- v2 polish: bottom nav (Shelf/+/Profile), gradient covers + deco bubbles, profile dashboard
  (headline numbers, status breakdown, กราฟแท่งรายเดือน + กราฟเส้น "By month, per year"),
  **dark mode เต็มระบบ** (settings toggle, การ์ด/sheet/input ตามธีม, ปุ่ม Save โทนคอรัล)
- `flutter analyze` 0 issues, `flutter test` 16 ผ่าน (T035/T036) ✅

**เหลือ — public web profile (US5) + ปิดงาน**

- `app_config.owner_user_id` ยังไม่ตั้ง (T032)
- `admyhusky-dev-template/data.js` ยังไม่ wire เข้า view `public_finished_shelf` (T033)
- ตรวจ privacy guarantees ของ view (T034)
- รัน 8 quickstart scenario บน simulator (T037)

---

## 0. Notes for the implementer (อ่านก่อน)

- โปรเจกต์นี้มีอยู่แล้ว ใช้ **Supabase เป็น backend หลัก** (Postgres + Auth) ไม่มี server แยก
- **Frontend = Flutter** อยู่ใน `app/` — ทำตาม convention และโครงไฟล์เดิม **ห้ามเปลี่ยน stack**
- ข้อจำกัดเหนือทุกอย่าง: **ต้องอยู่ใน free tier** ของ Supabase และ external API ทุกตัว
- ทำเป็น **phase ตามลำดับใน §8** ทดสอบทีละ phase
- **Cache-first** — point lookup (scan/ISBN) เช็ค `books` ของเราก่อนเสมอ เจอแล้วจบ ไม่แตะ external API
- **เก็บแค่ cover_url** ห้ามดาวน์โหลดไฟล์ภาพมาเก็บ Supabase Storage
- API calls ตอนนี้เรียกตรงจาก Flutter (Google Books ไม่ต้อง key); อนาคตย้ายไป Edge Function เมื่อต้องซ่อน key/คุม rate

---

## 1. Overview

My Shelf คือ personal digital bookshelf app สำหรับ Net โดยเฉพาะ ใช้ scan ISBN เพิ่มหนังสือ, track สถานะการอ่าน + rating + review, และ sync ขึ้น Supabase อัตโนมัติ — เพื่อให้หน้าเว็บ `admyhusky.dev` ดึงข้อมูลหนังสือแบบ live โดยไม่ต้อง hardcode หรือ deploy ทุกครั้งที่อ่านจบ

### ปัญหาที่แก้

| ปัญหาเดิม | วิธีแก้ใหม่ |
|-----------|------------|
| หนังสือที่อ่านอยู่ใน `data.js` hardcoded | Supabase DB → เว็บดึง live |
| อัปเดตต้องแก้ไฟล์ + git push + deploy | กด Mark as Finished ในแอพ → เว็บอัปเดตทันที |
| จำไม่ได้ว่าเคยอ่านอะไรไปบ้าง | Digital shelf พร้อม history ทุกปี |
| ไม่มี mobile UX สำหรับเพิ่มหนังสือ | Scan ISBN barcode จากปก → ข้อมูลครบทันที |

---

## 2. Tech Stack

| Layer | Tech | เหตุผล |
|-------|------|--------|
| Mobile App | Flutter (Dart) | Net กำลัง learn อยู่, ใช้กับ NextNet แล้ว |
| Database + Auth + API | Supabase (PostgreSQL) | ใช้กับ NextNet แล้ว, มี REST API ฟรี |
| ISBN Lookup (หลัก) | Google Books API | ฟรี, ไม่ต้อง key สำหรับ read, ข้อมูลครบ |
| ISBN Lookup (fallback) | Open Library API | ฟรี, ไม่ต้อง key, ครอบคลุมเล่มที่ Google ไม่มี |
| ISBN Scanner | `mobile_scanner` (Flutter) | รองรับ iOS + Android |
| Book Cover Cache | `cached_network_image` | ไม่โหลดซ้ำ, smooth UX |
| Web Integration | Supabase REST (fetch) | แก้ `data.js` → ดึง live แทน hardcode |
| Routing | GoRouter | ใช้กับ NextNet แล้ว |
| State Management | Riverpod | Simple, compile-safe |

### Project ที่เกี่ยวข้อง
- **Mobile app:** repo นี้ (`NetKanet/myshelf`) — Flutter ใน `app/`
- **Web profile:** `admyhusky-dev-template` — แก้ `data.js` ให้ fetch Supabase
- **Supabase:** project `myshelf` (`REDACTED`, ap-southeast-2) แยกจาก NextNet

---

## 3. Navigation & Features

### Bottom Nav (3 tabs)

```
├── [Shelf]    → หน้าหลัก: 3 tabs (Reading / Finished / Want to Read)
├── [+]        → Bottom sheet popup: Scan ISBN / Search / Add manually
└── [Profile]  → Dashboard: stats + recent reviews
```

> **ตัดสินใจแล้ว:** ไม่มี Discover page, ไม่มี Bestsellers (NYT), ไม่มี Friends

### Feature List

| # | Feature | รายละเอียด |
|---|---------|------------|
| 1 | Scan ISBN | camera → barcode → fallback chain (cache → Google → Open Library → manual) |
| 2 | Search | keyword (Google Books live) หรือ ISBN (fallback chain) |
| 3 | Add manually | กรอก title + author กรณีหาไม่เจอ → `source='manual'` |
| 4 | Reading status | 3 states: Want to Read / Reading / Finished (เปลี่ยนอิสระทุกทิศ) |
| 5 | Dates | auto-fill date_started/date_finished ตาม status |
| 6 | Rating | 0.5–5 ดาว ครึ่งดาวได้ (nullable) — **โผล่เฉพาะตอน Finished** |
| 7 | Review | personal note/review (nullable) — **โผล่เฉพาะตอน Finished** |
| 8 | My Shelf | หนังสือรวม + filter chips |
| 9 | Book detail | cover, info, status, rating, review, tap-to-change cover |
| 10 | Profile | stats (counts, avg rating) + recent reviews |
| 11 | Web sync | เว็บดึง finished books จาก Supabase live |

### Future (ไม่ทำตอนนี้)
- เพิ่ม provider login อื่น (Facebook, Apple ID) — Gmail เป็นหลักอยู่แล้ว
- Reading progress (page %/number)
- Share to social
- Reading stats (pages/month)
- Offline support

---

## 4. Database Schema

> Supabase project `myshelf` — แยกจาก NextNet

### Table: `books` (catalog กลาง)

```sql
CREATE TABLE books (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  isbn           TEXT UNIQUE,
  title          TEXT NOT NULL,
  author         TEXT,
  cover_url      TEXT,
  description    TEXT,
  publisher      TEXT,
  published_year INT,
  page_count     INT,
  source         TEXT,           -- 'google' | 'openlib' | 'manual'
  created_at     TIMESTAMPTZ DEFAULT now()
);
```

**หน้าที่:** public catalog — scan เล่มเดิมซ้ำดึงจาก cache ไม่ยิง API ใหม่

### Table: `user_books` (shelf ส่วนตัว)

```sql
CREATE TABLE user_books (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id        UUID REFERENCES books(id) ON DELETE CASCADE,
  status         TEXT NOT NULL CHECK (status IN ('want_to_read', 'reading', 'finished')),
  date_started   DATE,
  date_finished  DATE,
  rating         NUMERIC(2,1) CHECK (rating >= 0.5 AND rating <= 5),  -- half-star
  review         TEXT,
  created_at     TIMESTAMPTZ DEFAULT now(),
  updated_at     TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, book_id)
);
```

> **Status migration:** schema นี้ตรงกับ DB จริง ณ 2026-06-07 — `rating`, `review`, `source`, `page_count` applied แล้ว

### RLS Policy

```sql
-- books: อ่านได้ทุกคน
CREATE POLICY "public read books" ON books FOR SELECT USING (true);

-- user_books: public อ่านได้เฉพาะ finished (สำหรับ web)
CREATE POLICY "public read finished books"
  ON user_books FOR SELECT USING (status = 'finished');

-- user_books: เขียนได้เฉพาะ user ตัวเอง
CREATE POLICY "owner full access"
  ON user_books FOR ALL USING (auth.uid() = user_id);
```

> Schema/migration ฉบับเต็มดูที่ [`specs/001-phase1-foundation/data-model.md`](../specs/001-phase1-foundation/data-model.md)

---

## 5. API Flow

### ISBN Fallback Chain

```
[Camera scan / พิมพ์ ISBN]
        ↓
[normalize ISBN]
        ↓
1. SELECT * FROM books WHERE isbn = ?     ← cache hit → จบ ไม่ยิง external
        ↓ miss
2. GET googleapis.com/books/v1/volumes?q=isbn:{ISBN}
        ↓ เจอ → upsert books(source='google') → จบ
        ↓ ไม่เจอ
3. GET openlibrary.org/api/books?bibkeys=ISBN:{ISBN}&format=json&jscmd=data
        ↓ เจอ → upsert books(source='openlib') → จบ
        ↓ ไม่เจอ
4. Manual input (title + author) → upsert books(source='manual')
        ↓
[INSERT user_books(user_id, book_id, status='want_to_read')]
        ↓
[Show Book Detail]
```

> ทุก external call ห่อ try/catch + timeout; แหล่งล่มให้ขยับชั้นถัดไป ไม่พังทั้ง request

### Keyword Search

```
[พิมพ์ใน search bar] → debounce 400ms
        ↓
ถ้าเป็นตัวเลข 10/13 หลัก → ใช้ fallback chain (ISBN lookup)
ไม่งั้น → GET googleapis.com/books/v1/volumes?q={q}&maxResults=20  (live)
        ↓
map results → book cards → กดเพิ่มเข้า shelf
```

### Web Profile Integration

แก้ `admyhusky-dev-template/data.js` ให้ fetch แทน hardcode:

```js
async function loadBooks() {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/user_books?select=*,books(*)&status=eq.finished&order=date_finished.desc`,
    { headers: { apikey: SUPABASE_ANON_KEY } }
  );
  const data = await res.json();
  // group by year แล้ว render เหมือนเดิม
}
```

ข้อดี: แก้ครั้งเดียว → ไม่ต้อง git push ทุกครั้งที่อ่านจบ (anon key ปลอดภัยเพราะ RLS lock แค่ finished)

---

## 6. Flutter App Structure

```
app/lib/
├── core/
│   ├── config/supabase_config.dart   ← credentials (gitignored)
│   ├── router/app_router.dart
│   └── theme/app_theme.dart
├── features/
│   ├── auth/          ← login (Supabase)
│   ├── shelf/         ← หน้าหลัก 3 tabs + bottom nav
│   ├── scan/          ← camera + ISBN + manual fallback
│   ├── search/        ← keyword/ISBN search (ใหม่)
│   ├── book_detail/   ← cover, status, rating, review
│   └── profile/       ← dashboard stats (ใหม่)
├── models/
│   ├── book.dart
│   └── user_book.dart
├── services/
│   ├── supabase_service.dart
│   ├── google_books_service.dart
│   └── open_library_service.dart     ← fallback (ใหม่)
└── main.dart
```

---

## 7. Screens

### 7.1 Shelf (หน้าหลัก)
- Tabs: Reading | Finished | Want to Read
- Card: cover, title, author, (Finished: date_finished + rating stars)
- Bottom nav 3 ปุ่ม: Shelf / + / Profile

### 7.2 `+` Bottom Sheet
- Scan book ISBN → camera
- Search new books → Search screen
- Add new book manually → manual form

### 7.3 Scan
- Camera viewfinder + barcode overlay
- แสดง ISBN ที่ detect ได้ + loading
- หาไม่เจอ (ทุก source) → manual input

### 7.4 Search
- Search bar (debounce 400ms)
- ISBN → fallback chain; keyword → Google live
- Results เป็น book cards → tap เพิ่มเข้า shelf

### 7.5 Book Detail
- Cover (ใหญ่, tap เปลี่ยนได้), title, author, publisher, year, page count
- Description (collapsible)
- Status selector + date pickers
- Rating (0.5–5 ครึ่งดาว) + Review text field — **โผล่เฉพาะตอน status = Finished**
- SAVE button + unsaved-changes dialog
- Delete from shelf (confirm)

### 7.6 Profile (Dashboard)
- User info (email/display name)
- Stats: count แต่ละ status, Rated, Reviewed, avg rating
- Recent reviews list

### 7.7 Auth
- **Google (Gmail) sign-in** ผ่าน Supabase OAuth — ปุ่ม "Sign in with Google" ปุ่มเดียว
- ไม่มี email/password, ไม่มี register (personal app, user คนเดียว = Net)
- ต้อง setup: OAuth client ใน Google Cloud Console + เปิด Google provider ใน Supabase + redirect URL

---

## 8. Build Phases

> 2026-06-07: เริ่มใหม่แบบ spec-driven (Spec Kit) หลัง reset repo. โค้ดเก่าถูกล้าง,
> blueprint นี้ (PRD v2) + Supabase schema ที่ยังอยู่ คือจุดตั้งต้น.

### MVP (spec แรก) — ให้แอพ "ใช้งานได้"
- Flutter project + Supabase init
- **Auth: Google sign-in**
- Shelf (รวม + filter chips), Scan + Google Books (cache-first)
- Book Detail + status + dates + rating + review
- Web `data.js` fetch finished books live

### v2 (spec ถัดไป) — Discover/Search/Profile
- Nav 3 tabs (Shelf / + / Profile) + `+` bottom sheet
- Open Library fallback
- Search screen (keyword + ISBN)
- Profile dashboard (stats + recent reviews)
- Cover tap-to-change

### Future
- Facebook/Apple sign-in, reading progress, share, stats, offline

---

## 9. Key Decisions

| Decision | เหตุผล |
|----------|--------|
| Supabase project ใหม่ (แยกจาก NextNet) | ไม่ปน data, RLS ต่างกัน |
| Google Books หลัก + Open Library fallback | ครอบคลุมเล่มที่ Google ไม่มี (รวม manual เป็นชั้นสุดท้าย) |
| Status คงเดิม `want_to_read/reading/finished` | ไม่ต้อง migrate ข้อมูลเดิม |
| Nav 3 tabs (Shelf/+/Profile) | ตัด Discover/Bestsellers ออก — scope เล็ก โฟกัส personal use |
| Personal app (1 user = Net) | ไม่ต้อง multi-user, RLS simple, ไม่มี register |
| Login ด้วย Google อย่างเดียว | UX กดปุ่มเดียว ไม่ต้องจำรหัส, setup ครั้งเดียว |
| Flutter | Net learn อยู่แล้วกับ NextNet |
| Supabase anon key บนเว็บ | ปลอดภัยเพราะ RLS lock แค่ finished, ไม่มี private data |
| เก็บแค่ cover_url | ประหยัด Storage quota (free tier) |
```
