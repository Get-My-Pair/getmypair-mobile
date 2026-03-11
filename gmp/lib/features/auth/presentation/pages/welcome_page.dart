import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import 'mobile_otp_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  /// Ask location permission (per app user flow). Called before navigating to login.
  static Future<void> askLocationPermissionIfNeeded() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      await Permission.location.request();
    }
    // If permanently denied, user can enable in settings; we still allow app use.
  }

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _agreedToTerms = false;

  void _goToLogin() async {
    await WelcomePage.askLocationPermissionIfNeeded();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MobileOTPPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPaddingOf(context);
    final logoSize = Responsive.maxLogoSizeOf(context, 0.38);
    final titleSize = Responsive.fontSize(context, 36);
    final bodySize = Responsive.fontSize(context, 16);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 32),
                  // ── Top section: Logo + title + message + features ──
                  Column(
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 28),
                      // Welcome Text
                      Text(
                        'Welcome to',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 18),
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get My Pair',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Find shoes. Fix shoes.\nEverything you need, all in one place.',
                        style: TextStyle(
                          fontSize: bodySize,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Features highlights
                      _buildFeatureRow(
                        icon: Icons.search_rounded,
                        text: 'Browse thousands of shoes',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        icon: Icons.build_rounded,
                        text: 'Find trusted repair services',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        icon: Icons.local_shipping_rounded,
                        text: 'Fast delivery to your doorstep',
                      ),
                    ],
                  ),
                  // ── Bottom section: checkbox + button ──
                  Padding(
                    padding:
                        EdgeInsets.only(bottom: 16 + MediaQuery.paddingOf(context).bottom),
                    child: Column(
                      children: [
                        // Checkbox: only the box toggles on tap (not the whole row)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _agreedToTerms = !_agreedToTerms),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (v) => setState(
                                          () => _agreedToTerms = v ?? false),
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: RichText(
                                  textAlign: TextAlign.left,
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const TermsOfServicePage(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Terms of Service',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PrivacyPolicyPage(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Privacy Policy',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Get Started Button — enabled only when checkbox is ticked
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _agreedToTerms ? _goToLogin : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.textTertiary.withOpacity(0.3),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: _agreedToTerms ? 2 : 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFeatureRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
