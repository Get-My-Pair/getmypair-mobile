import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _user = await _storageService.getUser();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendOTP(String mobile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.sendOTP(mobile);
      _isLoading = false;
      notifyListeners();

      if (response.success) {
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String mobile, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.verifyOTP(mobile, otp);
      _isLoading = false;

      if (response.success) {
        if (response.data?.requiresProfileCompletion == true) {
          // New user - needs profile completion
          notifyListeners();
          return {
            'success': true,
            'requiresProfileCompletion': true,
            'mobile': mobile,
          };
        } else {
          // Existing user - login successful
          _user = await _storageService.getUser();
          _isAuthenticated = true;
          notifyListeners();
          return {
            'success': true,
            'requiresProfileCompletion': false,
            'user': _user,
          };
        }
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage ?? 'Failed to verify OTP',
      };
    }
  }

  Future<bool> completeProfile({
    required String mobile,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.completeProfile(
        mobile: mobile,
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      _isLoading = false;

      if (response.success) {
        _user = await _storageService.getUser();
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();

    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
