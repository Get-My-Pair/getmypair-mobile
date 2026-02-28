# MODELS DOCUMENTATION

## Table of Contents
1. [Overview](#overview)
2. [Auth Models](#auth-models)
3. [Profile Models](#profile-models)
4. [Model Relationships](#model-relationships)
5. [JSON Serialization](#json-serialization)

---

## Overview

This document describes all data models used in the GetMyPair mobile application. Models are organized by module (Auth and Profile) and include their properties, JSON serialization methods, and usage examples.

---

## Auth Models

### 1. UserModel

**File:** `lib/features/auth/data/models/user_model.dart`

**Purpose:** Represents a user entity in the authentication system.

**Properties:**
```dart
class UserModel {
  final String id;                    // User unique identifier
  final String mobile;                // Mobile number (with country code)
  final String name;                  // User's full name
  final DateTime dateOfBirth;         // Date of birth
  final String gender;                // Gender: 'male', 'female', 'other'
  final String? email;                // Email address (optional)
  final String role;                  // User role: 'customer', 'admin', etc.
  final bool isPhoneVerified;         // Phone verification status
  final bool isActive;                // Account active status
  final DateTime? lastLogin;          // Last login timestamp (optional)
  final DateTime createdAt;           // Account creation date
  final DateTime updatedAt;            // Last update date
}
```

**JSON Structure:**
```json
{
  "_id": "user123",
  "mobile": "+919876543210",
  "name": "John Doe",
  "dateOfBirth": "1990-01-15T00:00:00Z",
  "gender": "male",
  "email": "john@example.com",
  "role": "customer",
  "isPhoneVerified": true,
  "isActive": true,
  "lastLogin": "2024-01-20T10:30:00Z",
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-20T15:30:00Z"
}
```

**Usage:**
```dart
// From JSON
final user = UserModel.fromJson(jsonData);

// To JSON
final json = user.toJson();

// Access properties
print(user.name);        // "John Doe"
print(user.mobile);      // "+919876543210"
print(user.isActive);    // true
```

**Notes:**
- `id` can be `_id` or `id` in JSON (handles both)
- `dateOfBirth` is required and must be a valid date
- `email` is optional (can be null)
- `lastLogin` is optional (can be null)
- Dates are stored in ISO 8601 format

---

### 2. LoginResponseModel

**File:** `lib/features/auth/data/models/login_response_model.dart`

**Purpose:** Represents the response from OTP verification API.

**Properties:**
```dart
class LoginResponseModel {
  final bool success;                      // Request success status
  final String? token;                     // JWT access token (for existing users)
  final String? tempToken;                 // Temporary token (for new users)
  final User? user;                        // User object (if authenticated)
  final bool requiresProfileCompletion;     // Whether profile completion is needed
  final String? message;                   // Response message
}
```

**JSON Structure (Existing User):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "user123",
    "mobile": "+919876543210",
    "name": "John Doe",
    "isPhoneVerified": true
  },
  "requiresProfileCompletion": false
}
```

**JSON Structure (New User):**
```json
{
  "success": true,
  "tempToken": "temp_token_here",
  "requiresProfileCompletion": true,
  "mobile": "+919876543210"
}
```

**Usage:**
```dart
final response = LoginResponseModel.fromJson(jsonData);

if (response.requiresProfileCompletion) {
  // Navigate to profile completion
} else {
  // Save token and navigate to dashboard
  await saveToken(response.token!);
}
```

---

### 3. CountryCode

**File:** `lib/features/auth/data/models/country_code.dart`

**Purpose:** Represents a country code for phone number input.

**Properties:**
```dart
class CountryCode {
  final String code;      // Country code (e.g., "IN", "US")
  final String name;      // Country name (e.g., "India", "United States")
  final String dialCode;  // Dial code (e.g., "+91", "+1")
  final String flag;      // Emoji flag (e.g., "🇮🇳", "🇺🇸")
}
```

**Popular Countries:**
```dart
static const List<CountryCode> popularCountries = [
  CountryCode(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
  CountryCode(code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  CountryCode(code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  // ... more countries
];
```

**Usage:**
```dart
final country = CountryCode.popularCountries[0]; // India
print(country.dialCode);  // "+91"
print(country.flag);       // "🇮🇳"

// Full phone number
final fullNumber = '${country.dialCode}9876543210';
```

---

## Profile Models

### 1. UserProfileModel

**File:** `lib/features/profile/data/models/user_profile_model.dart`

**Purpose:** Represents a user's profile with all associated data.

**Properties:**
```dart
class UserProfileModel {
  final String id;                    // Profile unique identifier
  final String userId;                // Associated user ID
  final String name;                  // User's full name
  final String phone;                 // Phone number
  final String? email;                // Email address (optional)
  final String? profileImage;          // Profile image URL (optional)
  final List<Address> addresses;      // List of saved addresses
  final DateTime createdAt;           // Profile creation date
  final DateTime updatedAt;            // Last update date
}
```

**JSON Structure:**
```json
{
  "_id": "profile123",
  "userId": "user123",
  "name": "John Doe",
  "phone": "+919876543210",
  "email": "john@example.com",
  "profileImage": "https://example.com/profile.jpg",
  "addresses": [
    {
      "_id": "addr1",
      "addressLine1": "28, Anna Nagar",
      "city": "Chennai",
      "state": "Tamil Nadu",
      "pincode": "600028"
    }
  ],
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-20T15:30:00Z"
}
```

**Usage:**
```dart
// From JSON
final profile = UserProfileModel.fromJson(jsonData);

// Access properties
print(profile.name);                    // "John Doe"
print(profile.addresses.length);        // 1
print(profile.addresses[0].city);       // "Chennai"

// To JSON
final json = profile.toJson();
```

**Notes:**
- `addresses` is always a list (empty if no addresses)
- `profileImage` is optional (null if not set)
- `email` is optional (null if not set)
- Addresses are embedded in the profile document

---

### 2. AddressModel

**File:** `lib/features/profile/data/models/address_model.dart`

**Purpose:** Represents a user's saved address.

**Properties:**
```dart
class AddressModel {
  final String id;              // Address unique identifier
  final String addressLine1;    // Primary address line
  final String city;           // City name
  final String state;          // State name
  final String pincode;        // Postal/ZIP code
}
```

**JSON Structure:**
```json
{
  "_id": "addr1",
  "addressLine1": "28, Anna Nagar",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "pincode": "600028"
}
```

**Usage:**
```dart
// From JSON
final address = AddressModel.fromJson(jsonData);

// Access properties
print(address.addressLine1);  // "28, Anna Nagar"
print(address.city);           // "Chennai"
print(address.pincode);        // "600028"

// Full address string
final fullAddress = '${address.addressLine1}, ${address.city}, ${address.state} - ${address.pincode}';
// "28, Anna Nagar, Chennai, Tamil Nadu - 600028"

// To JSON
final json = address.toJson();
```

**Notes:**
- All fields are required
- `pincode` is typically 6 digits (validated by backend)
- Address is part of UserProfileModel's addresses list

---

## Model Relationships

### User → UserProfile Relationship

```
User (Auth Module)
  ├─ id: "user123"
  ├─ mobile: "+919876543210"
  ├─ name: "John Doe"
  └─ ...

UserProfile (Profile Module)
  ├─ id: "profile123"
  ├─ userId: "user123"  ← Links to User
  ├─ name: "John Doe"
  ├─ phone: "+919876543210"
  └─ addresses: [...]
```

**Relationship:**
- One User can have one UserProfile
- UserProfile.userId references User.id
- UserProfile is created after user completes profile (Module 1)

### UserProfile → Address Relationship

```
UserProfile
  ├─ id: "profile123"
  └─ addresses: [
      Address { id: "addr1", ... },
      Address { id: "addr2", ... },
      ...
    ]
```

**Relationship:**
- One UserProfile can have multiple Addresses
- Addresses are embedded in UserProfile document
- Addresses are managed via CRUD operations on UserProfile

---

## JSON Serialization

### From JSON (Deserialization)

All models implement `fromJson()` factory constructors:

```dart
// UserModel
final user = UserModel.fromJson(jsonData);

// UserProfileModel
final profile = UserProfileModel.fromJson(jsonData);

// AddressModel
final address = AddressModel.fromJson(jsonData);
```

**Handling Variations:**
- Models handle both `_id` and `id` fields
- Optional fields handle null values
- Date strings are parsed to DateTime objects
- Nested objects are parsed recursively

### To JSON (Serialization)

All models implement `toJson()` methods:

```dart
// UserModel
final json = user.toJson();

// UserProfileModel
final json = profile.toJson();

// AddressModel
final json = address.toJson();
```

**Output Format:**
- Dates are converted to ISO 8601 strings
- Null values are included in JSON
- Nested objects are serialized recursively

---

## Model Usage Examples

### Creating a User from API Response

```dart
// API Response
final response = await http.get(uri);
final jsonData = json.decode(response.body);

// Parse User
final user = UserModel.fromJson(jsonData['user']);
print('User: ${user.name}');
```

### Creating Profile with Addresses

```dart
// API Response
final response = await http.get(uri);
final jsonData = json.decode(response.body);

// Parse Profile
final profile = UserProfileModel.fromJson(jsonData['profile']);

// Access Addresses
for (final address in profile.addresses) {
  print('Address: ${address.addressLine1}');
}
```

### Creating Address for API Request

```dart
// Create Address
final address = AddressModel(
  id: '',  // New address, no ID yet
  addressLine1: '28, Anna Nagar',
  city: 'Chennai',
  state: 'Tamil Nadu',
  pincode: '600028',
);

// Convert to JSON for API
final json = address.toJson();
// Send to POST /api/user/profile/address/add
```

### Updating Profile

```dart
// Load existing profile
final profile = UserProfileModel.fromJson(existingJson);

// Create updated profile (immutable)
final updatedProfile = UserProfileModel(
  id: profile.id,
  userId: profile.userId,
  name: 'John Smith',  // Updated name
  phone: profile.phone,
  email: 'newemail@example.com',  // Updated email
  profileImage: profile.profileImage,
  addresses: profile.addresses,
  createdAt: profile.createdAt,
  updatedAt: DateTime.now(),  // Updated timestamp
);

// Convert to JSON for API
final json = updatedProfile.toJson();
// Send to PUT /api/user/profile/update
```

---

## Model Conversion

### UserModel to UserProfileModel

When a user completes their profile, a UserProfileModel is created:

```dart
// From User (Module 1)
final user = UserModel.fromJson(userJson);

// Create UserProfile (Module 2)
final profile = UserProfileModel(
  id: '',  // New profile
  userId: user.id,
  name: user.name,
  phone: user.mobile,
  email: user.email,
  profileImage: null,
  addresses: [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

---

## Model Files Structure

```
lib/features/
├── auth/
│   └── data/
│       └── models/
│           ├── user_model.dart
│           ├── login_response_model.dart
│           └── country_code.dart
│
└── profile/
    └── data/
        └── models/
            ├── user_profile_model.dart
            └── address_model.dart
```

---

## Best Practices

1. **Immutable Models:** All models are immutable (final properties)
2. **Null Safety:** Use nullable types (`String?`) for optional fields
3. **JSON Handling:** Always handle both `_id` and `id` fields
4. **Date Parsing:** Use `DateTime.parse()` with error handling
5. **Type Safety:** Use strong typing, avoid dynamic types
6. **Validation:** Validate data in models or use separate validators

---

## Common Issues & Solutions

### Issue: Date parsing fails
**Solution:** Always check for null before parsing:
```dart
createdAt: json['createdAt'] != null
    ? DateTime.parse(json['createdAt'])
    : DateTime.now(),
```

### Issue: Missing `_id` field
**Solution:** Handle both `_id` and `id`:
```dart
id: json['_id'] ?? json['id'] ?? '',
```

### Issue: Nested object parsing
**Solution:** Parse nested objects explicitly:
```dart
addresses: (json['addresses'] as List<dynamic>?)
    ?.map((a) => AddressModel.fromJson(a as Map<String, dynamic>))
    .toList() ?? [],
```

---

**End of Models Documentation**
