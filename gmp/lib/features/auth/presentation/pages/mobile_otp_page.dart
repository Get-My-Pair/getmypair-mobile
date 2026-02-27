import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../data/models/country_code.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/country_code_picker.dart';
import 'otp_page.dart';

class MobileOTPPage extends StatefulWidget {
  const MobileOTPPage({super.key});

  @override
  State<MobileOTPPage> createState() => _MobileOTPPageState();
}

class _MobileOTPPageState extends State<MobileOTPPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  CountryCode _selectedCountry = CountryCode.popularCountries[0]; // India default
  bool _termsAccepted = false;
  String? _phoneError;
  bool _isSendingOTP = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool get _isValid {
    final phoneLength = _phoneController.text
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    return phoneLength == 10 && _termsAccepted;
  }

  void _validatePhone(String value) {
    setState(() {
      final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.isEmpty) {
        _phoneError = null;
      } else if (cleanPhone.length < 10) {
        _phoneError = 'Phone number must be 10 digits';
      } else if (cleanPhone.length > 10) {
        _phoneError = 'Phone number cannot exceed 10 digits';
      } else {
        _phoneError = null;
      }
    });
  }

  void _sendOTP() {
    if (!_isValid) return;

    setState(() {
      _isSendingOTP = true;
    });

    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final fullMobile = '${_selectedCountry.dialCode}$cleanPhone';

    context.read<AuthBloc>().add(AuthSendOTP(fullMobile));
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
              Clipboard.setData(ClipboardData(text: otp));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('OTP copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OTPPage(
                    mobile: mobile,
                    countryCode: _selectedCountry.dialCode,
                    phoneNumber: _phoneController.text,
<<<<<<< HEAD
=======
                    prefilledOtp: otp,
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590
                  ),
                ),
              );
            },
            child: const Text('Copy & Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OTPPage(
                    mobile: mobile,
                    countryCode: _selectedCountry.dialCode,
                    phoneNumber: _phoneController.text,
<<<<<<< HEAD
=======
                    prefilledOtp: otp,
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590
                  ),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          leading: IconButton(
            color: const Color.fromARGB(255, 48, 27, 11),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOTPSent) {
            setState(() {
              _isSendingOTP = false;
            });
            if (state.otp != null && state.otp!.isNotEmpty) {
              _showOTPDialog(context, state.otp!, state.mobile);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OTPPage(
                    mobile: state.mobile,
                    countryCode: _selectedCountry.dialCode,
                    phoneNumber: _phoneController.text,
                  ),
                ),
              );
            }
          } else if (state is AuthError) {
            setState(() {
              _isSendingOTP = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),

                const SizedBox(height: 10),

                // Phone Input Card
                _buildPhoneInputCard(),

                const SizedBox(height: 10),

                // Terms & Privacy
                _buildTermsCheckbox(),

                const SizedBox(height: 10),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isValid && !_isSendingOTP) ? _sendOTP : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isValid ? 2 : 0,
                    ),
                    child: _isSendingOTP
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset('assets/images/logo.png', width: 300, height: 300),
        ),

        // Title
        Center(
          child: const Text(
            'Welcome to Get My Pair',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tagline
        Center(
          child: Text(
            'Find shoes. Fix shoes. Everything you need, all in one place.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your phone number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'We\'ll send you a verification code',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Country Code + Phone Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country Code Picker
              CountryCodePicker(
                selectedCountry: _selectedCountry,
                onChanged: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                },
              ),

              const SizedBox(width: 12),

              // Phone Input
              Expanded(
                child: CustomTextField(
                  controller: _phoneController,
                  // hintText: '9876543210',
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  focusNode: _phoneFocusNode,
                  maxLength: 10,
                  errorText: _phoneError,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: _validatePhone,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Info Text
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter your 10-digit mobile number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _termsAccepted = !_termsAccepted;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _termsAccepted ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _termsAccepted ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: _termsAccepted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.textOnPrimary,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'By continuing, you agree to receive SMS',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

