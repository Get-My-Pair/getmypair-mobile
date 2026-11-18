# MODULE 6 — SELL MY PAIR

## Overview

Sell My Pair lets users submit **luxury** or **everyday** footwear for admin review. Entry is from **Rehome My Pair → Sell My Pair**. Status icons match My Rack shelf UI.

**Feature path:** `lib/features/sell/`  
**Backend:** `getmypair-api/server/docs/MODULE_6_SELL_MY_PAIR.md`

| Asset | Meaning |
|-------|---------|
| `assets/images/sellmypair/review.svg` | In review (`pending`) |
| `assets/images/sellmypair/done.svg` | Approved |
| `assets/images/sellmypair/reject.svg` | Rejected |

---

## User flow

```
Home → Rehome My Pair
         ↓
   SellMyPairPage
         ↓
   Choose Luxury or Everyday
         ↓
   FootwearSelectionPage  (articles filtered by footwearType)
         ↓
   FootwearSellingPage    (price, condition, proofs, auction dates)
         ↓
   POST /api/sell/upload-proof  (×4)
   POST /api/sell/listings
         ↓
   MyFootwearRackPage     (status: pending → admin review)
```

Hub also shows **My Luxury Rack** / **My Everyday Rack** previews (same shelf chrome as My Rack).

---

## Screens

| Page | File | Role |
|------|------|------|
| Hub | `sell_my_pair_page.dart` | Services + rack previews + status legend |
| Select shoe | `footwear_selection_page.dart` | Articles for `luxury` / `everyday` |
| Sell form | `footwear_selling_page.dart` | Retail/base price, grade, proofs, dates |
| Full rack | `my_footwear_rack_page.dart` | Shelf grid; tap for status / resubmit |
| Shared UI | `widgets/sell_shell.dart` | Scaffold, `SellRackShelf`, `SellRackShoeCell` |

### Rack UI (My Rack style)

- Grey shelf (`#F0F0F0`), teal bottom border, 3 shoes per row
- Shoe image + label; **status SVG top-right**
- Rejected → bottom sheet with reason + **Resubmit**
- Pending / approved → info dialog only (no edit while in review)

---

## API (via `SellRemoteDataSource`)

| Method | Endpoint | Notes |
|--------|----------|--------|
| POST | `/api/sell/upload-proof` | multipart: `file` + `proofType` |
| POST | `/api/sell/listings` | Create listing (`status: pending`) |
| GET | `/api/sell/listings?footwearType=` | My listings |

**Proof types:** `receipt`, `purchaseEmail`, `authenticityCard`, `boxLabel`  
**Condition grades:** `brand_new_in_box`, `like_new`, `gently_used`  
**Listing statuses:** `pending` \| `approved` \| `rejected`

Article `footwearType` must match the selected rack type.

---

## Architecture

```
presentation/pages + sell_shell
        ↓
SellRemoteDataSource  (http + GetValidAccessToken)
        ↓
getmypair-api /api/sell/*
```

No dedicated SellBloc; pages load listings with the datasource after token resolve.

Admin approve/reject is **not** in this app — Masteradmin web (`client/client`). After review, pull-to-refresh / reopen rack to see new status.

---

## Related

- Articles / My Rack: [MODULE_3_ARTICLES.md](MODULE_3_ARTICLES.md)
- Rehome entry: `lib/features/service/presentation/pages/rehome_my_pair_page.dart`
- Backend: `getmypair-api/server/docs/MODULE_6_SELL_MY_PAIR.md`
