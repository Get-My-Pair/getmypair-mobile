import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'profile_completion_page.dart';
import 'package:gmp/features/dashboard/presentation/pages/customer_dashboard_page.dart';

class OTPPage extends StatefulWidget {
  final String mobile;
  final String? countryCode;
  final String? phoneNumber;
  /// Pre-filled OTP when coming from dev dialog (Continue / Copy & Continue).
  final String? prefilledOtp;

  const OTPPage({
    super.key,
    required this.mobile,
    this.countryCode,
    this.phoneNumber,
    this.prefilledOtp,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _otp = '';
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    final pre = widget.prefilledOtp?.trim().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (pre.length == 6) {
      _otp = pre;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Normalized 6-digit OTP for initial field value, or null if none.
  String? get _initialOtpValue {
    final pre = widget.prefilledOtp?.trim().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return pre.length == 6 ? pre : null;
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _verifyOTP() {
    if (_otp.length != 6) return;

    context.read<AuthBloc>().add(
      AuthVerifyOTP(
        mobile: widget.mobile,
        otp: _otp,
      ),
    );
  }

  void _resendOTP() {
    if (!_canResend) return;

    context.read<AuthBloc>().add(AuthSendOTP(widget.mobile));
    _startResendTimer();
  }

  void _showOTPDialog(BuildContext context, String otp) {
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
            },
            child: const Text('Copy & Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get _displayPhoneNumber {
    if (widget.countryCode != null && widget.phoneNumber != null) {
      return '${widget.countryCode} ${widget.phoneNumber}';
    }
    return widget.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOTPVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Phone verified successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );

            if (state.requiresProfileCompletion) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProfileCompletionPage(
                    mobile: widget.mobile,
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const CustomerDashboardPage(),
                ),
                (route) => false,
              );
            }
          } else if (state is AuthOTPSent) {
            if (state.otp != null && state.otp!.isNotEmpty) {
              _showOTPDialog(context, state.otp!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('OTP sent successfully'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          } else if (state is AuthError) {
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
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // OTP Input Card
                  _buildOtpInputCard(),

                  const SizedBox(height: 32),

                  // Verify Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      final isEnabled = _otp.length == 6;
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isEnabled ? _verifyOTP : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                            disabledForegroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: isEnabled ? 2 : 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Resend OTP
                  _buildResendSection(),

                  const SizedBox(height: 24),

                  // Help Text
                  _buildHelpText(),
                ],
              ),
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
        Row(
          children: [
            Expanded(
              child: const Text(
                'Verify Phone',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72, maxHeight: 72),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ],
        ),

        const SizedBox(height: 12),

        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Code sent to '),
              TextSpan(
                text: _displayPhoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Enter 6-digit code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: MaterialPinField(
            length: 6,
            initialValue: _initialOtpValue,
            onCompleted: (value) {
              setState(() {
                _otp = value;
              });
            },
            onChanged: (value) {
              setState(() {
                _otp = value;
              });
            },
            theme: MaterialPinTheme(
              shape: MaterialPinShape.outlined,
              cellSize: const Size(56, 56),
              spacing: 8,
              borderRadius: BorderRadius.circular(8),
              borderWidth: 2,
              borderColor: AppColors.border,
              focusedBorderColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              entryAnimation: MaterialPinAnimation.scale,
              animationDuration: const Duration(milliseconds: 300),
              animationCurve: Curves.easeOut,
            ),
            ),
          ),

          const SizedBox(height: 24),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _resendCountdown > 0
                      ? AppColors.accent
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  _resendCountdown > 0
                      ? 'Code expires in ${_formatTime(_resendCountdown)}'
                      : 'Code expired',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _resendCountdown > 0
                        ? AppColors.textSecondary
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Didn\'t receive the code?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: _canResend ? _resendOTP : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.textTertiary,
            ),
            child: Text(
              _canResend
                  ? 'Resend OTP'
                  : 'Resend in ${_formatTime(_resendCountdown)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline_rounded, size: 20, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'OTP is valid for 5 minutes. Maximum 3 attempts allowed.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
      
        ]
      )
    );
  }
}

