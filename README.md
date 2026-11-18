# getmypair-mobile

Customer **User App** (Flutter) for GetMyPair.

## App package

All product code lives under **`gmp/`**.

```bash
cd gmp
flutter pub get
flutter run
```

## Documentation

Start here: **[gmp/docs/README.md](gmp/docs/README.md)**

| Module | Doc |
|--------|-----|
| Auth / OTP | [gmp/docs/MODULE_1_AUTHENTICATION.md](gmp/docs/MODULE_1_AUTHENTICATION.md) |
| Profile | [gmp/docs/MODULE_2_PROFILE.md](gmp/docs/MODULE_2_PROFILE.md) |
| My Rack (articles) | [gmp/docs/MODULE_3_ARTICLES.md](gmp/docs/MODULE_3_ARTICLES.md) |
| Care / Rehome services | [gmp/docs/MODULE_4_SERVICE_REQUESTS.md](gmp/docs/MODULE_4_SERVICE_REQUESTS.md) |
| Payments | [gmp/docs/MODULE_5_PAYMENT.md](gmp/docs/MODULE_5_PAYMENT.md) |
| Sell My Pair | [gmp/docs/MODULE_6_SELL_MY_PAIR.md](gmp/docs/MODULE_6_SELL_MY_PAIR.md) |

Backend API docs: `getmypair-api/server/docs/`.

## API

- Production: `https://getmypair-api.onrender.com`
- Config: `gmp/lib/core/constants/api_endpoints.dart`
- App source header: `USER_APP` (`AppConstants.appSourceForApi`)
