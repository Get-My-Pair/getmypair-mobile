import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter_bloc/flutter_bloc.dart';
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/auth/presentation/pages/mobile_otp_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';
import 'features/auth/presentation/pages/profile_completion_page.dart';
import 'features/dashboard/presentation/pages/customer_dashboard_page.dart';
<<<<<<< HEAD
=======
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'injection_container.dart' as di;
import 'features/shop/presentation/pages/product_list_page.dart';
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String mobileOTP = '/mobile-otp';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileCompletion = '/profile-completion';
  static const String customerDashboard = '/customer-dashboard';
<<<<<<< HEAD
=======
  static const String profile = '/profile';
  static const String products = '/products';
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590

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
<<<<<<< HEAD
          builder: (_) => OTPPage(mobile: args?['mobile'] ?? ''),
=======
          builder: (_) => OTPPage(
            mobile: args?['mobile'] ?? '',
            countryCode: args?['countryCode'],
            phoneNumber: args?['phoneNumber'],
            prefilledOtp: args?['prefilledOtp'],
          ),
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590
        );
      case profileCompletion:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProfileCompletionPage(mobile: args?['mobile'] ?? ''),
        );
      case customerDashboard:
        return MaterialPageRoute(builder: (_) => const CustomerDashboardPage());
<<<<<<< HEAD
=======
      case profile:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<ProfileBloc>(),
            child: const ProfilePage(),
          ),
        );
      case products:
        return MaterialPageRoute(builder: (_) => const ProductListPage());
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590
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

