import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../data/models/country_code.dart';
import '../widgets/onboarding_surface.dart';
import 'otp_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class MobileOTPPage extends StatefulWidget {
  const MobileOTPPage({super.key});

  @override
  State<MobileOTPPage> createState() => _MobileOTPPageState();
}

class _MobileOTPPageState extends State<MobileOTPPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  CountryCode _selectedCountry = CountryCode.popularCountries[0];
  String? _phoneError;
  bool _isSendingOTP = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool get _isValid => _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length == 10;

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
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms of Service and Privacy Policy'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _isSendingOTP = true);
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
                const SnackBar(content: Text('OTP copied to clipboard'), duration: Duration(seconds: 2)),
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OTPPage(
                    mobile: mobile,
                    countryCode: _selectedCountry.dialCode,
                    phoneNumber: _phoneController.text,
                    prefilledOtp: otp,
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
                    prefilledOtp: otp,
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

  void _pickCountryCode() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: CountryCode.popularCountries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final country = CountryCode.popularCountries[index];
              final isSelected = country.code == _selectedCountry.code;
              return ListTile(
                leading: Text(country.flag, style: const TextStyle(fontSize: 20)),
                title: Text(country.name),
                trailing: Text(
                  country.dialCode,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCountry = country;
                  });
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final cardTop = topInset + MediaQuery.sizeOf(context).height * 0.27;

    return Scaffold(
      backgroundColor: AppColors.footwearHeroStart,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOTPSent) {
            setState(() => _isSendingOTP = false);
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
            setState(() => _isSendingOTP = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Hello!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFDFE7E9),
                        fontSize: 34,
                        fontFamily: 'Boldonse',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: const Color(0xFFDFE7E9),
                          fontSize: 24,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                        children: [
                          const TextSpan(text: 'Welcome to your '),
                          const TextSpan(
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
                  color: const Color(0xFFD9D9D9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(10, 0)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(44, 60, 38, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF062F35),
                              fontSize: 24,
                              fontFamily: 'Boldonse',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Enter your phone number',
                            style: TextStyle(
                              color: Color(0xFF062F35),
                              fontSize: 20,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "We'll text you a quick verification code",
                            style: TextStyle(
                              color: Color(0xFF062F35),
                              fontSize: 20,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              SizedBox(width: 110, child: _buildCountryCodeChip()),
                              const SizedBox(width: 5),
                              Expanded(child: _buildPhoneField()),
                            ],
                          ),
                          if (_phoneError != null) ...[
                            const SizedBox(height: 8),
                            Text(_phoneError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (_isValid && !_isSendingOTP) ? _sendOTP : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textOnPrimary,
                                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.65),
                                disabledForegroundColor: AppColors.textOnPrimary.withValues(alpha: 0.95),
                                elevation: 4,
                                shadowColor: AppColors.primary.withValues(alpha: 0.45),
                                side: const BorderSide(color: Color(0xFF09DFFF), width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: _isSendingOTP
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                                      ),
                                    )
                                  : const Text(
                                      'Send OTP',
                                      style: TextStyle(
                                        color: Color(0xFFDFE7E9),
                                        fontSize: 14,
                                        fontFamily: 'Boldonse',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.35), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or Sign Up with ',
                                  style: TextStyle(
                                    color: Colors.black26,
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.35), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialTile(
                                backgroundColor: Color(0xFF1877F2),
                                child: Center(
                                  child: Text('f', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 40),
                              _SocialTile(
                                backgroundColor: Colors.white,
                                child: Center(
                                  child: ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [
                                        Color(0xFF4285F4),
                                        Color(0xFFEA4335),
                                        Color(0xFFFBBC05),
                                        Color(0xFF34A853),
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                              _SocialTile(
                                backgroundColor: Colors.white,
                                child: Center(child: Icon(Icons.apple, size: 28, color: Colors.black)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(top: 0),
                                  decoration: BoxDecoration(
                                    color: _agreedToTerms ? AppColors.primary : Colors.transparent,
                                    border: Border.all(color: AppColors.textPrimary, width: 1.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: _agreedToTerms ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'I agree to the',
                                        style: TextStyle(
                                          color: Color(0xFF898989),
                                          fontSize: 12,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' ',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const TermsOfServicePage(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Terms of Service',
                                            style: TextStyle(
                                              color: Color(0xFF062F35),
                                              fontSize: 12,
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' ',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: 'and',
                                        style: TextStyle(
                                          color: Color(0xFF898989),
                                          fontSize: 12,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' ',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const PrivacyPolicyPage(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Privacy Policy',
                                            style: TextStyle(
                                              color: Color(0xFF062F35),
                                              fontSize: 12,
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w400,
                                            ),
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

  Widget _buildCountryCodeChip() {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: _pickCountryCode,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedCountry.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              _selectedCountry.dialCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x57000000),
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0x57000000)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.phone_outlined, color: Color(0x57000000), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              autofocus: true,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: _validatePhone,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: 'Phone',
                hintStyle: TextStyle(
                  color: Color(0x57000000),
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                ),
              ),
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({required this.child, required this.backgroundColor});

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 49,
        height: 49,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
      ),
    );
  }
}

