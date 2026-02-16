import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_page.dart';

class MobileOTPPage extends StatefulWidget {
  const MobileOTPPage({super.key});

  @override
  State<MobileOTPPage> createState() => _MobileOTPPageState();
}

class _MobileOTPPageState extends State<MobileOTPPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _sendOTP() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mobile = _mobileController.text.trim();
    // Ensure mobile has + prefix if it doesn't
    String normalizedMobile = mobile;
    if (mobile.isNotEmpty && !mobile.startsWith('+')) {
      normalizedMobile = '+91$mobile';
    }

    context.read<AuthBloc>().add(AuthSendOTP(normalizedMobile));
  }

  void _showOTPDialog(BuildContext context, String otp, String mobile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('OTP Code (Development)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your OTP code is:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                otp,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is shown only in development mode.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Copy OTP to clipboard
              Clipboard.setData(ClipboardData(text: otp));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('OTP copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
              // Navigate to OTP verification screen after copying
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OTPPage(mobile: mobile),
                ),
              );
            },
            child: const Text('Copy & Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to OTP verification screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OTPPage(mobile: mobile),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String? _validateMobile(String? value) {
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOTPSent) {
          // Show OTP in dialog if available (development mode)
          if (state.otp != null && state.otp!.isNotEmpty) {
            _showOTPDialog(context, state.otp!, state.mobile);
          } else {
            // Navigate to OTP verification screen if no OTP dialog
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OTPPage(mobile: state.mobile),
              ),
            );
          }
        } else if (state is AuthError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('Enter Mobile Number'),
              elevation: 0,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      
                      // Icon
                      Icon(
                        Icons.phone_android,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                      
                      // Title
                      Text(
                        'Enter Your Mobile Number',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'We\'ll send you a verification code',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Mobile Number Input
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '+1234567890',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: _validateMobile,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\)\s]')),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Send OTP Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Send OTP',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                        ),
                      ),
                      const Spacer(),
                      
                      // Terms and Privacy
                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

