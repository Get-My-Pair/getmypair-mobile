import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> sendOTP(String mobile) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendOTP(mobile);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is running on port 3000\n'
        '3. API base URL is correctly configured in api_endpoints.dart'
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyOTP(String mobile, String otp) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.verifyOTP(mobile, otp);
        
        // If existing user, save tokens and user data
        if (response.data?.tokens != null) {
          await localDataSource.saveTokens(response.data!.tokens!);
          if (response.data?.user != null) {
            await localDataSource.saveUser(response.data!.user!);
          }
        }

        return Right({
          'requiresProfileCompletion': response.data?.requiresProfileCompletion ?? false,
          'user': response.data?.user,
          'tokens': response.data?.tokens,
        });
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is running on port 3000\n'
        '3. API base URL is correctly configured in api_endpoints.dart'
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // Email login is not supported by the backend
    // Backend only supports mobile OTP authentication
    return const Left(ServerFailure('Email login is not supported. Please use mobile OTP authentication.'));
  }

  @override
  Future<Either<Failure, User>> completeProfile({
    required String mobile,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.completeProfile(
          mobile: mobile,
          name: name,
          dateOfBirth: dateOfBirth,
          gender: gender,
        );

        // Save tokens if provided in response
        if (response.data?.tokens != null) {
          await localDataSource.saveTokens(response.data!.tokens!);
        }
        
        // Save user data
        if (response.data?.user != null) {
          await localDataSource.saveUser(response.data!.user!);
          return Right(response.data!.user!);
        } else {
          return const Left(ServerFailure('User data not found in response'));
        }
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is running on port 3000\n'
        '3. API base URL is correctly configured in api_endpoints.dart'
      ));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final accessToken = await localDataSource.getAccessToken();
      if (accessToken == null) {
        return const Left(AuthenticationFailure('No access token found'));
      }

      if (await networkInfo.isConnected) {
        try {
          final userModel = await remoteDataSource.getCurrentUser(accessToken);
          await localDataSource.saveUser(userModel);
          return Right(userModel);
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        } on NetworkException catch (e) {
          return Left(NetworkFailure(e.message));
        }
      } else {
        // Try to get from cache
        final cachedUser = await localDataSource.getUser();
        if (cachedUser != null) {
          return Right(cachedUser);
        }
        return const Left(NetworkFailure('No internet connection and no cached user'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      final accessToken = await localDataSource.getAccessToken();

      if (refreshToken != null && await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout(refreshToken, accessToken);
        } catch (e) {
          // Continue to clear local storage even if API call fails
        }
      }

      await localDataSource.clearAll();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final accessToken = await localDataSource.getAccessToken();
      return Right(accessToken != null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> refreshToken() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null) {
        return const Left(AuthenticationFailure('No refresh token found'));
      }

      if (await networkInfo.isConnected) {
        try {
          // Get new access token from backend
          final newAccessToken = await remoteDataSource.refreshToken(refreshToken);
          
          // Save the new access token
          await localDataSource.saveAccessToken(newAccessToken);
          
          return const Right(null);
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        } on NetworkException catch (e) {
          return Left(NetworkFailure(e.message));
        }
      } else {
        return const Left(NetworkFailure('No internet connection'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

