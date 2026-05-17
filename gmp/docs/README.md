# GetMyPair Mobile (User App) – Documentation

This folder contains module documentation for the **GetMyPair mobile user app** (customer-facing Flutter app in `gmp/`).

| Module | Topic | Document |
|--------|--------|----------|
| **1** | Authentication & onboarding | [MODULE_1_AUTHENTICATION.md](MODULE_1_AUTHENTICATION.md) |
| **2** | Profile & addresses | [MODULE_2_PROFILE.md](MODULE_2_PROFILE.md) |
| **3** | Digital Shoe Passport (My Rack / articles) | [MODULE_3_ARTICLES.md](MODULE_3_ARTICLES.md) |
| **4** | Service requests (Care & Rehome) | [MODULE_4_SERVICE_REQUESTS.md](MODULE_4_SERVICE_REQUESTS.md) |

## Quick reference

- **Entry point:** `lib/main.dart` → `SplashScreen` → auth check → dashboard or onboarding/login
- **DI:** `lib/injection_container.dart` (Auth, Profile, Articles use cases)
- **API base:** `lib/core/constants/api_endpoints.dart` (Render production; `USE_LOCAL_API` for local)
- **Routes:** `lib/routes.dart` (named routes; most flows use `MaterialPageRoute`)

## App shell

`CustomerDashboardPage` uses a 3-tab bottom nav:

1. **Home** — discovery, CareMyPair / RehomeMyPair entry, location
2. **My Rack** — `ArticleListPage` (Module 3)
3. **Profile** — `ProfilePage` (Module 2)

---

*For the cobblers app documentation, see `gmp-cobblers-app/cobbler_app/docs/`.*
