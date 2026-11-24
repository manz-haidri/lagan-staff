import '../models/user_profile.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  unauthenticated,
  error,
}

class AuthUiState {
  final AuthStatus status;
  final String? errorMessage;
  final String? phone;
  final int resendCooldownSeconds;
  final UserProfile? userProfile;

  const AuthUiState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.phone,
    this.resendCooldownSeconds = 0,
    this.userProfile,
  });

  bool get canResendOtp => resendCooldownSeconds <= 0;
  bool get isAuthenticated => status == AuthStatus.authenticated && userProfile != null;
  bool get hasAssignedRole => userProfile?.primaryRole != null;

  AuthUiState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? phone,
    int? resendCooldownSeconds,
    UserProfile? userProfile,
    bool clearError = false,
  }) {
    return AuthUiState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      phone: phone ?? this.phone,
      resendCooldownSeconds: resendCooldownSeconds ?? this.resendCooldownSeconds,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}
