# MODULE 4 – SERVICE REQUESTS DOCUMENTATION

## Table of Contents
1. [Overview](#overview)
2. [Service Types](#service-types)
3. [Complete User Flows](#complete-user-flows)
4. [API Endpoints](#api-endpoints)
5. [Screens & Navigation](#screens--navigation)
6. [Request Payload](#request-payload)
7. [Proof Media Upload](#proof-media-upload)
8. [Request Lifecycle & Tracking](#request-lifecycle--tracking)
9. [Architecture Notes](#architecture-notes)

---

## Overview

Module 4 lets customers request **shoe care services** tied to a Module 3 **article** (digital passport): repair, maintenance, wash, donate, and dispose. Flows collect address, optional problem description, proof photos/videos, pickup mode, and estimated cost, then create a request on the backend.

**Feature path:** `lib/features/service/`

**Important:** There is no dedicated `ServiceBloc` or repository layer. Presentation pages call `DioClient` / `http` directly with `GetValidAccessToken`, plus `GetArticleById` and `ProfileBloc` / `GetUserProfile` for context.

---

## Service Types

| `serviceType` (API) | UI entry | Typical flow wrapper |
|---------------------|----------|----------------------|
| `repair` | CareMyPair → RepairMyPair | `RepairMyPairPage` → `ServiceSelectionPage` |
| `maintenance` | CareMyPair → MaintainMyPair | `MaintainMyPairPage` (`allowedServiceTypes: ['maintenance']`) |
| `wash` | CareMyPair → WashMyPair | `WashMyPairPage` (`allowedServiceTypes: ['wash']`) |
| `donate` | RehomeMyPair → Donate | `DonateMyPairPage` / `DonateMyPairFlow` |
| `dispose` | Service selection (multi-option) | `ServiceSelectionPage` when dispose allowed |

**Estimates (client defaults in `ServiceSelectionPage`):**
- Repair: ₹1000 (`kRepairEstimateRupees`)
- Wash: ₹300 (`kWashEstimateRupees`)
- Maintenance plans: 1m ₹299, 3m ₹999, 6m ₹1500

Donate/dispose summaries hide the estimation row in `RequestSummaryPage`.

---

## Complete User Flows

### Care hub (repair / maintain / wash)

```
HomePage or bottom nav context
      ↓
CareMyPairPage
      ↓
RepairMyPairPage | MaintainMyPairPage | WashMyPairPage
      ↓
User selects article from rack grid
      ↓
ServiceSelectionPage(articleId, allowedServiceTypes: [...])
      ↓
Steps: service details → address → pickup (home vs cobbler nearby)
       → schedule slot → proof photos/videos (max 5 images, 3 videos)
      ↓
RequestSummaryPage
      ↓
Upload proofs → POST /api/service/create
      ↓
Success alert → pop back
```

### Donate / rehome

```
RehomeMyPairPage
      ↓
DonateMyPairPage (article picker)
      ↓
DonateMyPairFlow or RepairMyPairPage with allowedServiceTypes: ['donate']
      ↓
RequestSummaryPage (confirm: "All Set for Donation")
      ↓
POST /api/service/create (serviceType: donate)
```

### List & manage requests

```
CareMyPairPage → "My Service Requests"
      ↓
ServiceRequestListPage
      ↓
GET /api/service/my
      ↓
Tap row → ServiceRequestDetailsPage(requestId)
      ↓
GET /api/service/:requestId
Actions: Cancel (PUT cancel), Accept/Reject actual cost (POST respond-actual-cost)
```

---

## API Endpoints

From `lib/core/constants/api_endpoints.dart`:

| Method | Path | Used by |
|--------|------|---------|
| `POST` | `/api/service/create` | `RequestSummaryPage` |
| `GET` | `/api/service/my` | `ServiceRequestListPage` |
| `GET` | `/api/service/:requestId` | `ServiceRequestDetailsPage` |
| `GET` | `/api/service/estimation-defaults` | Available on API (not always called from UI) |
| `PUT` | `/api/service/cancel/:requestId` | Details page |
| `POST` | `/api/service/respond-actual-cost` | Details page (accept/reject) |
| `POST` | `/api/service/upload-proof/image` | `ServiceProofUpload.uploadImage` |
| `POST` | `/api/service/upload-proof/video` | `ServiceProofUpload.uploadVideo` |

All authenticated calls use `DioClient` or multipart helpers with bearer token and `X-App-Source` / `X-App-Version`.

---

## Screens & Navigation

| Screen | File | Role |
|--------|------|------|
| **CareMyPairPage** | `care_my_pair_page.dart` | Hub: Repair / Maintain / Wash cards, DIY content, link to request list |
| **RehomeMyPairPage** | `rehome_my_pair_page.dart` | Donate entry, educational content |
| **RepairMyPairPage** | `repair_my_pair_page.dart` | Article grid → `ServiceSelectionPage` |
| **MaintainMyPairPage** | `maintain_my_pair_page.dart` | Single-service wrapper |
| **WashMyPairPage** | `wash_my_pair_page.dart` | Single-service wrapper |
| **DonateMyPairPage** | `donate_my_pair_page.dart` | Donate-only article selection |
| **DonateMyPairFlow** | `donate_my_pair_flow.dart` | Multi-step donate UI |
| **ServiceSelectionPage** | `service_selection_page.dart` | Core wizard: service, address, pickup, proofs |
| **SelectAddressPage** | `select_address_page.dart` | Pick saved address |
| **RequestSummaryPage** | `request_summary_page.dart` | Review + submit create |
| **ServiceRequestListPage** | `service_request_list_page.dart` | My requests |
| **ServiceRequestDetailsPage** | `service_request_details_page.dart` | Status, timeline, cost decision, cancel |
| **ServiceRequestBgLayer** | `widgets/service_request_bg_layer.dart` | Shared gradient background |

**Pickup modes (API `pickupMode`):**
- `home_pickup` — user address from profile
- `cobbler_nearby` — map selection via `SelectLocationPage` / geocode helpers

---

## Request Payload

Built in `RequestSummaryPage._confirmRequest()`:

```json
{
  "articleId": "<articleId>",
  "serviceType": "repair",
  "addressId": "<addressId>",
  "photos": ["https://..."],
  "videos": ["https://..."],
  "estimatedCost": 1000,
  "pickupMode": "home_pickup",
  "problemDescription": "Sole detached",
  "requestedPickupAt": "2025-05-17T10:30:00.000Z",
  "maintenancePlanId": "3m",
  "maintenancePlanLabel": "3 months"
}
```

Optional fields omitted when empty. `requestedPickupAt` is ISO 8601 UTC from selected day + slot in `ServiceSelectionPage`.

**Create response:** `data.request._id` used for success message.

---

## Proof Media Upload

**File:** `lib/features/service/data/service_proof_upload.dart`

- `ServiceProofUpload.uploadImage(XFile, token)` → `POST /api/service/upload-proof/image`
- `ServiceProofUpload.uploadVideo(XFile, token)` → `POST /api/service/upload-proof/video`
- Multipart field: `file`
- Returns Cloudinary URL from `data.url`

Called from `RequestSummaryPage` before `serviceCreate`.

---

## Request Lifecycle & Tracking

`ServiceRequestDetailsPage` reads `trackingState` and maps to a 10-stage workflow:

1. `request_created`
2. `pickup_scheduled`
3. `item_picked`
4. `dark_store_received`
5. `inspection_started`
6. `repair_in_progress`
7. `repair_completed`
8. `dispatch_ready`
9. `out_for_delivery`
10. `delivered`

**Actual cost workflow:**
- Backend sets `actualCost` and `actualCostUserDecision: pending`
- User **accept** or **reject** via `POST /api/service/respond-actual-cost` with `{ requestId, decision }`
- Reject shows warning that request is cancelled

**Cancel:** `PUT /api/service/cancel/:requestId` with confirmation dialog.

---

## Architecture Notes

```
UI (StatefulWidget pages)
      ↓
GetValidAccessToken / GetArticleById / GetUserProfile / ProfileBloc
      ↓
DioClient (JSON)  |  ServiceProofUpload (multipart)
      ↓
getmypair-api /api/service/*
```

**Dependencies:**
- Module 1: valid access token (refresh handled in auth repository)
- Module 2: `Address` entity, profile addresses for pickup
- Module 3: `articleId`, article images for summaries

**Not in `injection_container.dart`:** Service feature has no registered bloc/repository; add a data layer here if you refactor.

---

## Related Files

- `lib/core/constants/api_endpoints.dart`
- `lib/core/network/dio_client.dart`
- `lib/features/home/presentation/pages/home_page.dart` — Care / Rehome entry
- `lib/features/articles/presentation/pages/article_details_page.dart` — service CTAs

---

**End of Module 4 Documentation**
