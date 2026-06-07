# Session Notes — 2026-06-06

## สิ่งที่ทำเสร็จแล้ว

1. **Constitution** — 6 principles (P1-P6) ที่ `.specify/memory/constitution.md`
2. **Spec** — 5 user scenarios, 28 FRs ที่ `specs/001-phase1-foundation/spec.md`
3. **Clarifications** — duplicate scan → Book Detail, status เปลี่ยนอิสระ, sort order แยกตาม tab, social login ย้ายเข้า Phase 1, ไม่มี bottom tab bar
4. **Plan** — architecture, project structure, 5 phases ที่ `specs/001-phase1-foundation/plan.md`
5. **Design artifacts** — research.md, data-model.md, contracts/, quickstart.md
6. **Tasks** — 38 tasks, 8 phases ที่ `specs/001-phase1-foundation/tasks.md`
7. **UI mockup** — 4 หน้าจอ + mascot ที่ `docs/ui-mockup.html`
8. **Stitch design** — export อยู่ที่ `stitch_assistance_request_system/`

## Session หน้าทำอะไร

รัน `/speckit-implement` เริ่มจาก T001 (flutter create app) ไปตามลำดับ

## สิ่งที่ต้องทำมือก่อน implement

- สร้าง Supabase project ใหม่ (แยกจาก NextNet)
- สร้าง tables + RLS ตาม `data-model.md`
- Config social login providers (Google, Facebook, Apple) ใน Supabase dashboard
- ใส่ credentials ใน `supabase_config.dart`

## Design decisions ที่ตกลงแล้ว

- Style: Soft-Brutalist (admyhusky.dev + Stitch DESIGN.md)
- Colors: cream #FFF8E7, navy #1B1B3A, yellow #FFD93D, teal #4ECDC4, coral #FF6B6B
- Fonts: Fredoka (headings), Nunito Sans (body)
- Icons: Material Symbols Rounded (ไม่ใช้ emoji)
- Mascot: husky chibi (`docs/mascot.png`)
- No bottom tab bar, ใช้ FAB + top segment control tabs
