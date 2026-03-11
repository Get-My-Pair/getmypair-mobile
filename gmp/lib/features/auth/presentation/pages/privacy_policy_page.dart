import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

/// Sample Privacy Policy page – replace content with your legal text.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPaddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
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
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              _section('1. Information We Collect', 'We collect information you provide (name, phone, email, address), device information, and usage data to provide and improve the service.'),
              _section('2. How We Use It', 'We use your data to process orders, communicate with you, improve the app, and comply with legal obligations.'),
              _section('3. Sharing', 'We may share data with service providers (e.g. payment, delivery) and when required by law. We do not sell your personal information.'),
              _section('4. Security', 'We use reasonable measures to protect your data. No method of transmission over the internet is 100% secure.'),
              _section('5. Your Rights', 'You may access, correct, or delete your data through the app or by contacting us. You may also opt out of marketing communications.'),
              _section('6. Cookies & Similar Tech', 'The app may use local storage and similar technologies for functionality and analytics.'),
              _section('7. Children', 'The service is not directed at users under 18. We do not knowingly collect data from children.'),
              _section('8. Changes', 'We may update this policy. We will notify you of material changes via the app or email.'),
              _section('9. Contact', 'For privacy questions, contact us at privacy@getmypair.com.'),
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
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
