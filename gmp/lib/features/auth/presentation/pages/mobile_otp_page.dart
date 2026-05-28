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
import '../widgets/otp_dev_dialog.dart';
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
  static const String _kAuthBgFallbackAsset = 'assets/images/bg.png';
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
  /// Full viewport height captured while the keyboard is closed (Android
  /// `adjustResize` shrinks [MediaQuery.size] even when [resizeToAvoidBottomInset]
  /// is false).
  double? _layoutViewportHeight;

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
    showDevOtpDialog(
      context: context,
      otp: otp,
      primaryActionLabel: 'Continue',
      onPrimary: () => _openOtpPage(mobile, otp: otp),
      secondaryActionLabel: 'Copy & Continue',
      onSecondary: (dialogContext) => copyOtpAndCloseDialog(
        dialogContext: dialogContext,
        hostContext: context,
        otp: otp,
        onAfterCopy: () async => _openOtpPage(mobile, otp: otp),
      ),
    );
  }

  bool _isKeyboardVisible(MediaQueryData mediaQuery) =>
      mediaQuery.viewInsets.bottom > 0;

  /// Android `adjustResize` shrinks [MediaQuery.size] without always setting
  /// [MediaQuery.viewInsets].
  bool _isViewportShrunkByKeyboard(MediaQueryData mediaQuery) {
    final cached = _layoutViewportHeight;
    if (cached == null) return false;
    return mediaQuery.size.height < cached * 0.9;
  }

  void _syncLayoutViewportHeight(MediaQueryData mediaQuery) {
    final height = mediaQuery.size.height;
    if (_isKeyboardVisible(mediaQuery) || _isViewportShrunkByKeyboard(mediaQuery)) {
      _layoutViewportHeight ??= height;
      return;
    }
    _layoutViewportHeight = height;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _syncLayoutViewportHeight(mediaQuery);
    final layoutHeight = _layoutViewportHeight!;
    final layoutMediaQuery = mediaQuery.copyWith(
      size: Size(mediaQuery.size.width, layoutHeight),
      viewInsets: EdgeInsets.zero,
    );
    final size = layoutMediaQuery.size;
    final widthScale = (size.width / Responsive.designFrameWidth).clamp(0.88, 1.14);
    final heightScale = (size.height / 852.0).clamp(0.74, 1.08);
    final textScaleTightness = (1.06 / MediaQuery.textScalerOf(context).scale(1.0)).clamp(
      0.84,
      1.04,
    );
    final scale = (math.min(widthScale, heightScale) * textScaleTightness).clamp(0.72, 1.08);
    final titleSize = (34.0 * scale).clamp(24.0, 39.0);
    final welcomeSize = (24.0 * scale).clamp(16.0, 28.0);
    final panelRadius = (28.0 * scale).clamp(18.0, 32.0);
    final cardTitleSize = (24.0 * scale).clamp(18.0, 28.0);
    final bodyTitleSize = (20.0 * scale).clamp(15.0, 24.0);
    final bodySize = (20.0 * scale).clamp(14.0, 22.0);
    final fieldTextSize = (16.0 * scale).clamp(13.0, 18.0);
    final topInset = layoutMediaQuery.padding.top;
    // Keep hero responsive across short/tall phones.
    // Previous 0.95 factor made this almost always hit max height.
    final headerSweepHeight = (size.height * 0.25).clamp(132.0, 205.0);
    final cardTop = topInset + headerSweepHeight;

    return Scaffold(
      // Keep hero + card geometry stable when the keyboard opens (avoid inset resize +
      // Column reflow that pushes content upward).
      resizeToAvoidBottomInset: false,
      body: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: layoutHeight,
          maxHeight: layoutHeight,
          child: MediaQuery(
            data: layoutMediaQuery,
            child: SizedBox(
              height: layoutHeight,
              width: layoutMediaQuery.size.width,
              child: BlocListener<AuthBloc, AuthState>(
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
                        final squeeze = (constraints.maxHeight / 640).clamp(0.72, 1.0);
                        final horizontalPad = (constraints.maxWidth * 0.1).clamp(16.0, 44.0);
                        final topPad = (constraints.maxHeight * 0.06 * squeeze).clamp(8.0, 48.0);
                        final verticalGapXs = constraints.maxHeight * 0.012 * squeeze;
                        final verticalGapSm = constraints.maxHeight * 0.02 * squeeze;
                        final verticalGapMd = constraints.maxHeight * 0.032 * squeeze;
                        final verticalGapLg = constraints.maxHeight * 0.05 * squeeze;
                        final controlHeight = constraints.maxHeight * 0.082 * squeeze;
                        final iconTileSize = constraints.maxWidth * 0.13;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPad,
                            topPad,
                            horizontalPad,
                            verticalGapMd.clamp(10.0, 30.0),
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
                          SizedBox(height: verticalGapSm.clamp(10.0, 20.0)),
                          Text(
                            'Enter your phone number',
                            style: GoogleFonts.montserrat(
                              color: _kPrimary,
                              fontSize: bodyTitleSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: verticalGapXs.clamp(4.0, 12.0)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'We’ll text you a quick verification',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: GoogleFonts.montserrat(
                                    color: _kBodyMuted,
                                    fontSize: bodySize,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Text(
                                'code',
                                style: GoogleFonts.montserrat(
                                  color: _kBodyMuted,
                                  fontSize: bodySize,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: verticalGapMd.clamp(12.0, 28.0)),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final inputGap = (constraints.maxWidth * 0.014).clamp(4.0, 10.0);
                              final total = constraints.maxWidth - inputGap;
                              final codeWidth = total * 0.32;
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
                                        height: controlHeight.clamp(38.0, 50.0),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: (constraints.maxWidth * 0.03).clamp(8.0, 14.0),
                                          vertical: (constraints.maxWidth * 0.014).clamp(3.0, 8.0),
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
                                            style: TextStyle(
                                              fontSize: (constraints.maxWidth * 0.06).clamp(16.0, 24.0),
                                              height: 1,
                                            ),
                                            ),
                                            SizedBox(width: (constraints.maxWidth * 0.016).clamp(4.0, 8.0)),
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
                                            SizedBox(width: (constraints.maxWidth * 0.004).clamp(1.0, 4.0)),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Color(0x57000000),
                                              size: (constraints.maxWidth * 0.05).clamp(14.0, 20.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: inputGap),
                                  SizedBox(
                                    width: phoneWidth,
                                    child: Container(
                                      height: controlHeight.clamp(38.0, 50.0),
                                      padding: EdgeInsets.fromLTRB(
                                        (constraints.maxWidth * 0.046).clamp(10.0, 18.0),
                                        (constraints.maxWidth * 0.02).clamp(4.0, 9.0),
                                        (constraints.maxWidth * 0.05).clamp(12.0, 20.0),
                                        (constraints.maxWidth * 0.02).clamp(4.0, 9.0),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: (constraints.maxWidth * 0.052).clamp(14.0, 20.0),
                                            height: (constraints.maxWidth * 0.052).clamp(14.0, 20.0),
                                            child: SvgPicture.asset(
                                              'assets/images/phone.svg',
                                              width: (constraints.maxWidth * 0.052).clamp(14.0, 20.0),
                                              height: (constraints.maxWidth * 0.052).clamp(14.0, 20.0),
                                              colorFilter: const ColorFilter.mode(
                                                Color(0x66000000),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: (constraints.maxWidth * 0.03).clamp(6.0, 12.0)),
                                          Expanded(
                                            child: TextField(
                                              controller: _phoneController,
                                              focusNode: _phoneFocusNode,
                                              keyboardType: TextInputType.phone,
                                              textAlignVertical: TextAlignVertical.center,
                                              scrollPadding: EdgeInsets.zero,
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
                            SizedBox(height: verticalGapXs.clamp(4.0, 10.0)),
                            Text(
                              _phoneError!,
                              style: GoogleFonts.montserrat(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          SizedBox(height: verticalGapMd.clamp(12.0, 28.0)),
                          SizedBox(
                            height: controlHeight.clamp(42.0, 56.0),
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
                                  onPressed: (_isPhoneValid && !_isSendingOtp) ? _sendOtp : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kAccent,
                                    foregroundColor: _kOnGradient,
                                    disabledBackgroundColor: _kAccent,
                                    disabledForegroundColor: _kOnGradient,
                                    surfaceTintColor: Colors.transparent,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
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
                            ),
                          ),
                          SizedBox(height: verticalGapLg.clamp(12.0, 34.0)),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0x4D8D8D8D), thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (constraints.maxWidth * 0.07).clamp(12.0, 30.0),
                                ),
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
                          SizedBox(height: verticalGapSm.clamp(22.0, 38.0)),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: (constraints.maxWidth * 0.14).clamp(16.0, 48.0),
                            runSpacing: verticalGapSm.clamp(8.0, 18.0),
                            children: [
                              _SocialIconTile(
                                assetPath: _kAuthFacebookIcon,
                                contentInset: 6,
                                innerScale: 1.0,
                                tileSize: iconTileSize.clamp(36.0, 48.0),
                              ),
                              _SocialIconTile(
                                assetPath: _kAuthGoogleIcon,
                                tileSize: iconTileSize.clamp(36.0, 48.0),
                              ),
                              _SocialIconTile(
                                assetPath: _kAuthAppleIcon,
                                tileSize: iconTileSize.clamp(36.0, 48.0),
                              ),
                            ],
                          ),
                          SizedBox(height: verticalGapLg.clamp(30.0, 50.0)),
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
            ),
          ),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        TextSpan(
          style: GoogleFonts.montserrat(
            color: _MobileOTPPageState._kOnGradient,
            fontSize: fontSize,
            fontWeight: FontWeight.w200,
            height: 1.2,
          ),
          children: [
            const TextSpan(text: 'Welcome to your '),
            TextSpan(
              text: 'solecial hub',
              style: GoogleFonts.montserrat(
                color: _MobileOTPPageState._kOnGradient,
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

class _SocialIconTile extends StatelessWidget {
  const _SocialIconTile({
    this.assetPath,
    this.icon,
    this.color,
    this.contentInset,
    this.innerScale = 1,
    required this.tileSize,
  }) : assert(
         assetPath != null || (icon != null && color != null),
         'Provide either assetPath, or icon + color.',
       );

  final String? assetPath;
  final IconData? icon;
  final Color? color;

  final double? contentInset;

  final double innerScale;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final pad = contentInset ?? (tileSize * 0.145).clamp(4.0, 12.0);
    final r = (tileSize * 0.2).clamp(6.0, 16.0);
    final iconSize = tileSize - (pad * 2);
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
      width: tileSize,
      height: tileSize,
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
