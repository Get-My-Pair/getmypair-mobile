import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/check_auth_status.dart';
import '../../domain/usecases/clear_session_locally.dart';
import '../../domain/usecases/complete_profile.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/send_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOTP sendOTP;
  final VerifyOTP verifyOTP;
  final LoginWithEmail loginWithEmail;
  final CompleteProfile completeProfile;
  final GetCurrentUser getCurrentUser;
  final Logout logout;
  final CheckAuthStatus checkAuthStatus;
  final ClearSessionLocally clearSessionLocally;

  AuthBloc({
    required this.sendOTP,
    required this.verifyOTP,
    required this.loginWithEmail,
    required this.completeProfile,
    required this.getCurrentUser,
    required this.logout,
    required this.checkAuthStatus,
    required this.clearSessionLocally,
  }) : super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthSendOTP>(_onSendOTP);
    on<AuthVerifyOTP>(_onVerifyOTP);
    on<AuthLoginWithEmail>(_onLoginWithEmail);
    on<AuthCompleteProfile>(_onCompleteProfile);
    on<AuthLogout>(_onLogout);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthClearError>(_onClearError);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Login state is governed by ONLY two events:
    //   1. Refresh token expired / rejected by backend (AuthenticationFailure)
    //   2. Manual logout (handled by AuthLogout)
    // Any other failure (network down, backend 5xx, parse error, etc.) must
    // NOT log the user out. We keep them on the dashboard with cached data
    // and let a later launch / API call refresh once connectivity returns.
    final result = await checkAuthStatus();
    final isAuthenticated = result.fold((_) => false, (value) => value);
    if (!isAuthenticated) {
      emit(const AuthUnauthenticated());
      return;
    }

    final userResult = await getCurrentUser();
    userResult.fold(
      (failure) {
        if (failure is AuthenticationFailure) {
          // Refresh token truly invalid – treat as logged out.
          emit(const AuthUnauthenticated());
          return;
        }
        // Transient failure with no cached user available. Do NOT clear the
        // refresh token here; surface as unauthenticated only because we have
        // no User entity to render. Tokens stay in local storage so the next
        // launch can recover the session automatically.
        emit(const AuthUnauthenticated());
      },
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSendOTP(
    AuthSendOTP event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await sendOTP(event.mobile);
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (data) {
        // Extract OTP from response if available (development mode only)
        // OTP might come as int or String from backend
        final otpValue = data['otp'];
        String? otp;
        if (otpValue != null) {
          otp = otpValue is String ? otpValue : otpValue.toString();
        }
        emit(AuthOTPSent(event.mobile, otp: otp));
      },
    );
  }

  Future<void> _onVerifyOTP(
    AuthVerifyOTP event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await verifyOTP(mobile: event.mobile, otp: event.otp);
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (data) {
        final requiresProfileCompletion = data['requiresProfileCompletion'] as bool;
        final user = data['user'] as User?;

        if (requiresProfileCompletion) {
          emit(AuthOTPVerified(
            requiresProfileCompletion: true,
            mobile: event.mobile,
          ));
        } else {
          if (user != null) {
            emit(AuthOTPVerified(
              requiresProfileCompletion: false,
              mobile: event.mobile,
              user: user,
            ));
            emit(AuthAuthenticated(user));
          } else {
            emit(const AuthError('Failed to load user data'));
          }
        }
      },
    );
  }

  Future<void> _onLoginWithEmail(
    AuthLoginWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await loginWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (data) {
        final user = data['user'] as User?;
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthError('Failed to load user data'));
        }
      },
    );
  }

  Future<void> _onCompleteProfile(
    AuthCompleteProfile event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await completeProfile(
      mobile: event.mobile,
      name: event.name,
      dateOfBirth: event.dateOfBirth,
      gender: event.gender,
      householdType: event.householdType,
      location: event.location,
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) {
        emit(AuthProfileCompleted(user));
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onLogout(
    AuthLogout event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await logout();
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await clearSessionLocally();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onClearError(
    AuthClearError event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthError) {
      emit(const AuthUnauthenticated());
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case NetworkFailure:
        return failure.message;
      case CacheFailure:
        return failure.message;
      case ValidationFailure:
        return failure.message;
      case AuthenticationFailure:
        return failure.message;
      default:
        return 'Unexpected error occurred';
    }
  }
}

