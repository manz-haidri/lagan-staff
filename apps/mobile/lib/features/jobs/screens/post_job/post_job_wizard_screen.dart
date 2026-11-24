import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../owner/presentation/owner_onboarding_notifier.dart';
import '../../presentation/job_form_notifier.dart';
import 'step1_job_info.dart';
import 'step2_date_shift.dart';
import 'step3_payment.dart';
import 'step4_venue_location.dart';
import 'step5_perks_requirements.dart';
import 'step6_review_submit.dart';

class PostJobWizardScreen extends ConsumerStatefulWidget {
  const PostJobWizardScreen({super.key});

  @override
  ConsumerState<PostJobWizardScreen> createState() => _PostJobWizardScreenState();
}

class _PostJobWizardScreenState extends ConsumerState<PostJobWizardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = ref.read(currentOwnerBusinessProvider).asData?.value;
      if (biz != null) {
        ref.read(jobFormNotifierProvider.notifier).initForBusiness(
          biz.id,
          defaultLocality: biz.locality,
          defaultAddress: biz.address,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(jobFormNotifierProvider);
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);
    final bizAsync = ref.watch(currentOwnerBusinessProvider);
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          formState.jobId != null ? strings.editJobTitle : strings.postNewJobTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          const LanguageSelectorButton(),
          TextButton.icon(
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(strings.draftButton, style: const TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () async {
              final ok = await formNotifier.saveDraft();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.draftSavedSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: bizAsync.when(
          data: (biz) {
            if (biz == null || !biz.verificationStatus.isVerified) {
              return Center(
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_clock_rounded, size: 56, color: AppColors.warning),
                      AppSpacing.vMd,
                      Text(
                        strings.businessVerificationPendingTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.vSm,
                      Text(
                        strings.businessVerificationPendingDesc,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.vLg,
                      AppPrimaryButton(
                        label: strings.returnToDashboard,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Stepper Progress Header
                _buildProgressHeader(formState.currentStep, strings),

                // Step Body
                Expanded(
                  child: _buildCurrentStep(formState.currentStep, strings),
                ),

                // Bottom Navigation Bar (Steps 0-4)
                if (formState.currentStep < 5) _buildBottomBar(formState.currentStep, strings),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(int currentStep, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.onboardingStepProgress(currentStep + 1, 6, _getStepName(currentStep, strings)),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${((currentStep + 1) / 6 * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentStep + 1) / 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  String _getStepName(int step, AppStrings strings) {
    switch (step) {
      case 0:
        return strings.jobInfoTitle;
      case 1:
        return strings.dateShiftTitle;
      case 2:
        return strings.wageTitle;
      case 3:
        return strings.venueLocationTitle;
      case 4:
        return strings.perksRequirementsTitle;
      case 5:
        return strings.reviewJobTitle;
      default:
        return '';
    }
  }

  Widget _buildCurrentStep(int step, AppStrings strings) {
    switch (step) {
      case 0:
        return const Step1JobInfo();
      case 1:
        return const Step2DateShift();
      case 2:
        return const Step3Payment();
      case 3:
        return const Step4VenueLocation();
      case 4:
        return const Step5PerksRequirements();
      case 5:
        return Step6ReviewSubmit(
          onSavedDraft: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.draftSavedSuccess),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          },
          onSubmitted: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.jobSubmittedSuccess),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(int currentStep, AppStrings strings) {
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          if (currentStep > 0) ...[
            Expanded(
              child: AppSecondaryButton(
                label: strings.backStepButton,
                icon: Icons.arrow_back_rounded,
                onPressed: formNotifier.previousStep,
              ),
            ),
            AppSpacing.hMd,
          ],
          Expanded(
            flex: 2,
            child: AppPrimaryButton(
              label: strings.nextStepButton,
              icon: Icons.arrow_forward_rounded,
              onPressed: formNotifier.nextStep,
            ),
          ),
        ],
      ),
    );
  }
}
