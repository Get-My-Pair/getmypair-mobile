# GetMyPair Flutter Mobile App

A Flutter mobile application implementing the complete authentication flow with OTP verification and profile completion.

## Project Structure

```
lib/
├── main.dart                    # App entry point with Provider setup
├── splash_screen.dart          # Initial splash screen with auth check
├── config/
│   └── api_config.dart         # API configuration and endpoints
├── models/
│   ├── user_model.dart         # User data model
│   └── auth_response_model.dart # Auth API response models
├── providers/
│   └── auth_provider.dart      # State management for authentication
├── screens/
│   ├── welcome_screen.dart      # Welcome/landing screen
│   ├── mobile_otp_screen.dart  # Enter mobile number screen
│   ├── otp_verification_screen.dart # OTP verification screen
│   ├── profile_completion_screen.dart # New user profile completion
│   └── dashboard_screen.dart   # Role-specific dashboard
└── services/
    ├── auth_service.dart       # API service for authentication
    └── storage_service.dart     # Local storage for tokens and user data
```

## Authentication Flow

1. **Splash Screen** → Checks authentication status
   - If authenticated → Navigate to Dashboard
   - If not authenticated → Navigate to Welcome Screen

2. **Welcome Screen** → App introduction and entry point
   - "Get Started" button → Navigate to Mobile OTP Screen

3. **Mobile OTP Screen** → Enter mobile number
   - Validates mobile number
   - Calls `POST /api/auth/send-otp`
   - Navigates to OTP Verification Screen

4. **OTP Verification Screen** → Enter 6-digit OTP
   - Calls `POST /api/auth/verify-otp`
   - If existing user → Navigate to Dashboard
   - If new user → Navigate to Profile Completion Screen

5. **Profile Completion Screen** → New user registration
   - Collects: Name, Date of Birth, Gender
   - Calls `POST /api/auth/complete-profile`
   - Navigates to Dashboard on success

6. **Dashboard Screen** → Role-specific dashboard
   - Displays user profile information
   - Shows role-based content
   - Logout functionality

## API Configuration

Update the `baseUrl` in `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:3000';
```

**Important**: For different platforms:
- **Android Emulator**: Use `http://10.0.2.2:3000`
- **iOS Simulator**: Use `http://localhost:3000`
- **Physical Device**: Use `http://YOUR_IP_ADDRESS:3000`

## Dependencies

The app uses the following key packages:
- `http` - For API calls
- `provider` - For state management
- `shared_preferences` - For local storage
- `intl` - For date formatting
- `flutter_spinkit` - For loading indicators

## Setup Instructions

1. **Install Dependencies**:
   ```bash
   cd getmypair-mobile/gmp
   flutter pub get
   ```

2. **Configure API URL**:
   - Edit `lib/config/api_config.dart`
   - Update `baseUrl` to match your backend server

3. **Run the App**:
   ```bash
   flutter run
   ```

## Features

- ✅ Mobile OTP-based authentication
- ✅ User registration with profile completion
- ✅ JWT token management
- ✅ Role-based dashboard (user, admin, moderator)
- ✅ Secure token storage
- ✅ Automatic authentication check on app start
- ✅ Beautiful UI with Material Design 3

## Backend Integration

The app integrates with the backend API at `/api/auth` endpoints:
- `POST /api/auth/send-otp` - Send OTP to mobile
- `POST /api/auth/verify-otp` - Verify OTP
- `POST /api/auth/complete-profile` - Complete profile for new users
- `POST /api/auth/refresh-token` - Refresh access token
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user profile

## Notes

- The app automatically saves JWT tokens and user data locally
- Authentication state is checked on app startup
- Tokens are included in API requests automatically
- Profile completion is required for new users only
