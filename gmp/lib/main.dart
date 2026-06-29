import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/app_splash_screen.dart';
import 'injection_container.dart' as di;
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAndroidPhotoPicker();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await di.init();
  runApp(const MyApp());
}

/// Use the system photo picker on Android (no READ_MEDIA_* permissions).
void _configureAndroidPhotoPicker() {
  if (!Platform.isAndroid) return;
  final platform = ImagePickerPlatform.instance;
  if (platform is ImagePickerAndroid) {
    platform.useAndroidPhotoPicker = true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>()..add(const AuthCheckStatus()),
      child: MaterialApp(
        title: 'GetMyPair',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          // Clamp accessibility text scaling to a safe responsive range
          // to avoid layout overflows on compact devices.
          final scaledMediaQuery = mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          );
          return MediaQuery(
            data: scaledMediaQuery,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
