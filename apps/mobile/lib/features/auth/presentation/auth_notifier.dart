import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/auth_helpers.dart';
import '../data/auth_repository.dart';
import '../models/user_profile.dart';
import 'auth_state.dart';

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthUiState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthUiState> {
  Timer? _cooldownTimer;

  @override
  AuthUiState build() {
    ref.onDispose(() {
      _cooldownTimer?.cancel();
    });

    // Check for existing session upon initialization
    Future.microtask(() => restoreSession());

    return const AuthUiState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Sends a 6-digit SMS OTP to a 10-digit Indian mobile number
  Future<bool> sendOtp(String rawPhone) async {
    final repository = ref.read(authRepositoryProvider);

    // 1. Validation
    if (!AuthHelpers.isValidIndianPhone(rawPhone)) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please enter a valid 10-digit mobile number.',
      );
      return false;
    }

    final e164Phone = AuthHelpers.formatToE164(rawPhone);
    state = state.copyWith(
      status: AuthStatus.loading,
      phone: e164Phone,
      clearError: true,
    );

    try {
      await repository.signInWithOtp(e164Phone);

      state = state.copyWith(
        status: AuthStatus.otpSent,
        phone: e164Phone,
        resendCooldownSeconds: 60,
        clearError: true,
      );

      _startCooldownTimer();
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthNotifier] sendOtp AuthException: ${e.message}');
      String userMessage = e.message;
      if (e.message.toLowerCase().contains('rate') || e.message.toLowerCase().contains('limit')) {
        userMessage = 'Too many attempts. Please try again in 1 minute.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userMessage,
      );
      return false;
    } catch (e) {
      debugPrint('[AuthNotifier] sendOtp unexpected error: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Connection error: Please check your internet connection.',
      );
      return false;
    }
  }

  /// Verifies the 6-digit SMS OTP
  Future<bool> verifyOtp(String otpToken) async {
    final repository = ref.read(authRepositoryProvider);
    final phone = state.phone;

    if (phone == null || phone.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Mobile number not found. Please log in again.',
      );
      return false;
    }

    if (!AuthHelpers.isValidSixDigitOtp(otpToken)) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please enter a valid 6-digit OTP (e.g. 123456).',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final response = await repository.verifyOtp(
        e164Phone: phone,
        otpToken: otpToken,
      );

      if (response.user != null) {
        // Fetch or create profile and role status
        final profile = await repository.fetchUserProfileAndRole();

        state = state.copyWith(
          status: AuthStatus.authenticated,
          userProfile: profile ?? UserProfile(id: response.user!.id, phone: phone),
          clearError: true,
        );
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification failed. Please check the OTP and try again.',
      );
      return false;
    } on AuthException catch (e) {
      debugPrint('[AuthNotifier] verifyOtp AuthException: ${e.message}');
      String userMessage = 'Invalid or expired OTP. (Test Mode: 123456)';
      if (e.message.toLowerCase().contains('expired')) {
        userMessage = 'OTP has expired. Please click Resend.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification error: Please enter 123456.',
      );
      return false;
    }
  }

  /// Resends OTP if cooldown timer has elapsed
  Future<bool> resendOtp() async {
    if (!state.canResendOtp || state.phone == null) return false;
    return await sendOtp(state.phone!);
  }

  /// Starts 60-second cooldown timer for OTP resend
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSeconds = state.resendCooldownSeconds;
      if (currentSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(resendCooldownSeconds: 0);
      } else {
        state = state.copyWith(resendCooldownSeconds: currentSeconds - 1);
      }
    });
  }

  /// Assigns initial role (Worker / Owner) via PostgreSQL RPC
  Future<bool> assignInitialRole({
    required String role,
    required String fullName,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final updatedProfile = await repository.assignInitialRole(
        role: role,
        fullName: fullName,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: updatedProfile,
        clearError: true,
      );
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthNotifier] assignInitialRole AuthException: ${e.message}');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      debugPrint('[AuthNotifier] assignInitialRole unexpected error: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to assign role: $e',
      );
      return false;
    }
  }

  /// Restores session on app startup
  Future<void> restoreSession() async {
    final repository = ref.read(authRepositoryProvider);
    final session = repository.currentSession;

    if (session != null) {
      try {
        final profile = await repository.fetchUserProfileAndRole();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          phone: session.user.phone ?? session.user.email ?? '',
          userProfile: profile ??
              UserProfile(
                id: session.user.id,
                phone: session.user.phone ?? session.user.email ?? '',
              ),
        );
      } catch (e) {
        debugPrint('[AuthNotifier] Session restore profile fetch failed: $e');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          phone: session.user.phone ?? session.user.email ?? '',
          userProfile: UserProfile(
            id: session.user.id,
            phone: session.user.phone ?? session.user.email ?? '',
          ),
        );
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Signs out current user
  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    _cooldownTimer?.cancel();
    state = const AuthUiState();
  }
}
