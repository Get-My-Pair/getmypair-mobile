import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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
  static const Color _kPrimary = Color(0xFF062F35);
  static const Color _kAccent = Color(0xFF0F6876);
  static const Color _kTertiary = Color(0xFFDFE7E9);
  static const Color _kPanel = Color(0xFFD9D9D9);

  static const String _kFlagImage =
      'https://www.figma.com/api/mcp/asset/f2924cb4-41d5-41dd-b684-6ae3ef3b751b';
  static const String _kFacebookImage =
      'https://www.figma.com/api/mcp/asset/a4f220b1-86c3-441a-b0cb-d5d538de7e3e';
  static const String _kGoogleImage =
      'https://www.figma.com/api/mcp/asset/711583d9-a333-4c61-af4e-0f17a59890c3';
  static const String _kAppleImage =
      'https://www.figma.com/api/mcp/asset/aa606515-5cd1-4dec-ba1d-a3f669c4086a';

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

  bool get _isPhoneValid => _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length == 10;

  void _validatePhone(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      if (clean.isEmpty) {
        _phoneError = null;
      } else if (clean.length < 10) {
        _phoneError = 'Phone number must be 10 digits';
      } else if (clean.length > 10) {
        _phoneError = 'Phone number cannot exceed 10 digits';
      } else {
        _phoneError = null;
      }
    });
  }

  void _pickCountryCode() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            itemCount: CountryCode.popularCountries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final country = CountryCode.popularCountries[index];
              final isSelected = country.code == _selectedCountry.code;
              return ListTile(
                leading: Text(country.flag, style: const TextStyle(fontSize: 20)),
                title: Text(country.name),
                trailing: Text(country.dialCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                selected: isSelected,
                onTap: () {
                  setState(() => _selectedCountry = country);
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  void _sendOtp() {
    if (!_isPhoneValid) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms of Service and Privacy Policy'),
          behavior: SnackBarBehavior.floating,
        ),
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
            onPressed: () {
              Clipboard.setData(ClipboardData(text: otp));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('OTP copied to clipboard')),
              );
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
    final topInset = MediaQuery.paddingOf(context).top;
    final cardTop = topInset + MediaQuery.sizeOf(context).height * 0.27;

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
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
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 22),
                    Text(
                      'Hello!',
                      style: TextStyle(
                        color: _kTertiary,
                        fontSize: 56 * 0.607,
                        fontFamily: 'Boldonse',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 10),
                    _WelcomeRichText(),
                  ],
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(10, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SafeArea(
                    top: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final horizontalPad = (constraints.maxWidth * 0.1).clamp(20.0, 44.0);
                        final topPad = (constraints.maxHeight * 0.09).clamp(34.0, 62.0);
                        final countryWidth = (constraints.maxWidth * 0.26).clamp(86.0, 110.0);
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
                          const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: 24,
                              fontFamily: 'Boldonse',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Enter your phone number',
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: 20,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "We’ll text you a quick verification\ncode",
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: 20,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              InkWell(
                                onTap: _pickCountryCode,
                                borderRadius: BorderRadius.circular(100),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 86, maxWidth: countryWidth),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: Image.network(_kFlagImage,
                                              width: 32, height: 21, fit: BoxFit.cover),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _selectedCountry.dialCode,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0x57000000),
                                              fontSize: 16,
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down, color: Color(0x57000000), size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, color: Color(0x57000000), size: 22),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneController,
                                          focusNode: _phoneFocusNode,
                                          keyboardType: TextInputType.phone,
                                          textAlignVertical: TextAlignVertical.center,
                                          maxLength: 10,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(10),
                                          ],
                                          onChanged: _validatePhone,
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            hintText: 'Phone',
                                            hintStyle: TextStyle(
                                              color: Color(0x57000000),
                                              fontSize: 16,
                                              fontFamily: 'Montserrat',
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
                                          style: const TextStyle(
                                            color: _kPrimary,
                                            fontSize: 16,
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_phoneError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _phoneError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
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
                                foregroundColor: _kTertiary,
                                disabledBackgroundColor: _kAccent.withValues(alpha: 0.65),
                                disabledForegroundColor: _kTertiary.withValues(alpha: 0.95),
                                elevation: 4,
                                shadowColor: Colors.black.withValues(alpha: 0.1),
                                side: const BorderSide(color: Color(0xFF09E0FF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                padding: EdgeInsets.zero,
                              ),
                              child: _isSendingOtp
                                  ? _SendingOtpProgress(progress: _sendingProgress)
                                  : const Text(
                                      'Send OTP',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Boldonse',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 42),
                          Row(
                            children: const [
                              Expanded(child: Divider(color: Color(0x4D8D8D8D), thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 25),
                                child: Text(
                                  'or Sign Up with',
                                  style: TextStyle(
                                    color: Color(0x33000000),
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0x4D8D8D8D), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 24,
                            runSpacing: 12,
                            children: const [
                              _SocialImageTile(imageUrl: _kFacebookImage),
                              _SocialImageTile(imageUrl: _kGoogleImage),
                              _SocialImageTile(imageUrl: _kAppleImage),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _agreedToTerms ? _kPrimary : Colors.transparent,
                                    border: Border.all(color: _kPrimary, width: 1.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: _agreedToTerms
                                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w400,
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
                                            MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                                          ),
                                          child: const Text(
                                            'Terms of Service',
                                            style: TextStyle(color: _kPrimary, fontSize: 12),
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
                                            MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                                          ),
                                          child: const Text(
                                            'Privacy Policy',
                                            style: TextStyle(color: _kPrimary, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
  const _WelcomeRichText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        style: TextStyle(
          color: _MobileOTPPageState._kTertiary,
          fontSize: 24,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
        children: [
          TextSpan(text: 'Welcome to your '),
          TextSpan(
            text: 'solecial hub',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialImageTile extends StatelessWidget {
  const _SocialImageTile({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 49,
      height: 49,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(imageUrl, fit: BoxFit.contain),
      ),
    );
  }
}

class _SendingOtpProgress extends StatelessWidget {
  const _SendingOtpProgress({required this.progress});

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
              Container(color: AppColors.surface),
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Sending...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
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
