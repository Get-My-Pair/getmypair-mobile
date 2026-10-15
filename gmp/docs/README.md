# GetMyPair Mobile (User App) — Documentation

Module docs for the **customer Flutter app** in `getmypair-mobile/gmp/`.  
Aligned with backend docs in `getmypair-api/server/docs/`.

| Module | Topic | Document |
|--------|--------|----------|
| **1** | Authentication & onboarding (OTP) | [MODULE_1_AUTHENTICATION.md](MODULE_1_AUTHENTICATION.md) |
| **2** | Profile, family, addresses, devices | [MODULE_2_PROFILE.md](MODULE_2_PROFILE.md) |
| **3** | Digital Shoe Passport (My Rack / articles) | [MODULE_3_ARTICLES.md](MODULE_3_ARTICLES.md) |
| **4** | Service requests (Care & Rehome) | [MODULE_4_SERVICE_REQUESTS.md](MODULE_4_SERVICE_REQUESTS.md) |
| **5** | Payments (Zoho) | [MODULE_5_PAYMENT.md](MODULE_5_PAYMENT.md) |
| **6** | Sell My Pair (Luxury / Everyday racks) | [MODULE_6_SELL_MY_PAIR.md](MODULE_6_SELL_MY_PAIR.md) |

## Quick reference

| Item | Location |
|------|----------|
| Entry | `lib/main.dart` → splash → auth → dashboard / onboarding |
| DI | `lib/injection_container.dart` |
| API base & paths | `lib/core/constants/api_endpoints.dart` |
| App constants | `lib/core/constants/app_constants.dart` (`USER_APP`, version `3.0.0`) |
| Named routes | `lib/routes.dart` (many flows use `MaterialPageRoute`) |
| Features | `lib/features/{auth,profile,articles,service,sell,payment,home,dashboard}/` |

**Production API:** `https://getmypair-api.onrender.com`  
**Local override:** `flutter run --dart-define=USE_LOCAL_API=true` (see `ApiEndpoints`)

## App shell

`CustomerDashboardPage` — floating bottom nav:

1. **Home** — location, My Rack preview, Care / Rehome / Save / Style Me
2. **My Rack** — `ArticleListPage` (Module 3)
3. **Profile** — `ProfilePage` (Module 2)

## Headers sent to API

| Header | Value |
|--------|--------|
| `Authorization` | `Bearer <accessToken>` |
| `X-App-Source` | `USER_APP` |
| `X-App-Version` | `AppConstants.appVersion` |
| `X-Active-Profile-Id` | Active family profile (when set) |
| `device-info` | On verify-otp (device label) |

## Backend pairing

| App module | Backend doc |
|------------|-------------|
| Auth OTP | `getmypair-api/server/docs/MODULE_1_DOCUMENTATION.md` + `ENV.md` |
| Sell | `getmypair-api/server/docs/MODULE_6_SELL_MY_PAIR.md` |
| Payments | `getmypair-api/server/docs/MODULE_5_PAYMENT.md` |

---

*Cobbler app docs (if present): `gmp-cobblers-app/.../docs/`*
