import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/country_code.dart';
import 'mobile_otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  final CountryCode _selectedCountry = CountryCode.popularCountries[0];
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _goToMobileOtp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MobileOTPPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final cardTop = topInset + MediaQuery.sizeOf(context).height * 0.27;

    return Scaffold(
      body: Stack(
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
              padding: const EdgeInsets.fromLTRB(80, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  Text(
                    'Hello!',
                    style: GoogleFonts.boldonse(
                      color: _kTertiary,
                      fontSize: 56 * 0.607,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _WelcomeRichText(),
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
                        Text(
                          'Sign Up',
                          style: GoogleFonts.boldonse(
                            color: _kPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Enter your phone number',
                          style: GoogleFonts.montserrat(
                            color: _kPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We’ll text you a quick verification\ncode",
                          style: GoogleFonts.montserrat(
                            color: _kPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 86, maxWidth: countryWidth),
                              child: Container(
                                height: 58,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Image.network(_kFlagImage, width: 32, height: 21, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _selectedCountry.dialCode,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          color: const Color(0x57000000),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, color: Color(0x57000000), size: 18),
                                  ],
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
                                    SvgPicture.asset(
                                      'assets/images/phone.svg',
                                      width: 22,
                                      height: 22,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0x57000000),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          hintText: 'Phone',
                                          hintStyle: GoogleFonts.montserrat(
                                            color: const Color(0x57000000),
                                            fontSize: 16,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        style: GoogleFonts.montserrat(
                                          color: _kPrimary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _goToMobileOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kAccent,
                              foregroundColor: _kTertiary,
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              side: const BorderSide(color: Color(0xFF09E0FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: Text(
                              'Send OTP',
                              style: GoogleFonts.boldonse(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
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
                                  fontSize: 16,
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
                          spacing: 24,
                          runSpacing: 12,
                          children: const [
                            _SocialImageTile(imageUrl: _kFacebookImage),
                            _SocialImageTile(imageUrl: _kGoogleImage),
                            _SocialImageTile(imageUrl: _kAppleImage),
                          ],
                        ),
                        const SizedBox(height: 36),
                        const Row(
                          children: [
                            _TermsCheckbox(),
                            SizedBox(width: 8),
                            Expanded(child: _TermsText()),
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
    );
  }
}

class _WelcomeRichText extends StatelessWidget {
  const _WelcomeRichText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.montserrat(
          color: _LoginPageState._kTertiary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
        children: [
          const TextSpan(text: 'Welcome to your '),
          TextSpan(
            text: 'solecial hub',
            style: GoogleFonts.montserrat(
              color: _LoginPageState._kTertiary,
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

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: _LoginPageState._kPrimary, width: 1.8),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w400),
        children: [
          TextSpan(
            text: 'I agree to the ',
            style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF898989)),
          ),
          TextSpan(
            text: 'Terms of Service',
            style: GoogleFonts.montserrat(fontSize: 12, color: _LoginPageState._kPrimary),
          ),
          TextSpan(
            text: ' and ',
            style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF898989)),
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.montserrat(fontSize: 12, color: _LoginPageState._kPrimary),
          ),
        ],
      ),
    );
  }
}
