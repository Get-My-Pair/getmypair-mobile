import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/bgtheme.dart';
import 'core/widgets/chevron_screen_back_button.dart';
import 'features/auth/presentation/pages/onboarding/onboarding_flow_page.dart';
import 'features/auth/presentation/pages/mobile_otp_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';
import 'features/auth/presentation/pages/profile_completion_page.dart';
import 'features/dashboard/presentation/pages/customer_dashboard_page.dart';
import 'features/profile/domain/entities/user_profile.dart';
import 'features/profile/presentation/pages/add_family_profile_page.dart';
import 'features/profile/presentation/pages/family_profile_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'injection_container.dart' as di;
import 'features/shop/presentation/pages/product_list_page.dart';
import 'features/articles/presentation/pages/article_list_page.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
import 'features/payment/presentation/pages/payment_history_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String mobileOTP = '/mobile-otp';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileCompletion = '/profile-completion';
  static const String customerDashboard = '/customer-dashboard';
  static const String profile = '/profile';
  static const String products = '/products';
  static const String articleList = '/articles';
  static const String paymentHistory = '/payment/history';
  static const String familyProfile = '/family-profile';
  static const String addFamilyProfile = '/family-profile/add';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const OnboardingFlowPage());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingFlowPage());
      case welcome:
        return MaterialPageRoute(builder: (_) => const MobileOTPPage());
      case mobileOTP:
        return MaterialPageRoute(builder: (_) => const MobileOTPPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OTPPage(
            mobile: args?['mobile'] ?? '',
            countryCode: args?['countryCode'],
            phoneNumber: args?['phoneNumber'],
          ),
        );
      case profileCompletion:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProfileCompletionPage(mobile: args?['mobile'] ?? ''),
        );
      case customerDashboard:
        return MaterialPageRoute(builder: (_) => const CustomerDashboardPage());
      case profile:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<ProfileBloc>(),
            child: const ProfilePage(),
          ),
        );
      case products:
        return MaterialPageRoute(builder: (_) => const ProductListPage());
      case articleList:
        return MaterialPageRoute(builder: (_) => const ArticleListPage());
      case paymentHistory:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider(
            create: (_) => di.sl<PaymentBloc>(),
            child: const PaymentHistoryPage(),
          ),
        );
      case familyProfile:
        return _familyProfileRoute(settings);
      case addFamilyProfile:
        return _addFamilyProfileRoute(settings);
      default:
        return _unknownRoute(settings);
    }
  }

  static Route<dynamic> _familyProfileRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! Map) return _unknownRoute(settings);
    final profile = args['profile'];
    final token = args['accessToken']?.toString() ?? '';
    final bloc = args['bloc'];
    if (profile is! UserProfile || token.isEmpty || bloc is! ProfileBloc) {
      return _unknownRoute(settings);
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: FamilyProfilePage(profile: profile, accessToken: token),
      ),
    );
  }

  static Route<dynamic> _addFamilyProfileRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! Map) return _unknownRoute(settings);
    final token = args['accessToken']?.toString() ?? '';
    final relation = args['relation']?.toString() ?? '';
    final bloc = args['bloc'];
    if (token.isEmpty || relation.isEmpty || bloc is! ProfileBloc) {
      return _unknownRoute(settings);
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: AddFamilyProfilePage(accessToken: token, relation: relation),
      ),
    );
  }

  static Route<dynamic> _unknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const _UnknownRoutePage(),
    );
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BgTheme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(BgTheme.backgroundImageAsset),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ChevronScreenBackButton(iconColor: Colors.white),
                const Spacer(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      children: [
                        Text(
                          'Page not found',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.boldonse(
                            color: const Color(0xFFDFE7E9),
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This screen is not available. Go back and try again.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

