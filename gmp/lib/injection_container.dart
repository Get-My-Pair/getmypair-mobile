import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_auth_status.dart';
import 'features/auth/domain/usecases/complete_profile.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/login_with_email.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/send_otp.dart';
import 'features/auth/domain/usecases/verify_otp.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';

final sl = GetIt.instance;
bool _isInitialized = false;

Future<void> init() async {
  // Skip if already initialized (hot reload scenario)
  if (_isInitialized) {
    return;
  }

  //! External - Register first
  final sharedPreferences = await SharedPreferences.getInstance();
  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerLazySingleton(() => sharedPreferences);
  }

  //! Core - Register before data sources
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton(() => DioClient());
  }
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  }

  //! Features - Auth
  // Data sources - Register before repository
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<AuthLocalDataSource>()) {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
    );
  }

  // Repository - Register before use cases
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );
  }

  // Use cases - Register before bloc
  if (!sl.isRegistered<SendOTP>()) {
    sl.registerLazySingleton(() => SendOTP(sl()));
  }
  if (!sl.isRegistered<VerifyOTP>()) {
    sl.registerLazySingleton(() => VerifyOTP(sl()));
  }
  if (!sl.isRegistered<LoginWithEmail>()) {
    sl.registerLazySingleton(() => LoginWithEmail(sl()));
  }
  if (!sl.isRegistered<CompleteProfile>()) {
    sl.registerLazySingleton(() => CompleteProfile(sl()));
  }
  if (!sl.isRegistered<GetCurrentUser>()) {
    sl.registerLazySingleton(() => GetCurrentUser(sl()));
  }
  if (!sl.isRegistered<Logout>()) {
    sl.registerLazySingleton(() => Logout(sl()));
  }
  if (!sl.isRegistered<CheckAuthStatus>()) {
    sl.registerLazySingleton(() => CheckAuthStatus(sl()));
  }

  // Bloc - Register last (depends on all use cases)
  // Use registerFactory which can be re-registered
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(
      () => AuthBloc(
        sendOTP: sl(),
        verifyOTP: sl(),
        loginWithEmail: sl(),
        completeProfile: sl(),
        getCurrentUser: sl(),
        logout: sl(),
        checkAuthStatus: sl(),
      ),
    );
  }

  _isInitialized = true;
}

