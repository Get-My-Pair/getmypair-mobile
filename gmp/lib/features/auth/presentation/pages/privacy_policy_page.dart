import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ...BgTheme.background(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: GoogleFonts.boldonse(
                        color: const Color(0xFFDFE7E9),
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Last Updated March 2026',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor: MaterialStateProperty.all(
                            const Color(0x80000000),
                          ),
                          trackColor: MaterialStateProperty.all(
                            const Color(0x26FFFFFF),
                          ),
                          thickness: MaterialStateProperty.all(7),
                          radius: const Radius.circular(3.5),
                          thumbVisibility: MaterialStateProperty.all(true),
                          trackVisibility: MaterialStateProperty.all(true),
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(right: 20, bottom: 24),
                            children: const [
                              _SectionBlock(
                                title: '1. Information We Collect',
                                body:
                                    'We collect information you provide directly to us, such as name, phone number, email, and address. We use this data to provide and improve the service.',
                              ),
                              _SectionBlock(
                                title: '2. How We Use Your\n Information',
                                body:
                                    'We use your data to process orders, communicate with you, improve the app and comply with legal obligations.',
                              ),
                              _SectionBlock(
                                title: '3. Sharing',
                                body:
                                    'We may share your information with service providers, partners, and legal authorities when required. We do not sell your personal information.',
                              ),
                              _SectionBlock(
                                title: '4. Security',
                                body:
                                    'We use reasonable measures to protect your data. No method of transmission over the internet is 100% secure.',
                              ),
                              _SectionBlock(
                                title: '5. Your Rights',
                                body:
                                    'You may access, correct, or delete your data through the app or by contacting us. You may also opt out of marketing communications.',
                              ),
                              _SectionBlock(
                                title: '6. Cookies & Similar Tech',
                                body:
                                    'The app may use local storage and similar technologies for functionality and analytics.',
                              ),
                              _SectionBlock(
                                title: '7. Children',
                                body:
                                    'The service is not directed as users under 18. We do not knowingly collect data from children.',
                              ),
                              _SectionBlock(
                                title: '8. Changes',
                                body:
                                    'We may update this policy. We will notify you of material changes via the app or email.',
                              ),
                              _SectionBlock(
                                title: '9. Contact',
                                body:
                                    'For privacy questions, contact us at privacy@getmypair.com',
                              ),
                              SizedBox(height: 32),
                            ],
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
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final String body;

  const _SectionBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                softWrap: false,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFDFE7E9),
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            body,
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
