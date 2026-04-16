import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'ai_onboarding_page.dart';

class OTPPage extends StatefulWidget {
  const OTPPage({
    super.key,
    required this.mobile,
    this.countryCode,
    this.phoneNumber,
    this.prefilledOtp,
  });

  final String mobile;
  final String? countryCode;
  final String? phoneNumber;
  final String? prefilledOtp;

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  static const Color _kPrimary = Color(0xFF062F35);
  static const Color _kAccent = Color(0xFF0F6876);
  static const Color _kOnGradient = Color(0xFFFFFFFF);
  static const Color _kPanel = Color(0xFFD9D9D9);
  static const Color _kOtpBorder = Color(0x56062F35);
  static const double _kPanelRadius = 28;

  static const String _kClockIconUrl =
      'https://www.figma.com/api/mcp/asset/cc06893c-2fe8-4c01-9422-ece708223602';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _otp = '';
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    final prefilled = _cleanOtp(widget.prefilledOtp);
    if (prefilled.length == 6) {
      _otp = prefilled;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _cleanOtp(String? value) => (value ?? '').trim().replaceAll(RegExp(r'[^0-9]'), '');

  String? get _initialOtpValue {
    final value = _cleanOtp(widget.prefilledOtp);
    return value.length == 6 ? value : null;
  }

  String get _displayPhoneNumber {
    if (widget.countryCode != null && widget.phoneNumber != null) {
      return '${widget.countryCode} ${widget.phoneNumber}';
    }
    return widget.mobile;
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _verifyOtp() {
    if (_otp.length != 6) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthVerifyOTP(mobile: widget.mobile, otp: _otp));
  }

  void _resendOtp() {
    if (!_canResend) return;
    context.read<AuthBloc>().add(AuthSendOTP(widget.mobile));
    _startResendTimer();
  }

  void _showOtpDialog(BuildContext context, String otp) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('OTP Code (Development)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your OTP code is:'),
            const SizedBox(height: 10),
            SelectableText(
              otp.isEmpty ? '—' : otp,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: otp));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('OTP copied to clipboard')),
              );
            },
            child: const Text('Copy & Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / Responsive.designFrameWidth).clamp(0.88, 1.14);
    final titleSize = (34.0 * scale).clamp(28.0, 39.0);
    final welcomeSize = (24.0 * scale).clamp(18.0, 28.0);
    final panelRadius = (28.0 * scale).clamp(20.0, 32.0);
    final pageTitleSize = (24.0 * scale).clamp(21.0, 28.0);
    final pageBodySize = (20.0 * scale).clamp(16.0, 22.0);
    final otpButtonSize = (14.0 * scale).clamp(13.0, 16.0);
    final topInset = MediaQuery.paddingOf(context).top;
    final headerSweepHeight = (size.height * 0.30).clamp(170.0, 230.0);
    final cardTop = topInset + headerSweepHeight;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOTPVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Phone verified successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => AiOnboardingPage(
                  mobile: widget.mobile,
                  requiresProfileCompletion: state.requiresProfileCompletion,
                ),
              ),
              (route) => false,
            );
          } else if (state is AuthOTPSent) {
            if (state.otp != null && state.otp!.isNotEmpty) {
              _showOtpDialog(context, state.otp!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('OTP sent successfully'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF062F35)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: cardTop + panelRadius + 2,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment(0.22, -1.07),
                    startAngle: -0.55,
                    endAngle: 5.73,
                    colors: [
                      Color(0xFF09E0FF),
                      Color(0xFF0F6876),
                      Color(0xFF08414A),
                      Color(0xFF062F35),
                      Color(0xFF062F35),
                    ],
                    stops: [0.05, 0.44, 0.53, 0.57, 1],
                    transform: GradientRotation(-0.55),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headerSweepHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello!',
                          style: GoogleFonts.boldonse(
                            color: _kOnGradient,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _WelcomeRichText(fontSize: welcomeSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: cardTop,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _kPanel,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(panelRadius)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(panelRadius)),
                  clipBehavior: Clip.hardEdge,
                  child: SafeArea(
                    top: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final horizontalPad = (constraints.maxWidth * 0.1).clamp(20.0, 44.0);
                        final topPad = (constraints.maxHeight * 0.09).clamp(34.0, 60.0);
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPad,
                            topPad,
                            horizontalPad,
                            24,
                          ),
                          child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Verify Phone',
                              style: GoogleFonts.boldonse(
                                color: _kPrimary,
                                fontSize: pageTitleSize,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Code sent to $_displayPhoneNumber',
                              style: GoogleFonts.montserrat(
                                color: _kPrimary,
                                fontSize: pageBodySize,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _OtpCard(
                              initialOtpValue: _initialOtpValue,
                              countdownText: _resendCountdown > 0
                                  ? 'Code expires in ${_formatTime(_resendCountdown)}'
                                  : 'Code expired - tap to resend',
                              canResend: _canResend,
                              clockIconUrl: _kClockIconUrl,
                              onTapTimer: _resendOtp,
                              onChanged: (value) => setState(() => _otp = value),
                              onCompleted: (value) => setState(() => _otp = value),
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                final isEnabled = _otp.length == 6 && !isLoading;
                                return SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isEnabled ? _verifyOtp : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kAccent,
                                      foregroundColor: _kOnGradient,
                                      disabledBackgroundColor: _kAccent.withValues(alpha: 0.65),
                                      disabledForegroundColor: _kOnGradient.withValues(alpha: 0.95),
                                      elevation: 4,
                                      shadowColor: Colors.black.withValues(alpha: 0.1),
                                      side: const BorderSide(color: Color(0xFF09E0FF)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation<Color>(_kOnGradient),
                                            ),
                                          )
                                        : Text(
                                            'Verify OTP',
                                            style: GoogleFonts.boldonse(
                                              fontSize: otpButtonSize,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({
    required this.initialOtpValue,
    required this.countdownText,
    required this.canResend,
    required this.clockIconUrl,
    required this.onTapTimer,
    required this.onChanged,
    required this.onCompleted,
  });

  final String? initialOtpValue;
  final String countdownText;
  final bool canResend;
  final String clockIconUrl;
  final VoidCallback onTapTimer;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - 30;
        final spacing = (contentWidth * 0.045).clamp(8.0, 20.0);
        final cellWidth = ((contentWidth - (spacing * 5)) / 6).clamp(30.0, 36.0);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
        children: [
          Text(
            'Enter 6 digit code',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: _OTPPageState._kPrimary,
              fontSize: 36 * 0.556,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          MaterialPinField(
            length: 6,
            initialValue: initialOtpValue,
            onChanged: onChanged,
            onCompleted: onCompleted,
            theme: MaterialPinTheme(
              shape: MaterialPinShape.outlined,
              cellSize: Size(cellWidth, 48),
              spacing: spacing,
              borderRadius: BorderRadius.circular(8),
              borderWidth: 1,
              borderColor: _OTPPageState._kOtpBorder,
              focusedBorderColor: AppColors.primary,
              textStyle: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _OTPPageState._kPrimary,
              ),
              entryAnimation: MaterialPinAnimation.scale,
              animationDuration: const Duration(milliseconds: 250),
              animationCurve: Curves.easeOut,
            ),
          ),
          const SizedBox(height: 50),
          InkWell(
            onTap: canResend ? onTapTimer : null,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x66DFE7E9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Colors.black.withValues(alpha: 0.34),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    countdownText,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: canResend ? AppColors.primary : Colors.black.withValues(alpha: 0.34),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

class _WelcomeRichText extends StatelessWidget {
  const _WelcomeRichText({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.montserrat(
          color: _OTPPageState._kOnGradient,
          fontSize: fontSize,
          fontWeight: FontWeight.w200,
          height: 1.2,
        ),
        children: [
          const TextSpan(text: 'Welcome to your '),
          TextSpan(
            text: 'solecial hub',
            style: GoogleFonts.montserrat(
              color: _OTPPageState._kOnGradient,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
