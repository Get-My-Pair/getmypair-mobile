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
      return 'Please enter your date of birth';
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
    if (dob.month > today.month ||
        (dob.month == today.month && dob.day > today.day)) {
      age -= 1;
    }
    if (age > 100) {
      return 'Please enter a valid date of birth';
    }

    return null;
  }

  /// Formats [date] as `DD/MM/YYYY`.
  static String formatDateOfBirth(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  /// Inserts `/` separators while the user types digits for DD/MM/YYYY.
  static String maskDateOfBirthInput(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Parses a `DD/MM/YYYY` string. Incomplete input returns null date / null error.
  static ({DateTime? date, String? error}) parseDateOfBirth(
    String? value, {
    bool requireAdult = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return (date: null, error: null);
    }
    final text = value.trim();
    if (text.length < 10) {
      return (date: null, error: null);
    }
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (match == null) {
      return (date: null, error: 'Use DD/MM/YYYY format');
    }
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) {
      return (date: null, error: 'Use DD/MM/YYYY format');
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return (date: null, error: 'Please enter a valid date');
    }
    DateTime dob;
    try {
      dob = DateTime(year, month, day);
      if (dob.year != year || dob.month != month || dob.day != day) {
        return (date: null, error: 'Please enter a valid date');
      }
    } catch (_) {
      return (date: null, error: 'Please enter a valid date');
    }

    final baseError = validateDateOfBirth(dob);
    if (baseError != null) {
      return (date: null, error: baseError);
    }

    if (requireAdult) {
      final now = DateTime.now();
      var age = now.year - dob.year;
      if (dob.month > now.month ||
          (dob.month == now.month && dob.day > now.day)) {
        age -= 1;
      }
      if (age < 18) {
        return (date: null, error: 'You must be at least 18 years old');
      }
    }

    return (date: dob, error: null);
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your gender';
    }
    return null;
  }
}

