import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/language_selector_widget.dart';
import '../../../core/utils/auth_helpers.dart';
import '../../../core/widgets/app_buttons.dart';
import '../models/user_profile.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerify() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.verifyOtp(_otpController.text.trim());

    if (success && mounted) {
      final userProfile = ref.read(authNotifierProvider).userProfile;
      final role = userProfile?.primaryRole;

      if (role == null) {
        // Needs role selection
        context.go('/select-role');
      } else if (role == AppUserRole.worker) {
        context.go('/worker/home');
      } else if (role == AppUserRole.owner) {
        context.go('/owner/home');
      } else if (role == AppUserRole.admin) {
        context.go('/access-denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(authNotifierProvider);
    final strings = ref.watch(stringsProvider);
    final phoneDisplay = AuthHelpers.extractPhoneDisplay(uiState.phone ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.otpVerificationTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: const [
          LanguageSelectorButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.vLg,

              // Top Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.vLg,

              Text(
                strings.enterSixDigitOtp,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vXs,
              Text(
                strings.verificationCodeSentTo('+91 $phoneDisplay'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.vXxl,

              // Verification Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimensions.roundedLarge,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Test OTP Helper Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Soft Blue
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                                children: [
                                  TextSpan(text: 'Test OTP: '),
                                  TextSpan(
                                    text: '123456',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                  TextSpan(text: ' (Click below or type to fill)'),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              _otpController.text = '123456';
                              _handleVerify();
                            },
                            child: Text(strings.autoFill, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vLg,

                    // 6-Digit OTP Field
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 12,
                        color: AppColors.textPrimary,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        hintText: '••••••',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          color: AppColors.textMuted,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    // Error Banner
                    if (uiState.errorMessage != null) ...[
                      AppSpacing.vMd,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                            AppSpacing.hSm,
                            Expanded(
                              child: Text(
                                uiState.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    AppSpacing.vXl,

                    // Verify Button
                    AppPrimaryButton(
                      label: strings.verifyAndContinue,
                      isLoading: uiState.status == AuthStatus.loading,
                      onPressed: _handleVerify,
                    ),

                    AppSpacing.vLg,

                    // Resend OTP Action
                    Center(
                      child: uiState.canResendOtp
                          ? TextButton(
                              onPressed: () {
                                ref.read(authNotifierProvider.notifier).resendOtp();
                              },
                              child: Text(
                                strings.resendOtp,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Text(
                              strings.resendOtpIn(uiState.resendCooldownSeconds),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              AppSpacing.vXl,

              // Change Phone Option
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(strings.changePhoneNumber),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
