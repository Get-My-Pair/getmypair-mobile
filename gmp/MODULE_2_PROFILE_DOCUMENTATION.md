# MODULE 2 – PROFILE DOCUMENTATION .

## Table of Contents
1. [Overview](#overview)
2. [Complete Profile CRUD Flow](#complete-profile-crud-flow)
3. [API Endpoints](#api-endpoints)
4. [Screen Documentation](#screen-documentation)
5. [State Management](#state-management)
6. [Models](#models)
7. [Address Management](#address-management)

---

## Overview

Module 2 handles all profile-related operations including viewing, editing, and managing user profiles and addresses. It provides a complete CRUD interface for user profile data.

**Key Features:**
- View user profile
- Edit profile information
- Upload profile image
- Manage saved addresses (Add, Edit, Delete)
- Profile image cropping
- Form validation

---

## Complete Profile CRUD Flow

### View Profile Flow

```
CustomerDashboardPage
      ↓
Tap Profile Icon (Bottom Nav)
      ↓
ProfilePage
      ↓
GET /api/user/profile/me
      ↓
Display Profile Information
```

### Create Profile Flow (if not exists)

```
ProfileCompletionPage (Module 1)
      ↓
POST /api/auth/complete-profile
      ↓
Profile Created
      ↓
CustomerDashboardPage
```

### Update Profile Flow

```
ProfilePage
      ↓
Tap "Edit Profile"
      ↓
ProfileEditPage (EditProfileWidget)
      ↓
Edit:
  • Name
  • Email
  • Profile Image
      ↓
PUT /api/user/profile/update
      ↓
ProfileViewPage (Updated)
```

### Upload Profile Image Flow

```
ProfileEditPage
      ↓
Tap Profile Image / "Change Photo"
      ↓
Select Image Source:
  ├─ Gallery
  └─ Camera
      ↓
Crop Image
      ↓
POST /api/user/profile/upload-image
      ↓
ProfileViewPage (Updated Image)
```

### Address CRUD Flow

#### Add Address
```
ProfilePage
      ↓
Tap "Saved Addresses"
      ↓
AddressListPage (SavedAddressesPage)
      ↓
Tap "Add Address" (FAB)
      ↓
AddressFormSheet (Bottom Sheet)
      ↓
Fill:
  • Address Line 1
  • City
  • State
  • Pincode
      ↓
POST /api/user/profile/address/add
      ↓
AddressListPage (Updated)
```

#### Update Address
```
AddressListPage
      ↓
Tap "Edit" on Address Card
      ↓
AddressFormSheet (Pre-filled)
      ↓
Edit Address Fields
      ↓
PUT /api/user/profile/address/update/:addressId
      ↓
AddressListPage (Updated)
```

#### Delete Address
```
AddressListPage
      ↓
Tap "Delete" on Address Card
      ↓
Confirm Delete Dialog
      ↓
DELETE /api/user/profile/address/delete/:addressId
      ↓
AddressListPage (Updated)
```

---

## API Endpoints

### 1. GET /api/user/profile/me

**Purpose:** Get current user's profile

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "profile": {
    "_id": "profile123",
    "userId": "user123",
    "name": "John Doe",
    "phone": "+919876543210",
    "email": "john@example.com",
    "profileImage": "https://example.com/image.jpg",
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
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Profile not found"
}
```

---

### 2. POST /api/user/profile/create

**Purpose:** Create a new user profile (usually called from Module 1)

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "profile": {
    "_id": "profile123",
    "userId": "user123",
    "name": "John Doe",
    "phone": "+919876543210",
    "email": "john@example.com",
    "addresses": [],
    "createdAt": "2024-01-15T10:00:00Z",
    "updatedAt": "2024-01-15T10:00:00Z"
  }
}
```

---

### 3. PUT /api/user/profile/update

**Purpose:** Update user profile information

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "name": "John Smith",
  "email": "johnsmith@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "profile": {
    "_id": "profile123",
    "userId": "user123",
    "name": "John Smith",
    "phone": "+919876543210",
    "email": "johnsmith@example.com",
    "profileImage": "https://example.com/image.jpg",
    "addresses": [...],
    "updatedAt": "2024-01-20T15:30:00Z"
  }
}
```

---

### 4. POST /api/user/profile/upload-image

**Purpose:** Upload profile image

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body (Form Data):**
```
image: <file>
```

**Response:**
```json
{
  "success": true,
  "profileImage": "https://example.com/uploads/profile123.jpg",
  "profile": {
    "_id": "profile123",
    "profileImage": "https://example.com/uploads/profile123.jpg",
    "updatedAt": "2024-01-20T16:00:00Z"
  }
}
```

---

### 5. POST /api/user/profile/address/add

**Purpose:** Add a new address to user profile

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "addressLine1": "28, Anna Nagar",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "pincode": "600028"
}
```

**Response:**
```json
{
  "success": true,
  "address": {
    "_id": "addr1",
    "addressLine1": "28, Anna Nagar",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "pincode": "600028"
  },
  "profile": {
    "_id": "profile123",
    "addresses": [
      {
        "_id": "addr1",
        "addressLine1": "28, Anna Nagar",
        "city": "Chennai",
        "state": "Tamil Nadu",
        "pincode": "600028"
      }
    ]
  }
}
```

---

### 6. PUT /api/user/profile/address/update/:addressId

**Purpose:** Update an existing address

**Headers:**
```
Authorization: Bearer <token>
```

**URL Parameters:**
- `addressId`: String (required)

**Request Body:**
```json
{
  "addressLine1": "30, Anna Nagar",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "pincode": "600029"
}
```

**Response:**
```json
{
  "success": true,
  "address": {
    "_id": "addr1",
    "addressLine1": "30, Anna Nagar",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "pincode": "600029"
  },
  "profile": {
    "_id": "profile123",
    "addresses": [...]
  }
}
```

---

### 7. DELETE /api/user/profile/address/delete/:addressId

**Purpose:** Delete an address

**Headers:**
```
Authorization: Bearer <token>
```

**URL Parameters:**
- `addressId`: String (required)

**Response:**
```json
{
  "success": true,
  "message": "Address deleted successfully",
  "profile": {
    "_id": "profile123",
    "addresses": []
  }
}
```

---

## Screen Documentation

### 1. ProfilePage

**File:** `lib/features/profile/presentation/pages/profile_page.dart`

**Purpose:** Main profile view page displaying user information and settings.

**Features:**
- Profile header with:
  - Profile image (or initials avatar)
  - User name
  - Phone number
- Quick action chips:
  - My Orders
  - Wishlist
  - Carbon Credits
  - Help Center
- Account Settings section:
  - Edit Profile
  - Saved Addresses (with count)
  - Manage Devices
  - Select Language
  - Saved Cards / Debit Cards
  - Notification Settings
- Feedback & Information section:
  - Terms & Policies
  - Licenses
  - Browse FAQs
- Logout button

**User Actions:**
- Tap "Edit Profile" → Navigate to `EditProfileWidget`
- Tap "Saved Addresses" → Navigate to `SavedAddressesPage`
- Tap "Manage Devices" → Navigate to `ManageDevicesPage`
- Tap "Logout" → Show confirmation dialog → Logout

**State Management:**
- Uses `ProfileBloc` for state management
- Listens to `ProfileBloc` for profile updates
- Loads profile on init via `ProfileLoadRequested` event

**API Call:**
```dart
context.read<ProfileBloc>().add(ProfileLoadRequested(token));
```

**Route:** `/profile`

**Navigation:**
- Accessed from `CustomerDashboardPage` bottom navigation
- Can also be accessed via route

---

### 2. ProfileEditPage (EditProfileWidget)

**File:** `lib/features/profile/presentation/widgets/edit_profile_widget.dart`

**Purpose:** Page for editing user profile information and uploading profile image.

**Features:**
- Profile image display with:
  - Current image or initials avatar
  - Camera icon overlay
  - "Change Photo" button
  - Image cropping support
- Form fields:
  - **Full Name** (editable)
    - Required
    - Min 2 characters
    - Text capitalization: Words
  - **Date of Birth** (read-only)
    - Displayed but not editable
    - Set during registration
  - **Phone** (read-only)
    - Displayed with "Verified" badge
    - Cannot be changed
  - **Email** (editable)
    - Optional
    - Email validation
- Save Changes button
- Loading states:
  - Profile updating
  - Image uploading

**Image Upload Flow:**
1. Tap profile image or "Change Photo"
2. Select source (Gallery or Camera)
3. Image picker opens
4. Crop image dialog appears
5. Crop and confirm
6. Image uploaded via `POST /api/user/profile/upload-image`
7. Profile updated with new image URL

**Form Validation:**
- Name: Required, min 2 characters
- Email: Optional, must be valid format if provided

**API Calls:**
```dart
// Update profile
context.read<ProfileBloc>().add(ProfileUpdateRequested(
  accessToken: widget.accessToken,
  name: _nameController.text.trim(),
  email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
));

// Upload image
context.read<ProfileBloc>().add(ProfileImageUploadRequested(
  accessToken: widget.accessToken,
  imageBytes: bytes,
  fileName: fileName,
));
```

**Navigation:**
- Back button returns to `ProfilePage`
- On success → Navigate back with updated profile
- On error → Show error snackbar

**Dependencies:**
- `image_picker` - For selecting images
- `crop_your_image` - For cropping images

---

### 3. AddressListPage (SavedAddressesPage)

**File:** `lib/features/profile/presentation/widgets/saved_addresses_page.dart`

**Purpose:** Page for viewing and managing saved addresses.

**Features:**
- Address list display:
  - Address cards with:
    - Location icon
    - Address line 1
    - City, State, Pincode
    - Edit button
    - Delete button
- Empty state:
  - Icon
  - "No saved addresses" message
  - "Add Address" button
- Floating Action Button (FAB):
  - "Add Address" button
  - Opens address form bottom sheet
- Loading states during address operations

**User Actions:**
- Tap "Add Address" (FAB) → Open `AddressFormSheet`
- Tap "Edit" on address card → Open `AddressFormSheet` (pre-filled)
- Tap "Delete" on address card → Show confirmation dialog → Delete address

**Address Card Display:**
```
┌─────────────────────────────────────┐
│ 28, Anna Nagar          [Edit]   │
│     Chennai, Tamil Nadu - 600028    │
│                            [Delete] │
└─────────────────────────────────────┘
```

**API Calls:**
```dart
// Add address
context.read<ProfileBloc>().add(AddressAddRequested(
  accessToken: accessToken,
  addressLine1: _line1.text.trim(),
  city: _city.text.trim(),
  state: _state.text.trim(),
  pincode: _pincode.text.trim(),
));

// Update address
context.read<ProfileBloc>().add(AddressUpdateRequested(
  accessToken: accessToken,
  addressId: addressId,
  addressLine1: _line1.text.trim(),
  city: _city.text.trim(),
  state: _state.text.trim(),
  pincode: _pincode.text.trim(),
));

// Delete address
context.read<ProfileBloc>().add(AddressDeleteRequested(
  accessToken: accessToken,
  addressId: addressId,
));
```

**Navigation:**
- Back button returns to `ProfilePage`
- Address form opens as bottom sheet modal

---

### 4. AddressFormPage (AddressFormSheet)

**File:** `lib/features/profile/presentation/widgets/saved_addresses_page.dart` (internal widget)

**Purpose:** Bottom sheet form for adding or editing addresses.

**Features:**
- Form fields:
  - **Address Line 1** (required)
    - Text input
    - Placeholder: "e.g. 28, Anna Nagar"
  - **City** (required)
    - Text input
    - Placeholder: "e.g. Chennai"
  - **State** (required)
    - Text input
    - Placeholder: "e.g. Tamil Nadu"
  - **Pincode** (required)
    - Numeric input
    - Placeholder: "6 digits"
- Save/Update button
- Form validation
- Pre-filled when editing existing address

**Form Validation:**
- All fields are required
- Pincode should be numeric
- No specific length validation (handled by backend)

**Modes:**
- **Add Mode:** Empty form, button text: "Save Address"
- **Edit Mode:** Pre-filled form, button text: "Update Address"

**UI:**
- Bottom sheet modal
- Scrollable form
- Keyboard-aware padding
- Rounded top corners

---

## State Management

### ProfileBloc States

**File:** `lib/features/profile/presentation/bloc/profile_state.dart`

1. **ProfileInitial** - Initial state
2. **ProfileLoading** - Loading profile data
3. **ProfileLoaded** - Profile loaded successfully
   - Contains: `UserProfile profile`
4. **ProfileUpdating** - Updating profile
   - Contains: `UserProfile profile`
5. **ProfileImageUploading** - Uploading profile image
   - Contains: `UserProfile profile`
6. **AddressActionLoading** - Performing address action (add/update/delete)
   - Contains: `UserProfile profile`
7. **ProfileError** - Error occurred
   - Contains: `String message`, `UserProfile? profile`

### ProfileBloc Events

**File:** `lib/features/profile/presentation/bloc/profile_event.dart`

1. **ProfileLoadRequested** - Load user profile
   - Contains: `String accessToken`
2. **ProfileUpdateRequested** - Update profile
   - Contains: `String accessToken`, `String name`, `String? email`
3. **ProfileImageUploadRequested** - Upload profile image
   - Contains: `String accessToken`, `Uint8List imageBytes`, `String fileName`
4. **AddressAddRequested** - Add new address
   - Contains: `String accessToken`, `String addressLine1`, `String city`, `String state`, `String pincode`
5. **AddressUpdateRequested** - Update address
   - Contains: `String accessToken`, `String addressId`, `String addressLine1`, `String city`, `String state`, `String pincode`
6. **AddressDeleteRequested** - Delete address
   - Contains: `String accessToken`, `String addressId`

---

## Models

### UserProfileModel

**File:** `lib/features/profile/data/models/user_profile_model.dart`

**Properties:**
```dart
class UserProfileModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final String? profileImage;
  final List<Address> addresses;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**JSON Serialization:**
- `fromJson()` - Parse from API response
- `toJson()` - Convert to JSON for API requests

---

### AddressModel

**File:** `lib/features/profile/data/models/address_model.dart`

**Properties:**
```dart
class AddressModel {
  final String id;
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;
}
```

**JSON Serialization:**
- `fromJson()` - Parse from API response
- `toJson()` - Convert to JSON for API requests

**Example JSON:**
```json
{
  "_id": "addr1",
  "addressLine1": "28, Anna Nagar",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "pincode": "600028"
}
```

---

## Address Management

### Address Operations

#### Adding Address
1. User taps "Add Address" FAB
2. Bottom sheet opens with empty form
3. User fills all required fields
4. Taps "Save Address"
5. API call: `POST /api/user/profile/address/add`
6. Profile updated with new address
7. Bottom sheet closes
8. Address list refreshes

#### Editing Address
1. User taps "Edit" on address card
2. Bottom sheet opens with pre-filled form
3. User modifies fields
4. Taps "Update Address"
5. API call: `PUT /api/user/profile/address/update/:addressId`
6. Profile updated with modified address
7. Bottom sheet closes
8. Address list refreshes

#### Deleting Address
1. User taps "Delete" on address card
2. Confirmation dialog appears
3. User confirms deletion
4. API call: `DELETE /api/user/profile/address/delete/:addressId`
5. Profile updated (address removed)
6. Address list refreshes

### Address Validation

- **Address Line 1:** Required, non-empty
- **City:** Required, non-empty
- **State:** Required, non-empty
- **Pincode:** Required, numeric, typically 6 digits (validated by backend)

---

## Image Upload Flow

### Detailed Image Upload Process

1. **Image Selection:**
   - User taps profile image or "Change Photo"
   - Bottom sheet with options:
     - Choose from gallery
     - Take a photo
   - Image picker opens based on selection

2. **Image Picking:**
   - `ImagePicker` picks image
   - Max dimensions: 2000x2000
   - Quality: 90%
   - Returns `XFile`

3. **Image Cropping:**
   - Original image bytes loaded
   - Crop dialog opens with `Crop` widget
   - User adjusts crop area
   - Taps "Crop" button
   - Cropped bytes returned

4. **Image Upload:**
   - Cropped bytes converted to `Uint8List`
   - File name extracted
   - `ProfileImageUploadRequested` event dispatched
   - Multipart form data created
   - API call: `POST /api/user/profile/upload-image`
   - New image URL returned

5. **Profile Update:**
   - Profile state updated with new image URL
   - UI refreshes to show new image

---

## Security & Validation

### Profile Update Validation
- Name: Required, min 2 characters
- Email: Optional, must be valid email format if provided
- Phone: Read-only, cannot be changed
- DOB: Read-only, set during registration

### Address Validation
- All fields required
- Pincode must be numeric
- Address format validated by backend

### Image Upload
- Max file size: Handled by backend
- Supported formats: JPEG, PNG (handled by image_picker)
- Image cropping ensures consistent aspect ratio

---

## Notes

- Profile is automatically loaded when accessing ProfilePage
- Profile image is optional (shows initials if not set)
- Addresses are stored as part of profile document
- All profile operations require authentication token
- Profile updates are reflected immediately in UI
- Image upload includes cropping step for better UX
- Address operations (add/update/delete) update the entire profile object

---

## Implementation Details

### Token Retrieval
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString(AppConstants.accessTokenKey);
```

### Profile Loading
```dart
context.read<ProfileBloc>().add(ProfileLoadRequested(token));
```

### Image Upload
```dart
final picker = ImagePicker();
final picked = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 2000,
  maxHeight: 2000,
  imageQuality: 90,
);
```

### Form Submission
```dart
if (!_formKey.currentState!.validate()) return;
// Dispatch event
context.read<ProfileBloc>().add(ProfileUpdateRequested(...));
```

---

## Related Files

- **Profile Repository:** `lib/features/profile/domain/repositories/profile_repository.dart`
- **Profile Data Source:** `lib/features/profile/data/datasources/profile_remote_datasource.dart`
- **Profile Entities:** `lib/features/profile/domain/entities/`
- **Routes:** `lib/routes.dart`
- **Injection Container:** `lib/injection_container.dart`

---

## Integration with Module 1

- Profile completion in Module 1 creates initial profile
- Token from Module 1 authentication is used for all profile API calls
- Profile page is accessible from CustomerDashboardPage (Module 1)
- Profile state is managed separately but uses same authentication token

---

**End of Module 2 Documentation**
