import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'ai_onboarding_page.dart';

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
    final pre =
        widget.prefilledOtp?.trim().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
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
    final pre =
        widget.prefilledOtp?.trim().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
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
    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      AuthVerifyOTP(mobile: widget.mobile, otp: _otp),
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
            const Text('Your OTP code is:', style: TextStyle(fontSize: 16)),
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
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
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
    final screen = MediaQuery.sizeOf(context);
    final cardTop = screen.height * 0.277;
    final horizontal = Responsive.horizontalPaddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.footwearHeroStart,
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

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => AiOnboardingPage(
                  mobile: widget.mobile,
                  requiresProfileCompletion: state.requiresProfileCompletion,
                ),
              ),
            );
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment(0.22, -1.07),
                    startAngle: -0.55,
                    endAngle: 5.73,
                    colors: [
                      Color(0xFF09E0FF),
                      Color(0xFF0F6876),
                      Color(0xFF062F35),
                      Color(0xFF062F35),
                    ],
                    stops: [0.05, 0.44, 0.57, 1],
                    transform: GradientRotation(-0.55),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 20,
              top: 86,
              child: Text(
                'Hello!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFDFE7E9),
                  fontSize: 34,
                  fontFamily: 'Boldonse',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Positioned(
              left: 23,
              top: 161,
              right: 23,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Welcome to your ',
                      style: TextStyle(
                        color: Color(0xFFDFE7E9),
                        fontSize: 24,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: 'solecial hub',
                      style: TextStyle(
                        color: Color(0xFFDFE7E9),
                        fontSize: 24,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: cardTop,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = constraints.maxWidth;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: cardW,
                      height: constraints.maxHeight,
                      child: Container(
                        decoration: const ShapeDecoration(
                          color: Color(0xFFD9D9D9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(10, 0),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: SafeArea(
                            top: false,
                            bottom: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(
                                      horizontal,
                                      60,
                                      horizontal,
                                      16,
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Text(
                                            'Verify Phone',
                                            style: TextStyle(
                                              color: Color(0xFF062F35),
                                              fontSize: 24,
                                              fontFamily: 'Boldonse',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Code sent to $_displayPhoneNumber',
                                            style: const TextStyle(
                                              color: Color(0xFF062F35),
                                              fontSize: 20,
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          _buildOtpInputCard(context),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontal,
                                    0,
                                    horizontal,
                                    16,
                                  ),
                                  child: BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, state) {
                                      final isLoading = state is AuthLoading;
                                      final isEnabled = _otp.length == 6;
                                      return SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: isEnabled
                                              ? _verifyOTP
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0F6876,
                                            ),
                                            foregroundColor:
                                                AppColors.textOnPrimary,
                                            disabledBackgroundColor:
                                                const Color(
                                                  0xFF0F6876,
                                                ).withValues(alpha: 0.65),
                                            disabledForegroundColor: AppColors
                                                .textOnPrimary
                                                .withValues(alpha: 0.95),
                                            elevation: 4,
                                            shadowColor: const Color(
                                              0x19000000,
                                            ),
                                            side: const BorderSide(
                                              width: 1,
                                              color: Color(0xFF09DFFF),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          AppColors
                                                              .textOnPrimary,
                                                        ),
                                                  ),
                                                )
                                              : const Text(
                                                  'Verify OTP',
                                                  style: TextStyle(
                                                    color: Color(0xFFDFE7E9),
                                                    fontSize: 14,
                                                    fontFamily: 'Boldonse',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titleSize = Responsive.fontSize(context, 32);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Verify Phone',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxLogoSizeOf(context, 0.18),
                maxHeight: Responsive.maxLogoSizeOf(context, 0.18),
              ),
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

  Widget _buildOtpInputCard(BuildContext context) {
    const cellSize = 36.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Enter 6 digit code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF062F35),
              fontSize: 20,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
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
                cellSize: const Size(cellSize, 48),
                spacing: 20,
                borderRadius: BorderRadius.circular(5),
                borderWidth: 1,
                borderColor: const Color(0x56062F35),
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

          const SizedBox(height: 50),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x66DFE7E9),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: Colors.black.withValues(alpha: 0.34),
                ),
                const SizedBox(width: 14),
                Text(
                  _resendCountdown > 0
                      ? 'Code expires in ${_formatTime(_resendCountdown)}'
                      : 'Code expired',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                    color: _resendCountdown > 0
                        ? Colors.black.withValues(alpha: 0.34)
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
        ],
      ),
    );
  }
}
