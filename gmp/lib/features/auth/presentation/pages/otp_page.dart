import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../dashboard/presentation/pages/customer_dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/otp_dev_dialog.dart';
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
  static const String _kAuthBgAsset = 'assets/images/bg/auth.png';
  static const String _kAuthBgFallbackAsset = 'assets/images/bg.png';
  static const Color _kPrimary = Color(0xFF062F35);
  static const Color _kAccent = Color(0xFF0F6876);
  static const Color _kOnGradient = Color(0xFFFFFFFF);
  static const Color _kPanel = Color(0xFFD9D9D9);
  static const Color _kOtpBorder = Color(0xFFD7DEE0);

  static const String _kClockIconUrl =
      'https://www.figma.com/api/mcp/asset/cc06893c-2fe8-4c01-9422-ece708223602';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _otp = '';
  int _resendCountdown = 60;
  Timer? _timer;
  Timer? _verifyingProgressTimer;
  bool _canResend = false;
  bool _isVerifyingOtp = false;
  double _verifyingProgress = 0.0;

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
    _verifyingProgressTimer?.cancel();
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

  void _startVerifyingProgress() {
    _verifyingProgressTimer?.cancel();
    setState(() => _verifyingProgress = 0.08);
    _verifyingProgressTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted || !_isVerifyingOtp) return;
      setState(() {
        if (_verifyingProgress < 0.58) {
          _verifyingProgress += 0.04;
        } else if (_verifyingProgress < 0.84) {
          _verifyingProgress += 0.01;
        }
      });
    });
  }

  void _stopVerifyingProgress() {
    _verifyingProgressTimer?.cancel();
    _verifyingProgressTimer = null;
    if (mounted) {
      setState(() => _verifyingProgress = 0.0);
    }
  }

  void _verifyOtp() {
    if (_otp.length != 6 || _isVerifyingOtp) return;
    FocusScope.of(context).unfocus();
    setState(() => _isVerifyingOtp = true);
    _startVerifyingProgress();
    context.read<AuthBloc>().add(AuthVerifyOTP(mobile: widget.mobile, otp: _otp));
  }

  void _resendOtp() {
    if (!_canResend) return;
    context.read<AuthBloc>().add(AuthSendOTP(widget.mobile));
    _startResendTimer();
  }

  void _showOtpDialog(BuildContext hostContext, String otp) {
    showDevOtpDialog(
      context: hostContext,
      otp: otp,
      primaryActionLabel: 'Close',
      onPrimary: () {},
      secondaryActionLabel: 'Copy & Close',
      onSecondary: (dialogContext) => copyOtpAndCloseDialog(
        dialogContext: dialogContext,
        hostContext: hostContext,
        otp: otp,
        onAfterCopy: () async {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthScale = (size.width / 393.0).clamp(0.88, 1.14);
    final heightScale = (size.height / 852.0).clamp(0.72, 1.08);
    final textScaleTightness = (1.06 / MediaQuery.textScalerOf(context).scale(1.0)).clamp(
      0.84,
      1.04,
    );
    final scale = (math.min(widthScale, heightScale) * textScaleTightness).clamp(0.70, 1.08);
    final topInset = MediaQuery.paddingOf(context).top;
    final headerSweepHeight = (size.height * 0.28).clamp(145.0, 230.0);
    final panelRadius = (28.0 * scale).clamp(20.0, 32.0);
    final cardTop = topInset + headerSweepHeight;
    final helloSize = (34.0 * scale).clamp(24.0, 39.0);
    final welcomeSize = (24.0 * scale).clamp(16.0, 28.0);
    final verifyTitleSize = (24.0 * scale).clamp(18.0, 26.0);
    final verifySubSize = (20.0 * scale).clamp(14.0, 21.0);

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthOTPVerified) {
            setState(() => _isVerifyingOtp = false);
            _stopVerifyingProgress();
            await showAppFeedbackAlert(
              context,
              message: 'Phone verified successfully!',
              type: AppFeedbackType.success,
            );
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => state.requiresProfileCompletion
                    ? AiOnboardingPage(
                        mobile: widget.mobile,
                        requiresProfileCompletion: true,
                      )
                    : const CustomerDashboardPage(),
              ),
              (route) => false,
            );
          } else if (state is AuthOTPSent) {
            if (state.otp != null && state.otp!.isNotEmpty) {
              _showOtpDialog(context, state.otp!);
            } else {
              await showAppFeedbackAlert(
                context,
                message: 'OTP sent successfully',
                type: AppFeedbackType.success,
              );
            }
          } else if (state is AuthError) {
            setState(() => _isVerifyingOtp = false);
            _stopVerifyingProgress();
            await showAppFeedbackAlert(
              context,
              message: state.message,
              type: AppFeedbackType.failure,
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                _kAuthBgAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  _kAuthBgFallbackAsset,
                  fit: BoxFit.cover,
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
                            fontSize: helloSize,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: (size.height * 0.012).clamp(6.0, 12.0)),
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
                        final squeeze = (constraints.maxHeight / 560).clamp(0.76, 1.0);
                        final horizontalPad = (constraints.maxWidth * 0.1).clamp(16.0, 44.0);
                        final topPad = (constraints.maxHeight * 0.08 * squeeze).clamp(12.0, 60.0);
                        final verticalGapSm = constraints.maxHeight * 0.02 * squeeze;
                        final verticalGapMd = constraints.maxHeight * 0.032 * squeeze;
                        final controlHeight = constraints.maxHeight * 0.082 * squeeze;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPad,
                            topPad,
                            horizontalPad,
                            verticalGapMd.clamp(10.0, 30.0),
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
                                fontSize: verifyTitleSize,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: verticalGapSm.clamp(10.0, 20.0)),
                            Text(
                              'Code sent to $_displayPhoneNumber',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                color: _kPrimary,
                                fontSize: verifySubSize,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: verticalGapSm.clamp(10.0, 20.0)),
                            _OtpCard(
                              initialOtpValue: _initialOtpValue,
                              countdownText: _resendCountdown > 0
                                  ? 'Code expires in ${_formatTime(_resendCountdown)}'
                                  : 'Code expired - Tap to resend',
                              canResend: _canResend,
                              clockIconUrl: _kClockIconUrl,
                              onTapTimer: _resendOtp,
                              onChanged: (value) => setState(() => _otp = value),
                              onCompleted: (value) => setState(() => _otp = value),
                            ),
                            SizedBox(height: verticalGapMd.clamp(12.0, 28.0)),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isEnabled = _otp.length == 6 && !_isVerifyingOtp;
                                return SizedBox(
                                  height: controlHeight.clamp(42.0, 56.0),
                                  width: double.infinity,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [Color(0xFF12899B), Color(0xFF09E0FF)],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(1),
                                      child: ElevatedButton(
                                        onPressed: isEnabled ? _verifyOtp : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F6876),
                                          foregroundColor: _kOnGradient,
                                          disabledBackgroundColor: const Color(0xFF0F6876),
                                          disabledForegroundColor: _kOnGradient,
                                          surfaceTintColor: Colors.transparent,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: _isVerifyingOtp
                                            ? _VerifyOtpProgress(progress: _verifyingProgress)
                                            : Text(
                                                'Verify OTP',
                                                style: GoogleFonts.boldonse(
                                                  fontSize: (14.0 * scale).clamp(13.0, 16.0),
                                                  fontWeight: FontWeight.w400,
                                                  color: _kOnGradient,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
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

class _VerifyOtpProgress extends StatelessWidget {
  const _VerifyOtpProgress({required this.progress});

  static const Color _progressTrack = Color(0xFF08414A);
  static const Color _progressFill = Color(0xFF12899B);

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = constraints.maxWidth * progress.clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: _progressTrack),
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: _progressFill,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Verifying OTP...',
                  style: GoogleFonts.boldonse(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFDFE7E9),
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
        final cardWidth = constraints.maxWidth;
        final padH = (cardWidth * 0.045).clamp(10.0, 18.0);
        final padV = (cardWidth * 0.058).clamp(12.0, 24.0);
        final titleToOtp = (cardWidth * 0.07).clamp(12.0, 24.0);
        final otpToTimer = (cardWidth * 0.14).clamp(22.0, 50.0);
        final cellW = (cardWidth * 0.1).clamp(24.0, 36.0);
        final cellH = (cardWidth * 0.13).clamp(34.0, 48.0);
        final cellGap = (cardWidth * 0.05).clamp(8.0, 20.0);
        final otpRowTargetW = 6 * cellW + 5 * cellGap;
        final innerW = cardWidth - padH * 2;
        final scale = innerW < otpRowTargetW ? innerW / otpRowTargetW : 1.0;
        final pinW = cellW * scale;
        final pinH = cellH * scale;
        final pinGap = cellGap * scale;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: cardWidth,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular((cardWidth * 0.06).clamp(12.0, 22.0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Enter 6 digit code',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: _OTPPageState._kPrimary,
                      fontSize: (cardWidth * 0.055).clamp(14.0, 20.0),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: titleToOtp),
                  Center(
                    child: MaterialPinField(
                      length: 6,
                      initialValue: initialOtpValue,
                      onChanged: onChanged,
                      onCompleted: onCompleted,
                      theme: MaterialPinTheme(
                      shape: MaterialPinShape.outlined,
                      cellSize: Size(pinW, pinH),
                      spacing: pinGap,
                      borderRadius: BorderRadius.circular(5),
                      borderWidth: 1,
                      focusedBorderWidth: 1,
                      fillColor: Colors.white,
                      focusedFillColor: Colors.white,
                      filledFillColor: Colors.white,
                      followingFillColor: Colors.white,
                      completeFillColor: Colors.white,
                      borderColor: _OTPPageState._kOtpBorder,
                      filledBorderColor: _OTPPageState._kOtpBorder,
                      completeBorderColor: _OTPPageState._kOtpBorder,
                      focusedBorderColor: AppColors.border,
                      textStyle: GoogleFonts.montserrat(
                        fontSize: (cardWidth * 0.055).clamp(14.0, 20.0),
                        fontWeight: FontWeight.w600,
                        color: _OTPPageState._kPrimary,
                      ),
                      entryAnimation: MaterialPinAnimation.scale,
                      animationDuration: const Duration(milliseconds: 250),
                      animationCurve: Curves.easeOut,
                      ),
                    ),
                  ),
                  SizedBox(height: otpToTimer),
                  Align(
                    alignment: Alignment.center,
                    child: InkWell(
                    onTap: canResend ? onTapTimer : null,
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (cardWidth * 0.06).clamp(10.0, 20.0),
                        vertical: (cardWidth * 0.03).clamp(6.0, 10.0),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x66DFE7E9),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: (cardWidth * 0.045).clamp(12.0, 16.0),
                              color: Colors.black.withValues(alpha: 0.34),
                            ),
                            SizedBox(width: (cardWidth * 0.03).clamp(6.0, 10.0)),
                            Text(
                              countdownText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: (cardWidth * 0.04).clamp(11.0, 14.0),
                                fontWeight: FontWeight.w400,
                                color: canResend
                                    ? AppColors.primary
                                    : Colors.black.withValues(alpha: 0.34),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
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
      ),
    );
  }
}
