class Validators {
  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }

    // Normalize: keep only digits and optional leading +
    final normalized = value.replaceAll(RegExp(r'[^0-9+]'), '');

    // Must be digits only, with optional leading +
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(normalized)) {
      return 'Mobile number can contain digits only';
    }

    // Strip country code when present and validate local part
    String digitsOnly = normalized.replaceAll('+', '');

    // Enforce exact 10-digit mobile numbers
    if (digitsOnly.length != 10) {
      return 'Mobile number must be 10 digits';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 100) {
      return 'Name must be less than 100 characters';
    }
    // Only allow alphabets and spaces (no digits or special characters)
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can contain only letters and spaces';
    }
    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only digits';
    }
    return null;
  }

  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Please select your date of birth';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dob = DateTime(value.year, value.month, value.day);

    // Future date is not allowed
    if (dob.isAfter(today)) {
      return 'Date of birth cannot be in the future';
    }

    // Optional sanity check: treat extremely old dates as invalid
    int age = today.year - dob.year;
    if (age > 100) {
      return 'Please enter a valid date of birth';
    }
    
    return null;
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your gender';
    }
    return null;
  }
}

