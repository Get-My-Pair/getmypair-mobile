import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_auth_status.dart';
import 'features/auth/domain/usecases/clear_session_locally.dart';
import 'features/auth/domain/usecases/complete_profile.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/get_valid_access_token.dart';
import 'features/auth/domain/usecases/login_with_email.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/send_otp.dart';
import 'features/auth/domain/usecases/verify_otp.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/get_user_profile.dart';
import 'features/profile/domain/usecases/update_user_profile.dart';
import 'features/profile/domain/usecases/upload_profile_image.dart';
import 'features/profile/domain/usecases/address_usecases.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/articles/data/datasources/article_remote_datasource.dart';
import 'features/articles/data/repositories/article_repository_impl.dart';
import 'features/articles/domain/repositories/article_repository.dart';
import 'features/articles/domain/usecases/get_my_articles.dart';
import 'features/articles/domain/usecases/get_article_by_id.dart';
import 'features/articles/domain/usecases/create_article.dart';
import 'features/articles/domain/usecases/upload_article_image.dart';
import 'features/articles/domain/usecases/update_article.dart';
import 'features/articles/domain/usecases/delete_article.dart';
import 'features/payment/data/datasources/payment_remote_datasource.dart';
import 'features/payment/data/repositories/payment_repository_impl.dart';
import 'features/payment/domain/repositories/payment_repository.dart';
import 'features/payment/domain/usecases/payment_usecases.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
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
  if (!sl.isRegistered<GetValidAccessToken>()) {
    sl.registerLazySingleton(() => GetValidAccessToken(sl()));
  }
  if (!sl.isRegistered<ClearSessionLocally>()) {
    sl.registerLazySingleton(() => ClearSessionLocally(sl()));
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
        clearSessionLocally: sl(),
      ),
    );
  }

  //! Features - Profile
  if (!sl.isRegistered<ProfileRemoteDataSource>()) {
    sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(),
    );
  }
  if (!sl.isRegistered<ProfileRepository>()) {
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<GetUserProfile>()) {
    sl.registerLazySingleton(() => GetUserProfile(sl()));
  }
  if (!sl.isRegistered<UpdateUserProfile>()) {
    sl.registerLazySingleton(() => UpdateUserProfile(sl()));
  }
  if (!sl.isRegistered<UploadProfileImage>()) {
    sl.registerLazySingleton(() => UploadProfileImage(sl()));
  }
  if (!sl.isRegistered<AddAddress>()) {
    sl.registerLazySingleton(() => AddAddress(sl()));
  }
  if (!sl.isRegistered<UpdateAddress>()) {
    sl.registerLazySingleton(() => UpdateAddress(sl()));
  }
  if (!sl.isRegistered<DeleteAddress>()) {
    sl.registerLazySingleton(() => DeleteAddress(sl()));
  }
  if (!sl.isRegistered<AddFamilyMember>()) {
    sl.registerLazySingleton(() => AddFamilyMember(sl()));
  }
  if (!sl.isRegistered<UpdateFamilyMember>()) {
    sl.registerLazySingleton(() => UpdateFamilyMember(sl()));
  }
  if (!sl.isRegistered<ProfileBloc>()) {
    sl.registerFactory(
      () => ProfileBloc(
        getUserProfile: sl(),
        updateUserProfile: sl(),
        uploadProfileImage: sl(),
        addAddress: sl(),
        updateAddress: sl(),
        deleteAddress: sl(),
        addFamilyMember: sl(),
        updateFamilyMember: sl(),
      ),
    );
  }

  //! Features - Articles (Module 3)
  if (!sl.isRegistered<ArticleRemoteDataSource>()) {
    sl.registerLazySingleton<ArticleRemoteDataSource>(
      () => ArticleRemoteDataSourceImpl(),
    );
  }
  if (!sl.isRegistered<ArticleRepository>()) {
    sl.registerLazySingleton<ArticleRepository>(
      () => ArticleRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<GetMyArticles>()) {
    sl.registerLazySingleton(() => GetMyArticles(sl()));
  }
  if (!sl.isRegistered<GetArticleById>()) {
    sl.registerLazySingleton(() => GetArticleById(sl()));
  }
  if (!sl.isRegistered<CreateArticle>()) {
    sl.registerLazySingleton(() => CreateArticle(sl()));
  }
  if (!sl.isRegistered<UploadArticleImage>()) {
    sl.registerLazySingleton(() => UploadArticleImage(sl()));
  }
  if (!sl.isRegistered<UpdateArticle>()) {
    sl.registerLazySingleton(() => UpdateArticle(sl()));
  }
  if (!sl.isRegistered<DeleteArticle>()) {
    sl.registerLazySingleton(() => DeleteArticle(sl()));
  }

  //! Features - Payment (Module 5)
  if (!sl.isRegistered<PaymentRemoteDataSource>()) {
    sl.registerLazySingleton<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<PaymentRepository>()) {
    sl.registerLazySingleton<PaymentRepository>(
      () => PaymentRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<GetPaymentHistory>()) {
    sl.registerLazySingleton(() => GetPaymentHistory(sl()));
  }
  if (!sl.isRegistered<GetPaymentDetails>()) {
    sl.registerLazySingleton(() => GetPaymentDetails(sl()));
  }
  if (!sl.isRegistered<CreatePaymentLink>()) {
    sl.registerLazySingleton(() => CreatePaymentLink(sl()));
  }
  if (!sl.isRegistered<VerifyPayment>()) {
    sl.registerLazySingleton(() => VerifyPayment(sl()));
  }
  if (!sl.isRegistered<RefreshPaymentStatus>()) {
    sl.registerLazySingleton(() => RefreshPaymentStatus(sl()));
  }
  if (!sl.isRegistered<GetPaymentByServiceRequest>()) {
    sl.registerLazySingleton(() => GetPaymentByServiceRequest(sl()));
  }
  if (!sl.isRegistered<PaymentBloc>()) {
    sl.registerFactory(
      () => PaymentBloc(
        getPaymentHistory: sl(),
        getPaymentDetails: sl(),
        createPaymentLink: sl(),
        verifyPayment: sl(),
        refreshPaymentStatus: sl(),
      ),
    );
  }

  _isInitialized = true;
}

