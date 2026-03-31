import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/country_code.dart';
import '../widgets/onboarding_surface.dart';
import 'mobile_otp_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _goToMobileOtp(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MobileOTPPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);
    final india = CountryCode.popularCountries[0];
    final topInset = MediaQuery.paddingOf(context).top;
    final cardTop = topInset + MediaQuery.sizeOf(context).height * 0.22;

    return Scaffold(
      backgroundColor: AppColors.footwearHeroStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.heroDiagonal),
            ),
          ),
          const Positioned.fill(child: OnboardingDotLayer()),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    'Hello!',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                          height: 1.1,
                        ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 17,
                            height: 1.35,
                          ) ??
                          TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 17,
                            height: 1.35,
                          ),
                      children: const [
                        TextSpan(text: 'Welcome to your '),
                        TextSpan(
                          text: 'solecial hub',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.06),
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
                color: AppColors.footwearCardHighlight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Log in',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Enter your phone number',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "We'll text you a quick verification code",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.border.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(india.flag, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 6),
                                  Text(
                                    india.dialCode,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: AppColors.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: AppColors.border.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      color: AppColors.textTertiary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Phone',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _goToMobileOtp(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              'SEND OTP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.textTertiary.withValues(alpha: 0.35),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.textTertiary.withValues(alpha: 0.35),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialTile(
                              backgroundColor: const Color(0xFF1877F2),
                              child: const Center(
                                child: Text(
                                  'f',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
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
                            const SizedBox(width: 16),
                            _SocialTile(
                              backgroundColor: Colors.white,
                              child: const Center(
                                child: Icon(Icons.apple, size: 28, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.textPrimary, width: 2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                  children: const [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
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
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.child,
    required this.backgroundColor,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: child,
        ),
      ),
    );
  }
}
