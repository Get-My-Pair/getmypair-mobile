import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.82, 0.05),
              end: Alignment(-0.17, 1.22),
              colors: [
                Color(0xFF062F35),
                Color(0xFF0F6876),
                Color(0xFF09E0FF),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFFDFE7E9),
                      fontSize: 24,
                      fontFamily: 'Boldonse',
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Last Updated March 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        child: ListView(
                          children: const [
                            _SectionBlock(
                              title: '1. Information We Collect',
                              body:
                                  'We collect information you provide directly to us, such as name, phone number, email, and address. We use this data to provide and improve the service.',
                            ),
                            _SectionBlock(
                              title: '2. How We Use Your\nInformation',
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
    final isMultiLineTitle = title.contains('\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: isMultiLineTitle ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 24,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFFDFE7E9),
              fontSize: 14,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
