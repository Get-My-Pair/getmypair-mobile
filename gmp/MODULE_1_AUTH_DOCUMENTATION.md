# MODULE 1 – AUTHENTICATION DOCUMENTATION

## Table of Contents
1. [Overview](#overview)
2. [Complete User Flow](#complete-user-flow)
3. [API Endpoints](#api-endpoints)
4. [Screen Documentation](#screen-documentation)
5. [State Management](#state-management)
6. [Models](#models)
7. [Architecture Flow](#architecture-flow)

---

## Overview

Module 1 handles the complete authentication flow for the GetMyPair mobile application. It includes user registration, login via OTP, and profile completion for new users.

**Key Features:**
- Mobile OTP-based authentication
- Splash screen with auth status check
- Welcome screen with app introduction
- OTP verification with resend functionality
- Profile completion for new users
- JWT token management

---

## Complete User Flow

### App Launch Flow

```
App Launch
   ↓
SplashPage (2s)
   ↓
Check AuthBloc.state
   ↓
 ├─ Authenticated → GET /api/user/profile/me
 │                     ↓
 │              ├─ Profile Exists → CustomerDashboardPage
 │              └─ Profile Not Exists → ProfileCompletionPage
 │
 └─ Not Authenticated → WelcomePage
                          ↓
                    Tap "Get Started"
                          ↓
                    MobileOTPPage
                          ↓
                    Enter Mobile Number
                          ↓
                    POST /api/auth/send-otp
                          ↓
                    OTPPage
                          ↓
                    Enter OTP
                          ↓
                    POST /api/auth/verify-otp
                          ↓
                    ├─ Existing User
                    │      ↓
                    │   Save Token
                    │      ↓
                    │   GET /api/user/profile/me
                    │      ↓
                    │   CustomerDashboardPage
                    │
                    └─ New User
                           ↓
                    ProfileCompletionPage
                           ↓
                    Fill:
                      • Name
                      • DOB
                      • Gender
                      • Location
                           ↓
                    POST /api/auth/complete-profile
                           ↓
                    Save Token
                           ↓
                    CustomerDashboardPage
```

---

## API Endpoints

### 1. POST /api/auth/send-otp

**Purpose:** Send OTP to user's mobile number

**Request Body:**
```json
{
  "mobile": "+919876543210"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "otp": "123456"  // Only in development mode
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Rate limit exceeded. Please try again later."
}
```

---

### 2. POST /api/auth/verify-otp

**Purpose:** Verify OTP and authenticate user

**Request Body:**
```json
{
  "mobile": "+919876543210",
  "otp": "123456"
}
```

**Response (Existing User):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user123",
    "mobile": "+919876543210",
    "name": "John Doe",
    "isPhoneVerified": true
  },
  "requiresProfileCompletion": false
}
```

**Response (New User):**
```json
{
  "success": true,
  "tempToken": "temp_token_here",
  "requiresProfileCompletion": true,
  "mobile": "+919876543210"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Invalid OTP"
}
```

---

### 3. POST /api/auth/complete-profile

**Purpose:** Complete profile for new users

**Request Body:**
```json
{
  "mobile": "+919876543210",
  "name": "John Doe",
  "dateOfBirth": "1990-01-15",
  "gender": "male",
  "location": {
    "lat": 13.0827,
    "lng": 80.2707,
    "address": "Chennai, Tamil Nadu"
  }
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user123",
    "mobile": "+919876543210",
    "name": "John Doe",
    "dateOfBirth": "1990-01-15",
    "gender": "male",
    "role": "customer"
  }
}
```

---

## Screen Documentation

### 1. SplashPage

**File:** `lib/features/auth/presentation/pages/splash_page.dart`

**Purpose:** Initial screen shown when app launches. Displays app branding and checks authentication status.

**Features:**
- Animated logo with floating effect
- App name with gradient text
- Tagline display
- Loading indicator
- App version display
- 2-second minimum display time
- Automatic navigation based on auth status

**Navigation Logic:**
```dart
if (authState is AuthAuthenticated) {
  // Navigate to CustomerDashboardPage
} else {
  // Navigate to WelcomePage
}
```

**UI Components:**
- Animated logo (scale + fade)
- Floating animation for logo
- Gradient text for app name
- Pulsing loading dots
- Decorative background elements

**Route:** `/` (root route)

---

### 2. WelcomePage

**File:** `lib/features/auth/presentation/pages/welcome_page.dart`

**Purpose:** Welcome screen introducing the app to new users.

**Features:**
- App logo
- Welcome message
- App tagline
- Feature highlights:
  - Browse thousands of shoes
  - Find trusted repair services
  - Fast delivery to your doorstep
- "Get Started" button
- Terms & Privacy Policy links
- Location permission request (optional)

**User Actions:**
- Tap "Get Started" → Navigate to `MobileOTPPage`
- Location permission requested before navigation

**Route:** `/welcome`

**Key Code:**
```dart
ElevatedButton(
  onPressed: () async {
    await WelcomePage.askLocationPermissionIfNeeded();
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const MobileOTPPage(),
    ));
  },
  child: Text('Get Started'),
)
```

---

### 3. MobileOTPPage

**File:** `lib/features/auth/presentation/pages/mobile_otp_page.dart`

**Purpose:** Screen for entering mobile number to receive OTP.

**Features:**
- Country code picker (default: India)
- Phone number input (10 digits)
- Terms & Privacy checkbox
- Send OTP button
- Real-time phone validation
- Loading state during OTP send
- Development mode OTP display dialog

**Form Validation:**
- Phone number must be exactly 10 digits
- Terms & Privacy must be accepted
- Country code selection

**API Call:**
```dart
context.read<AuthBloc>().add(AuthSendOTP(fullMobile));
```

**Navigation:**
- On success → Navigate to `OTPPage` with mobile number
- In dev mode → Show OTP dialog, then navigate

**Route:** `/mobile-otp`

**State Management:**
- Listens to `AuthBloc` for `AuthOTPSent` state
- Shows error snackbar on `AuthError` state

---

### 4. OTPPage

**File:** `lib/features/auth/presentation/pages/otp_page.dart`

**Purpose:** Screen for entering and verifying 6-digit OTP.

**Features:**
- 6-digit OTP input field (pin_code_fields)
- Auto-fill support (from dev dialog)
- Resend OTP functionality
- 60-second countdown timer
- OTP expiration timer (5 minutes)
- Verify button
- Loading state during verification
- Development mode OTP display

**User Actions:**
- Enter 6-digit OTP
- Tap "Verify OTP" → Calls `POST /api/auth/verify-otp`
- Tap "Resend OTP" → Calls `POST /api/auth/send-otp` (after 60s)

**API Call:**
```dart
context.read<AuthBloc>().add(AuthVerifyOTP(
  mobile: widget.mobile,
  otp: _otp,
));
```

**Navigation Logic:**
```dart
if (state.requiresProfileCompletion) {
  // Navigate to ProfileCompletionPage
} else {
  // Navigate to CustomerDashboardPage
}
```

**Route:** `/otp`

**Parameters:**
- `mobile`: String (required)
- `countryCode`: String? (optional)
- `phoneNumber`: String? (optional)
- `prefilledOtp`: String? (optional, dev mode)

---

### 5. ProfileCompletionPage

**File:** `lib/features/auth/presentation/pages/profile_completion_page.dart`

**Purpose:** Screen for new users to complete their profile information.

**Features:**
- Full name input (2-100 characters, letters only)
- Date of birth picker (must be 18+ years)
- Gender selection (Male, Female, Other)
- Location detection (optional, via GPS)
- Form validation
- Complete Profile button
- Loading state during submission

**Form Fields:**
1. **Name:**
   - Required
   - Min 2 characters
   - Max 100 characters
   - Only letters and spaces allowed
   - Text capitalization: Words

2. **Date of Birth:**
   - Required
   - Must be at least 18 years old
   - Date picker with custom theme
   - Display format: "dd MMMM yyyy"

3. **Gender:**
   - Required
   - Options: Male, Female, Other
   - Icon-based selection

4. **Location:**
   - Optional
   - Auto-detected via GPS if permission granted
   - Falls back to coordinates if reverse geocoding fails

**API Call:**
```dart
context.read<AuthBloc>().add(AuthCompleteProfile(
  mobile: widget.mobile,
  name: _nameController.text.trim(),
  dateOfBirth: _selectedDate!,
  gender: _selectedGender!,
  location: location,
));
```

**Navigation:**
- On success → Navigate to `CustomerDashboardPage`
- On error → Show error snackbar

**Route:** `/profile-completion`

**Parameters:**
- `mobile`: String (required)

---

### 6. LoginPage

**File:** `lib/features/auth/presentation/pages/login_page.dart`

**Purpose:** Placeholder page indicating email login is not available.

**Features:**
- App logo
- Message: "Email Login Not Available"
- Redirect button to Mobile OTP

**Note:** This page is currently a placeholder. All authentication is done via mobile OTP.

**Route:** `/login`

---

## State Management

### AuthBloc States

**File:** `lib/features/auth/presentation/bloc/auth_state.dart`

1. **AuthInitial** - Initial state
2. **AuthLoading** - Loading state during API calls
3. **AuthAuthenticated** - User is authenticated
   - Contains: `User user`
4. **AuthUnauthenticated** - User is not authenticated
5. **AuthOTPSent** - OTP sent successfully
   - Contains: `String mobile`, `String? otp` (dev mode)
6. **AuthOTPVerified** - OTP verified successfully
   - Contains: `bool requiresProfileCompletion`, `String mobile`, `User? user`
7. **AuthProfileCompleted** - Profile completed successfully
   - Contains: `User user`
8. **AuthError** - Error occurred
   - Contains: `String message`

### AuthBloc Events

**File:** `lib/features/auth/presentation/bloc/auth_event.dart`

1. **AuthCheckStatus** - Check if user is authenticated
2. **AuthSendOTP** - Send OTP to mobile number
   - Contains: `String mobile`
3. **AuthVerifyOTP** - Verify OTP
   - Contains: `String mobile`, `String otp`
4. **AuthCompleteProfile** - Complete user profile
   - Contains: `String mobile`, `String name`, `DateTime dateOfBirth`, `String gender`, `Map<String, dynamic>? location`
5. **AuthLogout** - Logout user

---

## Models

### UserModel

**File:** `lib/features/auth/data/models/user_model.dart`

**Properties:**
```dart
class UserModel {
  final String id;
  final String mobile;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String? email;
  final String role;  // 'customer', 'admin', etc.
  final bool isPhoneVerified;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**JSON Serialization:**
- `fromJson()` - Parse from API response
- `toJson()` - Convert to JSON for API requests

---

### CountryCode

**File:** `lib/features/auth/data/models/country_code.dart`

**Properties:**
```dart
class CountryCode {
  final String code;      // e.g., "IN"
  final String name;      // e.g., "India"
  final String dialCode; // e.g., "+91"
  final String flag;      // Emoji flag
}
```

**Popular Countries:**
- India (+91)
- USA (+1)
- UK (+44)
- And more...

---

### LoginResponseModel

**File:** `lib/features/auth/data/models/login_response_model.dart`

**Properties:**
```dart
class LoginResponseModel {
  final bool success;
  final String? token;
  final String? tempToken;
  final User? user;
  final bool requiresProfileCompletion;
  final String? message;
}
```

---

## Architecture Flow

```
Flutter App
   ↓
AuthBloc (State Management)
   ↓
AuthRepository (Domain Layer)
   ↓
AuthRemoteDataSource (Data Layer)
   ↓
POST /api/auth/send-otp
POST /api/auth/verify-otp
POST /api/auth/complete-profile
   ↓
Backend API
   ↓
JWT Token Response
   ↓
Token Storage (SharedPreferences)
   ↓
Profile APIs (Module 2)
```

---

## Security Features

1. **OTP Expiration:** 5 minutes
2. **Rate Limiting:** 3 OTP requests per phone per hour
3. **Max Attempts:** 3 failed OTP attempts before cooldown
4. **Resend Delay:** 60 seconds between resend requests
5. **Phone Validation:** 10-digit validation
6. **Token Storage:** Secure storage via SharedPreferences
7. **JWT Token:** Used for authenticated API calls

---

## Notes

- All authentication is mobile OTP-based
- Email login is not supported (LoginPage is placeholder)
- Location permission is optional but requested for better UX
- Profile completion is mandatory for new users
- Token is saved automatically after successful authentication
- Auth state is checked on app launch via SplashPage

---

## Implementation Details

### Token Storage
```dart
// Save token
await prefs.setString(AppConstants.accessTokenKey, token);

// Retrieve token
final token = prefs.getString(AppConstants.accessTokenKey);
```

### Navigation
- Uses `MaterialPageRoute` for navigation
- `pushAndRemoveUntil` for replacing entire navigation stack
- Route definitions in `lib/routes.dart`

### Error Handling
- All errors are caught and displayed via SnackBar
- Error messages come from API responses
- Network errors are handled gracefully

---

## Related Files

- **Routes:** `lib/routes.dart`
- **Injection Container:** `lib/injection_container.dart`
- **API Endpoints:** `lib/core/constants/api_endpoints.dart`
- **App Constants:** `lib/core/constants/app_constants.dart`

---

**End of Module 1 Documentation**
