import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/auth_helpers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../presentation/owner_onboarding_notifier.dart';
import 'step1_category_selection.dart';
import 'step2_business_details.dart';
import 'step3_business_location.dart';
import 'step4_document_upload.dart';
import 'step5_review_submission.dart';

class OwnerOnboardingScreen extends ConsumerStatefulWidget {
  const OwnerOnboardingScreen({super.key});

  @override
  ConsumerState<OwnerOnboardingScreen> createState() =>
      _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends ConsumerState<OwnerOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authNotifierProvider);
      final rawPhone = authState.userProfile?.phone ?? authState.phone ?? '';
      final phone = AuthHelpers.extractPhoneDisplay(rawPhone);
      final fullName = authState.userProfile?.fullName ?? '';

      final notifier = ref.read(ownerOnboardingNotifierProvider.notifier);
      notifier.initializeFromProfile(ownerName: fullName, verifiedPhone: phone);

      // Check if owner already has an existing business draft
      final existingBiz = await ref.read(currentOwnerBusinessProvider.future);
      if (existingBiz != null) {
        notifier.loadExistingBusiness(existingBiz);
      }
    });
  }

  void _handleNext(OwnerOnboardingState state, OwnerOnboardingNotifier notifier, AppStrings strings) {
    switch (state.currentStep) {
      case 0:
        notifier.nextStep();
        break;
      case 1:
        if (!state.isStep2Valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.enterBusinessNameError),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        notifier.nextStep();
        break;
      case 2:
        if (!state.isStep3Valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.enterValidPincodeError),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        notifier.nextStep();
        break;
      case 3:
        notifier.nextStep();
        break;
    }
  }

  Future<void> _handleSubmit(
      OwnerOnboardingState state, OwnerOnboardingNotifier notifier, AppStrings strings) async {
    final success = await notifier.submitForVerification();
    if (success && mounted) {
      ref.invalidate(currentOwnerBusinessProvider);
      _showSuccessDialog(strings);
    } else if (mounted && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog(AppStrings strings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              AppSpacing.vLg,
              Text(
                strings.applicationSubmittedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vSm,
              Text(
                strings.applicationSubmittedDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              AppSpacing.vLg,
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: strings.goToDashboardAction,
                  icon: Icons.dashboard_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/owner/home');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final state = ref.watch(ownerOnboardingNotifierProvider);
    final notifier = ref.read(ownerOnboardingNotifierProvider.notifier);

    final stepLabels = [
      strings.ownerStep1Label,
      strings.ownerStep2Label,
      strings.ownerStep3Label,
      strings.ownerStep4Label,
      strings.ownerStep5Label,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 4,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(strings.onboardingStepProgress(state.currentStep + 1, 5, stepLabels[state.currentStep]),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ),
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => notifier.previousStep(),
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.go('/owner/home'),
              ),
        actions: [
          const LanguageSelectorButton(),
          TextButton.icon(
            icon: const Icon(Icons.save_outlined, size: 18, color: AppColors.primary),
            label: Text(
              strings.draftButton,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            onPressed: () async {
              final saved = await notifier.saveDraft();
              if (saved && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.draftSavedSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (state.currentStep + 1) / 5,
            backgroundColor: AppColors.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: _buildCurrentStep(state, notifier, strings),
              ),
            ),

            // Bottom Navigation Controls
            if (state.currentStep < 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (state.currentStep > 0) ...[
                      Expanded(
                        flex: 1,
                        child: AppSecondaryButton(
                          label: strings.previous,
                          onPressed: () => notifier.previousStep(),
                        ),
                      ),
                      AppSpacing.hMd,
                    ],
                    Expanded(
                      flex: 2,
                      child: AppPrimaryButton(
                        label: strings.next,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => _handleNext(state, notifier, strings),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(
      OwnerOnboardingState state, OwnerOnboardingNotifier notifier, AppStrings strings) {
    switch (state.currentStep) {
      case 0:
        return Step1CategorySelection(state: state, notifier: notifier, strings: strings);
      case 1:
        return Step2BusinessDetails(state: state, notifier: notifier, strings: strings);
      case 2:
        return Step3BusinessLocation(state: state, notifier: notifier, strings: strings);
      case 3:
        return Step4DocumentUpload(state: state, notifier: notifier, strings: strings);
      case 4:
        return Step5ReviewSubmission(
          state: state,
          notifier: notifier,
          strings: strings,
          onSubmit: () => _handleSubmit(state, notifier, strings),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
