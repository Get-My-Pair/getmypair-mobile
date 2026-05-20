import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/chevron_screen_back_button.dart';

/// Profile → License (software use & third-party notices).
class AppLicensePage extends StatefulWidget {
  const AppLicensePage({super.key});

  @override
  State<AppLicensePage> createState() => _AppLicensePageState();
}

class _AppLicensePageState extends State<AppLicensePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPaddingOf(context);
    final titleFont = Responsive.fontSizeClamped(context, 24, min: 20, max: 24);
    final subtitleFont =
        Responsive.fontSizeClamped(context, 12, min: 11, max: 13);

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
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  (30 * (MediaQuery.sizeOf(context).height / 844))
                      .clamp(30.0, 30.0),
                  8,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ChevronScreenBackButton(
                          iconColor: Color(0xFFDFE7E9),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'License',
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFFDFE7E9),
                              fontSize: titleFont,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Last Updated March 2026',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: subtitleFont,
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
                          padding: EdgeInsets.only(
                            right: Responsive.horizontalPaddingOf(context),
                            bottom: 24,
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LicenseSection(
                                number: 1,
                                title: 'Application License',
                                body:
                                    'GetMyPair grants you a limited, non-exclusive, non-transferable license to install and use the mobile application for personal, non-commercial purposes in accordance with these terms and applicable law.',
                              ),
                              _LicenseSection(
                                number: 2,
                                title: 'Ownership',
                                body:
                                    'The app, including software, design, logos, and content (excluding your user-submitted footwear data), is owned by GetMyPair or its licensors and is protected by copyright and other intellectual property laws.',
                              ),
                              _LicenseSection(
                                number: 3,
                                title: 'Restrictions',
                                body:
                                    'You may not copy, modify, reverse engineer, distribute, sell, or lease any part of the app; attempt to extract source code; or use the service to build a competing product without written permission.',
                              ),
                              _LicenseSection(
                                number: 4,
                                title: 'Open Source & Third-Party',
                                body:
                                    'The app may include open-source libraries and third-party services (for example maps, analytics, or cloud storage). Those components are subject to their own licenses, which are available on request or in project documentation where applicable.',
                              ),
                              _LicenseSection(
                                number: 5,
                                title: 'User Content',
                                body:
                                    'Photos and information you upload remain yours. You grant GetMyPair a license to use that content to provide and improve services (for example processing repair requests and storing your rack).',
                              ),
                              _LicenseSection(
                                number: 6,
                                title: 'Termination',
                                body:
                                    'This license ends if you stop using the app, delete your account, or if we suspend access for a violation. Sections on ownership and limitations survive termination where required by law.',
                              ),
                              _LicenseSection(
                                number: 7,
                                title: 'Disclaimer',
                                body:
                                    'The app is provided "as is" without warranties of any kind, whether express or implied, to the fullest extent permitted by law.',
                              ),
                              _LicenseSection(
                                number: 8,
                                title: 'Contact',
                                body:
                                    'For licensing questions, contact legal@getmypair.com or support@getmypair.com.',
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

class _LicenseSection extends StatelessWidget {
  const _LicenseSection({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final sectionTitleFont =
        Responsive.fontSizeClamped(context, 24, min: 18, max: 24);
    final sectionBodyFont =
        Responsive.fontSizeClamped(context, 14, min: 12, max: 14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: sectionTitleFont,
              fontWeight: FontWeight.w300,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            body,
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: sectionBodyFont,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
