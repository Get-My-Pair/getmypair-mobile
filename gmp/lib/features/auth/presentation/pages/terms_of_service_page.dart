import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/gradient_page_shell.dart';

/// Sample Terms of Service page – replace content with your legal text.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPaddingOf(context);
    return GradientPageShell(
      appBar: buildGradientAppBar(
        title: 'Terms of Service',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated: March 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onGradientMuted,
                ),
              ),
              const SizedBox(height: 24),
              _section('1. Acceptance of Terms', 'By accessing or using Get My Pair, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app.'),
              _section('2. Use of Service', 'You may use the app to browse shoes, find repair services, and place orders. You must provide accurate information and use the service only for lawful purposes.'),
              _section('3. Account', 'You are responsible for keeping your account credentials secure. Notify us immediately of any unauthorized use.'),
              _section('4. Orders & Payments', 'Orders are subject to availability. Prices and delivery terms are as shown at checkout. Refunds follow our refund policy.'),
              _section('5. Prohibited Conduct', 'You may not misuse the app, harm others, or violate any laws. We may suspend or terminate access for violations.'),
              _section('6. Intellectual Property', 'Content and branding in the app are owned by Get My Pair or its licensors. You may not copy or use them without permission.'),
              _section('7. Limitation of Liability', 'The app is provided "as is." We are not liable for indirect, incidental, or consequential damages arising from your use.'),
              _section('8. Changes', 'We may update these terms from time to time. Continued use after changes means you accept the updated terms.'),
              _section('9. Contact', 'For questions about these terms, contact us at support@getmypair.com.'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.onGradientBody,
            ),
          ),
        ],
      ),
    );
  }
}
