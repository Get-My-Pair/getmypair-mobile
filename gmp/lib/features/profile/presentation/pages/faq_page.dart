import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/chevron_screen_back_button.dart';

/// Profile → FAQ.
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
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
                            'FAQ',
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
                      'Frequently asked questions',
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
                              _FaqItem(
                                number: 1,
                                question: 'What is GetMyPair?',
                                answer:
                                    'GetMyPair is your footwear companion — register pairs in your rack, book repair, wash, maintenance, donate, or dispose services, and track requests from pickup to delivery.',
                              ),
                              _FaqItem(
                                number: 2,
                                question: 'How do I add footwear to my rack?',
                                answer:
                                    'Open My Rack from the home screen, tap add footwear, and fill in brand, model, category, photos, and purchase details. Save to store the pair on your account.',
                              ),
                              _FaqItem(
                                number: 3,
                                question: 'How do I request a service?',
                                answer:
                                    'Select a pair from your rack, choose a service (repair, wash, maintenance, donate, or dispose), add photos if needed, pick pickup details, and confirm on the summary screen.',
                              ),
                              _FaqItem(
                                number: 4,
                                question: 'How can I track my request?',
                                answer:
                                    'Go to Profile → My Orders (or Service requests) to see status, tracking steps, costs, and proof photos you submitted.',
                              ),
                              _FaqItem(
                                number: 5,
                                question: 'What are estimated vs final costs?',
                                answer:
                                    'You see an estimate when you create a request. After inspection, the team may send a final service cost — accept or reject it before work continues.',
                              ),
                              _FaqItem(
                                number: 6,
                                question: 'How do I update my profile or address?',
                                answer:
                                    'From Profile, use Edit Profile for name and details, or Saved Addresses to add or change pickup locations.',
                              ),
                              _FaqItem(
                                number: 7,
                                question: 'Who do I contact for help?',
                                answer:
                                    'Email support@getmypair.com for account, orders, or app issues. Include your registered mobile number when possible.',
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

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.number,
    required this.question,
    required this.answer,
  });

  final int number;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final questionFont =
        Responsive.fontSizeClamped(context, 18, min: 15, max: 20);
    final answerFont =
        Responsive.fontSizeClamped(context, 14, min: 12, max: 14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $question',
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: questionFont,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDFE7E9),
              fontSize: answerFont,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
