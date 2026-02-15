import 'user_model.dart';

class LoginResponseModel {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final UserModel? user;
  final Tokens? tokens;
  final bool? requiresProfileCompletion;
  final String? mobile;
  final int? expiresIn;

  LoginData({
    this.user,
    this.tokens,
    this.requiresProfileCompletion,
    this.mobile,
    this.expiresIn,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      tokens: json['tokens'] != null ? Tokens.fromJson(json['tokens']) : null,
      requiresProfileCompletion: json['requiresProfileCompletion'],
      mobile: json['mobile'],
      expiresIn: json['expiresIn'],
    );
  }
}

class Tokens {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  Tokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) {
    // Backend returns expiresIn as int (604800 = 7 days in seconds)
    // Convert to String for consistency
    final expiresInValue = json['expiresIn'];
    String expiresInString = '';
    
    if (expiresInValue != null) {
      if (expiresInValue is int) {
        expiresInString = expiresInValue.toString();
      } else if (expiresInValue is String) {
        expiresInString = expiresInValue;
      } else {
        // Fallback: convert any other type to string
        expiresInString = expiresInValue.toString();
      }
    }
    
    return Tokens(
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: (json['refreshToken'] as String?) ?? '',
      expiresIn: expiresInString,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }
}

