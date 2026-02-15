class Validators {
  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    
    // Remove any spaces, dashes, or parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it starts with + or is a valid number
    if (cleaned.startsWith('+')) {
      if (cleaned.length < 10) {
        return 'Please enter a valid mobile number';
      }
    } else {
      if (cleaned.length < 10) {
        return 'Please enter a valid mobile number';
      }
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
    final age = now.year - value.year;
    
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    
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

