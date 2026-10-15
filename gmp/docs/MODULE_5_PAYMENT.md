# MODULE 5 — PAYMENTS (ZOHO)

## Overview

Customer payments for service requests use **Zoho Payments** (order / link / verify / status). The app supports live checkout and a **simulate** path for QA.

**Feature path:** `lib/features/payment/`  
**Backend:** `getmypair-api/server/docs/MODULE_5_PAYMENT.md`

---

## Main screens

| Page | Role |
|------|------|
| `payment_request_page.dart` | Cost approval / pay entry from a service request |
| `payment_checkout_page.dart` | Checkout / open Zoho |
| `payment_simulate_checkout_page.dart` | Local / mock checkout flow |
| `payment_pending_page.dart` | Waiting for confirmation |
| `payment_success_page.dart` / `payment_failed_page.dart` | Terminal states |
| `payment_history_page.dart` | Past transactions |
| `payment_summary_page.dart` / `transaction_details_page.dart` | Details |

**State:** `PaymentBloc` + use cases in `domain/usecases/`.  
**Config:** `lib/features/payment/config/payment_config.dart` (modes / simulate flags).

---

## API (via `ApiEndpoints`)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/payment/order` | Create order |
| POST | `/api/payment/link` | Payment link |
| POST | `/api/payment/verify` | Verify payment |
| GET | `/api/payment/status/:orderId` | Poll status (`?refresh=true`) |
| GET | `/api/payment/history` | History |
| GET | `/api/payment/:paymentId` | By id |
| GET | `/api/payment/by-service-request/:id` | By service request |

Webhook handling is **server-side only** (`POST /api/payment/webhook/zoho`).

---

## Flow (summary)

```
Service request needs payment / cost approval
        ↓
PaymentRequestPage / PaymentSummaryPage
        ↓
PaymentBloc → create order / link
        ↓
Checkout (Zoho) or SimulateCheckout
        ↓
Poll status → Success / Failed / Pending
        ↓
Optional: PaymentHistoryPage
```

---

## Related

- Service requests: [MODULE_4_SERVICE_REQUESTS.md](MODULE_4_SERVICE_REQUESTS.md)
- Notifications: profile / home notification entry for payment events
- Backend env: Zoho keys in `getmypair-api/server/docs/ENV.md`
