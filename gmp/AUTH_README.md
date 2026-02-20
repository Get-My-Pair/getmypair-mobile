# 📱 Get My Pair - Authentication UI

Professional authentication system with phone number + OTP verification for Get My Pair mobile application.

## 🎨 Design System

### Color Palette
- **Primary**: Muted Dark Teal (#2C3E50) - Professional, trustworthy
- **Accent**: Warm Terracotta (#E67E22) - Action, warmth
- **Background**: Light Gray (#F5F6F8) - Clean, modern
- **Text**: Dark Gray (#2C3E50) - High contrast, readable

### Typography
- **Display**: 32px, Bold - Headlines
- **Title**: 16-20px, SemiBold - Section titles
- **Body**: 14-16px, Regular - Content
- **Caption**: 12px, Regular - Helper text

### Components
- **Border Radius**: 12px (inputs, buttons), 20px (cards)
- **Shadows**: Subtle elevation (0.08-0.16 opacity)
- **Spacing**: 8px grid system

## 🏗️ Architecture

```
Flutter UI
   ↓
Flutter BLoC (Business Logic)
   ↓
Repository Layer
   ↓
API Service (HTTP)
   ↓
Node.js Express Backend
   ↓
MongoDB Database
```

## 📁 Project Structure

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart       # Color constants
│       └── app_theme.dart        # Theme configuration
│
└── feature/
    └── auth/
        ├── bloc/
        │   ├── auth_bloc.dart    # Business logic
        │   ├── auth_event.dart   # Events
        │   └── auth_state.dart   # States
        │
        ├── data/
        │   └── models/
        │       ├── auth_user.dart      # User model
        │       ├── otp_model.dart      # OTP models
        │       └── country_code.dart   # Country codes
        │
        ├── ui/
        │   ├── phone_auth_screen.dart       # Phone input screen
        │   └── otp_verification_screen.dart # OTP verification
        │
        └── widgets/
            ├── custom_text_field.dart    # Input field component
            ├── custom_button.dart        # Button components
            ├── country_code_picker.dart  # Country selector
            └── otp_input_field.dart      # OTP input component
```

## 🔐 Authentication Flow

### New User Registration
1. User enters phone number → `POST /auth/send-otp`
2. User receives OTP via SMS
3. User enters OTP → `POST /auth/verify-otp` (returns `temp_token` with `is_new_user: true`)
4. User completes registration form → `POST /auth/register-mobile`
5. User receives full access token

### Returning User Login
1. User enters phone number → `POST /auth/send-otp`
2. User receives OTP via SMS
3. User enters OTP → `POST /auth/verify-otp` (returns token with `is_new_user: false`)
4. System automatically issues full access token

## 🛡️ Security Features

- ✅ OTP expires after 5 minutes
- ✅ Rate limiting: 3 OTP requests per phone per hour
- ✅ Maximum 3 failed OTP attempts before cooldown
- ✅ Resend OTP available after 60 seconds
- ✅ Phone number validation
- ✅ Secure token storage (TODO: Implement)

## 🎯 Screens

### 1. Phone Number Screen
**Features:**
- App logo with brand identity
- Tagline: "Find shoes. Fix shoes. All in one place."
- Country code selector (🇮🇳 +91 default)
- 10-digit phone input with auto-focus
- Real-time validation
- Terms & Privacy checkbox (mandatory)
- "Send OTP" button (disabled until valid)
- Loading state with spinner

**Validation:**
- Phone must be exactly 10 digits
- Terms must be accepted
- Inline error messages

### 2. OTP Verification Screen
**Features:**
- Clear header with phone number display
- 6-digit OTP input with auto-advance
- Visual timer showing expiry countdown
- Auto-verify on complete input
- Resend OTP with countdown (60s)
- Help text about attempts/validity
- Loading states
- Error handling

**UX Enhancements:**
- Auto-focus first OTP field
- Auto-advance to next field on input
- Auto-submit when complete
- Clear on tap for easy editing
- Keyboard optimized for numeric input

## 🎨 UI/UX Best Practices

### Mobile-First Design
- ✅ Large touch targets (56px buttons)
- ✅ Auto-focus important fields
- ✅ Numeric keyboards for phone/OTP
- ✅ Clear visual hierarchy
- ✅ Minimal cognitive load
- ✅ Immediate feedback
- ✅ Progressive disclosure

### Accessibility
- ✅ High contrast ratios (WCAG AA)
- ✅ Clear error messages
- ✅ Logical tab order
- ✅ Semantic color usage
- ✅ Readable font sizes (14px+)

### Performance
- ✅ Lazy loading
- ✅ Optimized rebuilds with BLoC
- ✅ Minimal dependencies
- ✅ Efficient state management

## 📦 Dependencies

```yaml
dependencies:
  flutter_bloc: ^9.1.1    # State management
  equatable: ^2.0.8       # Value equality
  http: ^1.6.0            # API calls
```

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

### 3. Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🔧 Configuration

### Update API Endpoints
Edit `lib/feature/auth/data/repositories/auth_repository.dart`:
```dart
static const String baseUrl = 'YOUR_API_URL';
```

### Customize Colors
Edit `lib/core/theme/app_colors.dart`:
```dart
static const Color primary = Color(0xFF2C3E50);
static const Color accent = Color(0xFFE67E22);
```

### Add Logo
Place your logo in:
- `assets/logo/app_logo.png` (recommended 512x512px)
- Update `pubspec.yaml` if needed

## 📱 Screens Preview

### Phone Number Input
- Clean, professional header
- Intuitive country code picker
- Real-time validation feedback
- Clear call-to-action

### OTP Verification
- Easy-to-read 6-digit input
- Visual countdown timer
- Helpful error messages
- Quick resend option

## 🎯 TODO - API Integration

1. **Create Auth Repository**
   - Implement HTTP client
   - Add API endpoints
   - Handle responses/errors

2. **Add Local Storage**
   - Save auth token
   - Persist user data
   - Handle session management

3. **Error Handling**
   - Network errors
   - Server errors
   - Validation errors

4. **Additional Features**
   - Biometric authentication
   - Remember device
   - Auto-fill OTP (SMS listener)

## 📝 API Endpoints (Expected)

```
POST /auth/send-otp
Body: { phoneNumber: string, countryCode: string }
Response: { success: bool, message: string, expiresIn: number }

POST /auth/verify-otp
Body: { phoneNumber: string, countryCode: string, otp: string }
Response: { 
  success: bool, 
  tempToken: string, 
  isNewUser: bool,
  user: { id, phoneNumber, ... }
}

POST /auth/register-mobile
Headers: { Authorization: Bearer <tempToken> }
Body: { name: string, email: string, ... }
Response: { token: string, user: {...} }
```

## 🤝 Contributing

1. Follow the existing code style
2. Write meaningful commit messages
3. Test on multiple devices
4. Update documentation

## 📄 License

This project is part of Get My Pair application.

---

**Built with ❤️ using Flutter & BLoC Pattern**
