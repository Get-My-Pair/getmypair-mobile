import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
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
                padding: const EdgeInsets.fromLTRB(20, 80, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms of Services',
                      style: GoogleFonts.boldonse(
                        color: const Color(0xFFDFE7E9),
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Last Updated March 2026',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: false,
                        radius: const Radius.circular(3.5),
                        thickness: 7,
                        thumbColor: const Color(0x80000000),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(right: 20, bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _TermsSection(
                                number: 1,
                                title: 'Acceptance of Terms',
                                body:
                                    'By accessing or using GetMyPair, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app.',
                              ),
                              _TermsSection(
                                number: 2,
                                title: 'Use of Service',
                                body:
                                    'You may use the app to browse shoes, find repair services, and place orders. You must provide accurate information and use the service only for lawful purposes.',
                              ),
                              _TermsSection(
                                number: 3,
                                title: 'Account',
                                body:
                                    'You are responsible for keeping your account credentials secure. Notify us immediately of any unauthorized use.',
                              ),
                              _TermsSection(
                                number: 4,
                                title: 'Orders & Payments',
                                body:
                                    'Orders are subject to availability. Prices and delivery terms are as shown at checkout. Refunds follow and refund policy.',
                              ),
                              _TermsSection(
                                number: 5,
                                title: 'Prohibited Conduct',
                                body:
                                    'You may not misuse the app, harm others, or violate any laws. We may suspend or terminate access for violations.',
                              ),
                              _TermsSection(
                                number: 6,
                                title: 'Intellectual Property',
                                body:
                                    'Content and branding in the app are owned by GetMyPair or its licensors. You may not copy or use them without permission.',
                              ),
                              _TermsSection(
                                number: 7,
                                title: 'Limitation of Liability',
                                body:
                                    'The app is provided "as is". We are not liable for indirect, incidental, or consequential damages arising from your use.',
                              ),
                              _TermsSection(
                                number: 8,
                                title: 'Changes',
                                body:
                                    'We may update these terms. Continued use means acceptance of the changes.',
                              ),
                              _TermsSection(
                                number: 9,
                                title: 'Contact',
                                body:
                                    'For questions, contact support@getmypair.com',
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
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: 24,
              fontWeight: FontWeight.w300,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            body,
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
