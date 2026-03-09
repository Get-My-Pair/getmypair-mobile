import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import 'mobile_otp_page.dart';

class WelcomePage extends StatelessWidget {
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
                children: [
                  const Spacer(flex: 1),
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
              
              const SizedBox(height: 32),
              
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
              
              const Spacer(flex: 2),
              
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
              
              const Spacer(flex: 2),
              
              // Get Started Button — ask location permission then go to login
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await WelcomePage.askLocationPermissionIfNeeded();
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MobileOTPPage(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
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
              
              const SizedBox(height: 16),
              
              // Terms text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
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

