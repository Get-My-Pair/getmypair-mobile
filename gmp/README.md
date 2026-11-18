# GetMyPair Flutter User App (`gmp`)

Customer mobile app: OTP login, My Rack, Care / Rehome services, Sell My Pair, and Zoho payments.

## Docs

**[docs/README.md](docs/README.md)** — module index (auth, profile, articles, service, payment, sell).

## Run

```bash
flutter pub get
flutter run
# Optional: point ApiEndpoints at local API (see api_endpoints.dart)
flutter run --dart-define=USE_LOCAL_API=true
```

## Structure

```
lib/
├── main.dart
├── routes.dart
├── injection_container.dart
├── core/                    # API, theme, widgets, constants
└── features/
    ├── auth/                # OTP, onboarding
    ├── profile/             # Profile, family, addresses, devices
    ├── articles/            # My Rack (Digital Shoe Passport)
    ├── service/             # Care / Rehome / Save flows
    ├── sell/                # Sell My Pair (luxury / everyday)
    ├── payment/             # Zoho checkout + history
    ├── home/
    └── dashboard/           # Tab shell
```

## API

- Base URL: `lib/core/constants/api_endpoints.dart`
- Default production: `https://getmypair-api.onrender.com`
- `X-App-Source`: `USER_APP`

Backend documentation: `../../getmypair-api/server/docs/` (from monorepo root).
