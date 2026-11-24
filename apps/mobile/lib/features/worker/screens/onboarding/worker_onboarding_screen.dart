import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/auth_helpers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../presentation/worker_onboarding_notifier.dart';
import 'step1_personal_details.dart';
import 'step2_skills_selection.dart';
import 'step3_location_entry.dart';
import 'step4_selfie_capture.dart';
import 'step5_review_submit.dart';

class WorkerOnboardingScreen extends ConsumerStatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  ConsumerState<WorkerOnboardingScreen> createState() =>
      _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState
    extends ConsumerState<WorkerOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      final rawPhone = authState.userProfile?.phone ?? authState.phone ?? '';
      final phone = AuthHelpers.extractPhoneDisplay(rawPhone);
      final fullName = authState.userProfile?.fullName ?? '';

      final notifier = ref.read(workerOnboardingNotifierProvider.notifier);
      notifier.initializeUserData(
        fullName: fullName,
        phone: phone,
      );

      final currentProfile = ref.read(currentWorkerProfileProvider).asData?.value;
      if (currentProfile != null) {
        notifier.loadExistingProfile(currentProfile);
      }
    });
  }

  void _handleNext(WorkerOnboardingState state, WorkerOnboardingNotifier notifier, AppStrings strings) {
    switch (state.currentStep) {
      case 0:
        if (!state.isStep1Valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.fullNameRequiredError),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        notifier.nextStep();
        break;
      case 1:
        if (!state.isStep2Valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.selectAtLeastOneSkillError),
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
              content: Text(strings.invalidLocationPincodeError),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        notifier.nextStep();
        break;
      case 3:
        if (!state.isStep4Valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.selfieRequiredError),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        notifier.nextStep();
        break;
    }
  }

  Future<void> _handleSubmit(
      WorkerOnboardingState state, WorkerOnboardingNotifier notifier, AppStrings strings) async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.sessionExpired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await notifier.submitOnboarding(userId: user.id);
    if (success && mounted) {
      ref.invalidate(currentWorkerProfileProvider);
      ref.invalidate(publishedJobsProvider);
      await ref.read(authNotifierProvider.notifier).restoreSession();

      if (mounted) {
        _showSuccessDialog(strings);
      }
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
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              AppSpacing.vLg,
              Text(
                strings.congratulationsAccountActive,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vSm,
              Text(
                strings.accountActiveDesc,
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
                  label: strings.browseJobsAction,
                  icon: Icons.work_outline_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/worker/home');
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
    final state = ref.watch(workerOnboardingNotifierProvider);
    final notifier = ref.read(workerOnboardingNotifierProvider.notifier);

    final stepLabels = [
      strings.workerStep1Label,
      strings.workerStep2Label,
      strings.workerStep3Label,
      strings.workerStep4Label,
      strings.workerStep5Label,
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (state.currentStep > 0) {
          notifier.previousStep();
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/worker/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 4,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              strings.onboardingStepProgress(state.currentStep + 1, 5, stepLabels[state.currentStep]),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          actions: const [
            LanguageSelectorButton(),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: strings.previous,
            onPressed: () {
              if (state.currentStep > 0) {
                notifier.previousStep();
              } else {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/worker/home');
                }
              }
            },
          ),
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

            // Bottom Navigation Controls for Steps 0-3
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
    ),
    );
  }

  Widget _buildCurrentStep(
      WorkerOnboardingState state, WorkerOnboardingNotifier notifier, AppStrings strings) {
    switch (state.currentStep) {
      case 0:
        return Step1PersonalDetails(state: state, notifier: notifier, strings: strings);
      case 1:
        return Step2SkillsSelection(state: state, notifier: notifier, strings: strings);
      case 2:
        return Step3LocationDetails(state: state, notifier: notifier, strings: strings);
      case 3:
        return Step4SelfieCapture(state: state, notifier: notifier, strings: strings);
      case 4:
        return Step5ReviewSubmit(
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
