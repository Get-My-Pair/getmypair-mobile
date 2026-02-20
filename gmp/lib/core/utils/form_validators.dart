import 'package:reactive_forms/reactive_forms.dart';

/// Form Validators for all input fields
class FormValidators {
  FormValidators._();

  // Name Validation
  static Map<String, dynamic>? Function(AbstractControl<dynamic>) nameValidator(
      {int minLength = 2, int maxLength = 50}) {
    return (control) {
      final value = control.value as String?;
      if (value == null || value.isEmpty) {
        return {'required': true};
      }
      if (value.length < minLength) {
        return {'minLength': {'requiredLength': minLength}};
      }
      if (value.length > maxLength) {
        return {'maxLength': {'requiredLength': maxLength}};
      }
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
        return {'pattern': 'Only letters and spaces allowed'};
      }
      return null;
    };
  }

  // Phone Validation
  static Map<String, dynamic>? Function(AbstractControl<dynamic>)
      phoneValidator({int length = 10}) {
    return (control) {
      final value = control.value as String?;
      if (value == null || value.isEmpty) {
        return {'required': true};
      }
      final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length != length) {
        return {'phone': 'Phone must be $length digits'};
      }
      return null;
    };
  }

  // Email Validation
  static Map<String, dynamic>? emailValidator(AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return {'email': 'Enter a valid email address'};
    }
    return null;
  }

  // Optional Email Validation
  static Map<String, dynamic>? optionalEmailValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return {'email': 'Enter a valid email address'};
    }
    return null;
  }

  // City Validation
  static Map<String, dynamic>? cityValidator(AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    if (value.length < 2) {
      return {'minLength': {'requiredLength': 2}};
    }
    return null;
  }

  // Address Validation
  static Map<String, dynamic>? addressValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    if (value.length < 10) {
      return {'minLength': {'requiredLength': 10}};
    }
    return null;
  }

  // Shop Name Validation
  static Map<String, dynamic>? shopNameValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    if (value.length < 3) {
      return {'minLength': {'requiredLength': 3}};
    }
    return null;
  }

  // Experience Validation
  static Map<String, dynamic>? experienceValidator(
      AbstractControl<dynamic> control) {
    final value = control.value;
    if (value == null) {
      return {'required': true};
    }
    int years;
    if (value is String) {
      years = int.tryParse(value) ?? -1;
    } else if (value is int) {
      years = value;
    } else {
      return {'invalid': 'Enter a valid number'};
    }
    if (years < 0 || years > 50) {
      return {'range': 'Experience must be between 0 and 50 years'};
    }
    return null;
  }

  // Vehicle Type Validation
  static Map<String, dynamic>? vehicleTypeValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    return null;
  }

  // License Number Validation
  static Map<String, dynamic>? licenseValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    // Indian license format: XX00 0000000000 (state code + year + number)
    if (value.length < 10) {
      return {'license': 'Enter a valid license number'};
    }
    return null;
  }

  // Skills Validation (at least one required)
  static Map<String, dynamic>? skillsValidator(
      AbstractControl<dynamic> control) {
    final value = control.value;
    if (value == null) {
      return {'required': true};
    }
    if (value is List && value.isEmpty) {
      return {'required': 'Select at least one skill'};
    }
    return null;
  }

  // File/Image Validation
  static Map<String, dynamic>? fileRequiredValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': 'Please upload the required document'};
    }
    return null;
  }

  // Password Validation
  static Map<String, dynamic>? passwordValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    if (value.length < 6) {
      return {'minLength': {'requiredLength': 6}};
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return {'uppercase': 'Password must contain an uppercase letter'};
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return {'number': 'Password must contain a number'};
    }
    return null;
  }

  // Pincode Validation
  static Map<String, dynamic>? pincodeValidator(
      AbstractControl<dynamic> control) {
    final value = control.value as String?;
    if (value == null || value.isEmpty) {
      return {'required': true};
    }
    if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return {'pincode': 'Enter a valid 6-digit pincode'};
    }
    return null;
  }
}

/// Error messages helper
class ValidationMessages {
  static String getErrorMessage(String errorKey, Map<String, dynamic>? error) {
    switch (errorKey) {
      case 'required':
        return 'This field is required';
      case 'minLength':
        final minLength = error?['requiredLength'] ?? 2;
        return 'Minimum $minLength characters required';
      case 'maxLength':
        final maxLength = error?['requiredLength'] ?? 50;
        return 'Maximum $maxLength characters allowed';
      case 'email':
        final errorMsg = error?['message'];
        return errorMsg is String ? errorMsg : 'Enter a valid email';
      case 'phone':
        final errorMsg = error?['message'];
        return errorMsg is String ? errorMsg : 'Enter a valid phone number';
      case 'pattern':
        final errorMsg = error?['message'];
        return errorMsg is String ? errorMsg : 'Invalid format';
      case 'license':
        return 'Enter a valid license number';
      case 'pincode':
        return 'Enter a valid 6-digit pincode';
      case 'uppercase':
        return 'Must contain an uppercase letter';
      case 'number':
        return 'Must contain a number';
      default:
        return 'Invalid input';
    }
  }
}
