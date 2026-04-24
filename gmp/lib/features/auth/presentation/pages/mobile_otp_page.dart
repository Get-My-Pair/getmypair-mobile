import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../data/models/country_code.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class MobileOTPPage extends StatefulWidget {
  const MobileOTPPage({super.key});

  @override
  State<MobileOTPPage> createState() => _MobileOTPPageState();
}

class _MobileOTPPageState extends State<MobileOTPPage> {
  static const String _kAuthBgAsset = 'assets/images/bg/auth.png';
  static const String _kAuthFacebookIcon = 'assets/images/icons/auth/facebook.svg';
  static const String _kAuthGoogleIcon = 'assets/images/icons/auth/google.svg';
  static const String _kAuthAppleIcon = 'assets/images/icons/auth/apple.svg';
  static const Color _kPrimary = Color(0xFF062F35);
  static const Color _kAccent = Color(0xFF0F6876);
  /// Text/icons on the teal sweep (Figma: white).
  static const Color _kOnGradient = Color(0xFFFFFFFF);
  static const Color _kPanel = Color(0xFFD9D9D9);
  /// Secondary line under title (slightly softer than [_kPrimary]).
  static const Color _kBodyMuted = Color(0xFF456970);

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  CountryCode _selectedCountry = CountryCode.popularCountries[0];

  bool _isSendingOtp = false;
  bool _agreedToTerms = false;
  String? _phoneError;
  double _sendingProgress = 0.0;
  Timer? _sendingProgressTimer;

  @override
  void dispose() {
    _sendingProgressTimer?.cancel();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _startSendingProgress() {
    _sendingProgressTimer?.cancel();
    setState(() => _sendingProgress = 0.08);
    _sendingProgressTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted || !_isSendingOtp) return;
      setState(() {
        if (_sendingProgress < 0.58) {
          _sendingProgress += 0.04;
        } else if (_sendingProgress < 0.84) {
          _sendingProgress += 0.01;
        }
      });
    });
  }

  void _stopSendingProgress() {
    _sendingProgressTimer?.cancel();
    _sendingProgressTimer = null;
    if (mounted) {
      setState(() => _sendingProgress = 0.0);
    }
  }

  static const int _minNationalDigits = 10;
  static const int _maxNationalDigits = 10;

  int get _nationalDigitCount =>
      _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length;

  bool get _isPhoneValid {
    final n = _nationalDigitCount;
    return n >= _minNationalDigits && n <= _maxNationalDigits;
  }

  void _validatePhone(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      if (clean.isEmpty) {
        _phoneError = null;
      } else if (clean.length < _minNationalDigits) {
        _phoneError = 'Enter exactly $_minNationalDigits digits';
      } else if (clean.length > _maxNationalDigits) {
        _phoneError = 'Only $_maxNationalDigits digits are allowed';
      } else {
        _phoneError = null;
      }
    });
  }

  void _onPhoneChanged(String value) {
    _validatePhone(value);
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= _maxNationalDigits && _phoneFocusNode.hasFocus) {
      _phoneFocusNode.unfocus();
    }
  }

  void _pickCountryCode() {
    final all = CountryCode.getAllCountries();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _CountryCodePickerSheet(
          countries: all,
          selected: _selectedCountry,
          onSelected: (country) {
            setState(() => _selectedCountry = country);
            _validatePhone(_phoneController.text);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  void _sendOtp() {
    if (!_isPhoneValid) return;
    if (!_agreedToTerms) {
      showAppFeedbackAlert(
        context,
        message: 'Please agree to Terms of Service and Privacy Policy',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final clean = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final fullMobile = '${_selectedCountry.dialCode}$clean';
    setState(() => _isSendingOtp = true);
    _startSendingProgress();
    context.read<AuthBloc>().add(AuthSendOTP(fullMobile));
  }

  void _openOtpPage(String mobile, {String? otp}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OTPPage(
          mobile: mobile,
          countryCode: _selectedCountry.dialCode,
          phoneNumber: _phoneController.text,
          prefilledOtp: otp,
        ),
      ),
    );
  }

  void _showOtpDialog(String otp, String mobile) {
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
            onPressed: () async {
              Clipboard.setData(ClipboardData(text: otp));
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              await showAppFeedbackAlert(
                context,
                message: 'OTP copied to clipboard',
                type: AppFeedbackType.success,
              );
              if (!context.mounted) return;
              _openOtpPage(mobile, otp: otp);
            },
            child: const Text('Copy & Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openOtpPage(mobile, otp: otp);
            },
            child: const Text('Continue'),
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
    final cardTitleSize = (24.0 * scale).clamp(21.0, 28.0);
    final bodyTitleSize = (20.0 * scale).clamp(17.0, 24.0);
    final bodySize = (20.0 * scale).clamp(16.0, 22.0);
    final fieldTextSize = (16.0 * scale).clamp(14.0, 18.0);
    final topInset = MediaQuery.paddingOf(context).top;
    // Keep hero responsive across short/tall phones.
    // Previous 0.95 factor made this almost always hit max height.
    final headerSweepHeight = (size.height * 0.30).clamp(170.0, 230.0);
    final cardTop = topInset + headerSweepHeight;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOTPSent) {
            setState(() => _isSendingOtp = false);
            _stopSendingProgress();
            if (state.otp != null && state.otp!.isNotEmpty) {
              _showOtpDialog(state.otp!, state.mobile);
            } else {
              _openOtpPage(state.mobile);
            }
          } else if (state is AuthError) {
            setState(() => _isSendingOtp = false);
            _stopSendingProgress();
            showAppFeedbackAlert(
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
                errorBuilder: (_, _, _) =>
                    Image.asset('assets/images/bg.png', fit: BoxFit.cover),
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
                        final topPad = (constraints.maxHeight * 0.09).clamp(34.0, 62.0);
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPad,
                            topPad,
                            horizontalPad,
                            24,
                          ),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign Up',
                            style: GoogleFonts.boldonse(
                              color: _kPrimary,
                              fontSize: cardTitleSize,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: (16.0 * scale).clamp(14.0, 20.0)),
                          Text(
                            'Enter your phone number',
                            style: GoogleFonts.montserrat(
                              color: _kPrimary,
                              fontSize: bodyTitleSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "We’ll text you a quick verification\ncode",
                            style: GoogleFonts.montserrat(
                              color: _kBodyMuted,
                              fontSize: bodySize,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const inputGap = 5.0;
                              final total = constraints.maxWidth - inputGap;
                              final codeWidth = (total * (110 / 343)).clamp(98.0, 120.0);
                              final phoneWidth = total - codeWidth;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: codeWidth,
                                    child: InkWell(
                                      onTap: _pickCountryCode,
                                      borderRadius: BorderRadius.circular(100),
                                      child: Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              _selectedCountry.flag,
                                              style: const TextStyle(fontSize: 22, height: 1),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _selectedCountry.dialCode,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.montserrat(
                                                  color: const Color(0x57000000),
                                                  fontSize: fieldTextSize - 1,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 1),
                                            const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Color(0x57000000),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: inputGap),
                                  SizedBox(
                                    width: phoneWidth,
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.fromLTRB(16, 10, 18, 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: SvgPicture.asset(
                                              'assets/images/phone.svg',
                                              width: 18,
                                              height: 18,
                                              colorFilter: const ColorFilter.mode(
                                                Color(0x66000000),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: _phoneController,
                                              focusNode: _phoneFocusNode,
                                              keyboardType: TextInputType.phone,
                                              textAlignVertical: TextAlignVertical.center,
                                              maxLength: _maxNationalDigits,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                  _maxNationalDigits,
                                                ),
                                              ],
                                              onChanged: _onPhoneChanged,
                                              decoration: InputDecoration(
                                                counterText: '',
                                                hintText: 'Phone',
                                                hintStyle: GoogleFonts.montserrat(
                                                  color: const Color(0x57000000),
                                                  fontSize: fieldTextSize,
                                                ),
                                                filled: false,
                                                fillColor: Colors.transparent,
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                disabledBorder: InputBorder.none,
                                                errorBorder: InputBorder.none,
                                                focusedErrorBorder: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                              ),
                                              style: GoogleFonts.montserrat(
                                                color: _kPrimary,
                                                fontSize: fieldTextSize,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_phoneError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _phoneError!,
                              style: GoogleFonts.montserrat(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (_isPhoneValid && !_isSendingOtp) ? _sendOtp : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kAccent,
                                foregroundColor: _kOnGradient,
                                disabledBackgroundColor: _kAccent,
                                disabledForegroundColor: _kOnGradient,
                                surfaceTintColor: Colors.transparent,
                                elevation: 4,
                                // shadowColor: Colors.black.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                padding: EdgeInsets.zero,
                              ),
                              child: _isSendingOtp
                                  ? _SendingOtpProgress(progress: _sendingProgress)
                                  : Text(
                                      'Send OTP',
                                      style: GoogleFonts.boldonse(
                                        fontSize: (14.0 * scale).clamp(13.0, 16.0),
                                        fontWeight: FontWeight.w400,
                                        color: _kOnGradient,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 42),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0x4D8D8D8D), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                child: Text(
                                  'or Sign Up with',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0x33000000),
                                    fontSize: fieldTextSize,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0x4D8D8D8D), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 48,
                            runSpacing: 12,
                            children: const [
                              _SocialIconTile(
                                assetPath: _kAuthFacebookIcon,
                                contentInset: 6,
                                innerScale: 1.0,
                              ),
                              _SocialIconTile(
                                assetPath: _kAuthGoogleIcon,
                              ),
                              _SocialIconTile(
                                assetPath: _kAuthAppleIcon,
                              ),
                            ],
                          ),
                          const SizedBox(height: 44),
                        LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final horizontalInset = (w * 0.042).clamp(10.0, 28.0);
                              final verticalInset = (w * 0.018).clamp(6.0, 11.0);
                              final tapSide = MediaQuery.textScalerOf(context)
                                  .scale(40.0)
                                  .clamp(40.0, 52.0);
                              final blockMaxWidth = math.min(
                                w - 2 * horizontalInset,
                                420.0,
                              );
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalInset,
                                  vertical: verticalInset,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: blockMaxWidth),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () =>
                                              setState(() => _agreedToTerms = !_agreedToTerms),
                                          child: SizedBox(
                                            width: tapSide,
                                            height: tapSide,
                                            child: Center(
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: _agreedToTerms
                                                      ? _kPrimary
                                                      : Colors.transparent,
                                                  border: Border.all(
                                                    color: _kPrimary,
                                                    width: 1.8,
                                                  ),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                                child: _agreedToTerms
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 11,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: (w * 0.02).clamp(6.0, 10.0)),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: RichText(
                                              textAlign: TextAlign.start,
                                              maxLines: 1,
                                              softWrap: false,
                                              text: TextSpan(
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.35,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'I agree to the ',
                                                    style: TextStyle(color: Color(0xFF898989)),
                                                  ),
                                                  WidgetSpan(
                                                    alignment: PlaceholderAlignment.baseline,
                                                    baseline: TextBaseline.alphabetic,
                                                    child: GestureDetector(
                                                      onTap: () => Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const TermsOfServicePage(),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Terms of Service',
                                                        style: GoogleFonts.montserrat(
                                                          color: _kPrimary,
                                                          fontSize: 12,
                                                          height: 1.35,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' and ',
                                                    style: TextStyle(color: Color(0xFF898989)),
                                                  ),
                                                  WidgetSpan(
                                                    alignment: PlaceholderAlignment.baseline,
                                                    baseline: TextBaseline.alphabetic,
                                                    child: GestureDetector(
                                                      onTap: () => Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const PrivacyPolicyPage(),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Privacy Policy',
                                                        style: GoogleFonts.montserrat(
                                                          color: _kPrimary,
                                                          fontSize: 12,
                                                          height: 1.35,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
                          ),
                                               ],
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

class _WelcomeRichText extends StatelessWidget {
  const _WelcomeRichText({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.montserrat(
          color: _MobileOTPPageState._kOnGradient,
          fontSize: 24,
          fontWeight: FontWeight.w200,
          height: 1.2,
        ),
        children: [
          const TextSpan(text: 'Welcome to your '),
          TextSpan(
            text: 'solecial hub',
            style: GoogleFonts.montserrat(
              color: _MobileOTPPageState._kOnGradient,
              fontSize: 24,
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

class _SocialIconTile extends StatelessWidget {
  const _SocialIconTile({
    this.assetPath,
    this.icon,
    this.color,
    this.contentInset,
    this.innerScale = 1,
  }) : assert(
         assetPath != null || (icon != null && color != null),
         'Provide either assetPath, or icon + color.',
       );

  static const double _tile = 42;

  final String? assetPath;
  final IconData? icon;
  final Color? color;

  final double? contentInset;

  final double innerScale;

  @override
  Widget build(BuildContext context) {
    final pad = contentInset ?? (_tile * (7 / 49)).clamp(6.0, 14.0);
    final r = (_tile * (10 / 49)).clamp(8.0, 16.0);
    final iconSize = _tile - (pad * 2);
    Widget logo = assetPath != null
        ? SvgPicture.asset(
            assetPath!,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => SizedBox(
              width: iconSize,
              height: iconSize,
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            ),
          )
        : FittedBox(
            fit: BoxFit.contain,
            child: Icon(icon, color: color),
          );
    if (innerScale != 1) {
      logo = Transform.scale(
        scale: innerScale,
        alignment: Alignment.center,
        child: logo,
      );
    }
    return Container(
      width: _tile,
      height: _tile,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Center(
        child: logo,
      ),
    );
  }
}

class _SendingOtpProgress extends StatelessWidget {
  const _SendingOtpProgress({required this.progress});

  /// Deeper teal track (matches hero gradient end / button family).
  static const Color _progressTrack = Color(0xFF08414A);
  /// Lighter teal fill (same family as [_MobileOTPPageState._kAccent]).
  static const Color _progressFill = Color(0xFF12899B);

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = (constraints.maxWidth * progress.clamp(0.0, 1.0));
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
                  'Sending OTP...',
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

class _CountryCodePickerSheet extends StatefulWidget {
  const _CountryCodePickerSheet({
    required this.countries,
    required this.selected,
    required this.onSelected,
  });

  final List<CountryCode> countries;
  final CountryCode selected;
  final ValueChanged<CountryCode> onSelected;

  @override
  State<_CountryCodePickerSheet> createState() => _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<_CountryCodePickerSheet> {
  static const Color _sheetPrimary = Color(0xFF062F35);
  static const Color _sheetAccent = Color(0xFF0F6876);

  late final List<CountryCode> _sorted;
  late List<CountryCode> _filtered;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sorted = List<CountryCode>.from(widget.countries)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _filtered = List<CountryCode>.from(_sorted);
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<CountryCode>.from(_sorted);
        return;
      }
      _filtered = _sorted.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.dialCode.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search country or dial code',
                  hintStyle: GoogleFonts.montserrat(
                    color: _sheetPrimary.withValues(alpha: 0.45),
                  ),
                  prefixIcon: Icon(Icons.search, color: _sheetPrimary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: _sheetPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _filtered.length,
                separatorBuilder: (context, _) => Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (_, index) {
                  final c = _filtered[index];
                  final isSelected = c.code == widget.selected.code;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      c.name,
                      style: GoogleFonts.montserrat(fontSize: 16),
                    ),
                    trailing: Text(
                      c.dialCode,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _sheetPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: _sheetAccent.withValues(alpha: 0.12),
                    onTap: () => widget.onSelected(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
