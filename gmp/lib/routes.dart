import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/auth/presentation/pages/mobile_otp_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';
import 'features/auth/presentation/pages/profile_completion_page.dart';
import 'features/dashboard/presentation/pages/customer_dashboard_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'injection_container.dart' as di;
import 'features/shop/presentation/pages/product_list_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String mobileOTP = '/mobile-otp';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileCompletion = '/profile-completion';
  static const String customerDashboard = '/customer-dashboard';
  static const String profile = '/profile';
  static const String products = '/products';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case mobileOTP:
        return MaterialPageRoute(builder: (_) => const MobileOTPPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OTPPage(mobile: args?['mobile'] ?? ''),
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
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

