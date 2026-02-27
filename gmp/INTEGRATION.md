# Backend Integration Guide

This document describes how the Flutter mobile app integrates with the GetMyPair backend API.

## Backend API Server

The backend server runs on **port 3000** by default and provides the following endpoints:

### Base URL Configuration

Update `lib/core/constants/api_endpoints.dart` to match your environment:

- **Local Development**: `http://localhost:3000`
- **Android Emulator**: `http://10.0.2.2:3000`
- **iOS Simulator**: `http://localhost:3000`
- **Physical Device**: `http://YOUR_IP_ADDRESS:3000`
- **Production**: `https://your-api-domain.com`

## API Endpoints

All authentication endpoints are under `/api/auth`:

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/send-otp` | Send OTP to mobile number | No |
| POST | `/api/auth/verify-otp` | Verify OTP and check user | No |
| POST | `/api/auth/complete-profile` | Complete profile for new users | No |
| POST | `/api/auth/refresh-token` | Refresh access token | No |
| POST | `/api/auth/logout` | User logout | Yes |
| GET | `/api/auth/me` | Get current user | Yes |

## Response Format

### Success Response
```json
{
  "success": true,
  "message": "Success message",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "statusCode": 400,
  "errors": [
    {
      "field": "mobile",
      "message": "Validation error"
    }
  ]
}
```

## Authentication Flow

1. **Send OTP**: User enters mobile number → `POST /api/auth/send-otp`
2. **Verify OTP**: User enters 6-digit OTP → `POST /api/auth/verify-otp`
   - If existing user → Returns JWT tokens and user data
   - If new user → Returns `requiresProfileCompletion: true`
3. **Complete Profile** (new users only): User provides name, DOB, gender → `POST /api/auth/complete-profile`
   - Returns JWT tokens and user data
4. **Dashboard**: User is authenticated and can access protected routes

## Mobile Number Format

The app automatically normalizes mobile numbers:
- Input without `+` prefix → Adds `+91` (India country code)
- Input with `+` prefix → Uses as-is

Example: `6374129515` → `+916374129515`

## Token Management

- **Access Token**: Used for authenticated requests (Bearer token in Authorization header)
- **Refresh Token**: Used to get new access tokens when expired
- Tokens are stored locally using SharedPreferences
- Tokens are automatically included in API requests

## Error Handling

The app handles the following error types:
- `ServerFailure`: Backend API errors
- `NetworkFailure`: Network connectivity issues
- `CacheFailure`: Local storage errors
- `ValidationFailure`: Input validation errors
- `AuthenticationFailure`: Authentication/authorization errors

## Notes

- **Email Login**: Not supported by backend. The app only supports mobile OTP authentication.
- **CORS**: Backend is configured to accept requests from any origin in development (`CORS_ORIGIN: '*'`)
- **Rate Limiting**: Backend implements rate limiting on OTP endpoints (20 requests/15 minutes in dev)

## Testing the Integration

1. Start the backend server:
   ```bash
   cd getmypair-api/server
   npm install
   npm run dev
   ```

2. Update the API base URL in `lib/core/constants/api_endpoints.dart` if needed

3. Run the Flutter app:
   ```bash
   cd getmypair-mobile/gmp
   flutter run
   ```

4. Test the flow:
   - Enter mobile number
   - Receive OTP (check backend logs/console)
   - Enter OTP
   - Complete profile (if new user)
   - Access dashboard

## Troubleshooting

### Connection Issues
- **Android Emulator**: Use `http://10.0.2.2:3000` instead of `localhost`
- **Physical Device**: Use your computer's IP address (e.g., `http://192.168.1.100:3000`)
- **iOS Simulator**: `localhost` should work

### CORS Errors
- Ensure backend CORS is configured to accept requests from your app
- Check `CORS_ORIGIN` in backend `.env` file

### Token Issues
- Tokens are stored in SharedPreferences
- Clear app data if experiencing token-related issues
- Check token expiration (Access: 7 days, Refresh: 30 days)

