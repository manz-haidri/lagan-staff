import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../presentation/job_form_notifier.dart';

class Step6ReviewSubmit extends ConsumerWidget {
  final VoidCallback onSubmitted;
  final VoidCallback onSavedDraft;

  const Step6ReviewSubmit({
    super.key,
    required this.onSubmitted,
    required this.onSavedDraft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(jobFormNotifierProvider);
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);
    final strings = ref.watch(stringsProvider);
    final isHindi = strings.language == AppLanguage.hindi;

    String categoryTitle = isHindi ? 'कार्य' : 'Job';
    categoriesAsync.whenData((cats) {
      final match = cats.where((c) => c.id == formState.categoryId);
      if (match.isNotEmpty) categoryTitle = strings.localizedName(match.first.name);
    });

    final dateStr = formState.shiftDate != null
        ? '${formState.shiftDate!.day}/${formState.shiftDate!.month}/${formState.shiftDate!.year}'
        : '-';

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.reviewJobTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vXs,
          Text(
            strings.reviewJobSubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,

          // Notice banner regarding First-Job Approval vs Auto-Publish
          AppCard(
            borderColor: AppColors.info,
            backgroundColor: AppColors.info.withValues(alpha: 0.08),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.info, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.platformPolicyTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.firstJobApprovalNotice,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vMd,

          // Summary Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Category
                Text(
                  categoryTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.vXs,
                Text(
                  formState.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (formState.description.isNotEmpty) ...[
                  AppSpacing.vXs,
                  Text(
                    formState.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
                const Divider(height: 24),

                // Shift & Timing
                _buildReviewRow(
                  icon: Icons.calendar_today_rounded,
                  label: strings.dateAndShiftLabel,
                  value: '$dateStr • ${formState.startTime.format(context)} - ${formState.endTime.format(context)}${formState.isOvernight ? (isHindi ? ' (रात की शिफ्ट)' : ' (Overnight)') : ''}',
                ),
                AppSpacing.vSm,

                // Workers & Wage
                _buildReviewRow(
                  icon: Icons.people_outline_rounded,
                  label: strings.workersNeededSummaryLabel,
                  value: strings.workersCountSummary(formState.workersNeeded),
                ),
                AppSpacing.vSm,

                _buildReviewRow(
                  icon: Icons.currency_rupee_rounded,
                  label: strings.wageSummaryLabel,
                  value: strings.wageAmountFormatted(formState.wageAmount),
                  valueColor: AppColors.success,
                  isBold: true,
                ),
                AppSpacing.vSm,

                // Location
                _buildReviewRow(
                  icon: Icons.location_on_outlined,
                  label: strings.venueAddressSummaryLabel,
                  value: '${formState.venueName.isNotEmpty ? '${formState.venueName}, ' : ''}${formState.reportingAddress}, ${formState.locality}, ${strings.ghazipurCity} (${formState.pincode})',
                ),
                AppSpacing.vSm,

                // Perks
                _buildReviewRow(
                  icon: Icons.restaurant_rounded,
                  label: strings.foodSummaryLabel,
                  value: formState.foodProvided
                      ? (formState.foodDetails.isNotEmpty
                          ? strings.yesWithDetails(formState.foodDetails)
                          : strings.yesLabel)
                      : strings.noLabel,
                ),
                AppSpacing.vSm,

                _buildReviewRow(
                  icon: Icons.directions_bus_outlined,
                  label: strings.transportSummaryLabel,
                  value: formState.transportProvided
                      ? (formState.transportDetails.isNotEmpty
                          ? strings.yesWithDetails(formState.transportDetails)
                          : strings.yesLabel)
                      : strings.noLabel,
                ),

                if (formState.specialInstructions.isNotEmpty) ...[
                  AppSpacing.vSm,
                  _buildReviewRow(
                    icon: Icons.info_outline_rounded,
                    label: strings.specialInstructionsSummaryLabel,
                    value: formState.specialInstructions,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.vLg,

          // Error / Success Messages
          if (formState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  AppSpacing.hSm,
                  Expanded(
                    child: Text(
                      formState.errorMessage!,
                      style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vMd,
          ],

          if (formState.successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                  AppSpacing.hSm,
                  Expanded(
                    child: Text(
                      formState.successMessage!,
                      style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vMd,
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: formState.isDraftSaving ? strings.savingDraft : strings.saveDraftButton,
                  icon: Icons.save_outlined,
                  onPressed: (formState.isSubmitting || formState.isDraftSaving)
                      ? null
                      : () async {
                          final ok = await formNotifier.saveDraft();
                          if (ok) onSavedDraft();
                        },
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                flex: 2,
                child: AppPrimaryButton(
                  label: formState.isSubmitting ? strings.submittingJob : strings.submitJobButton,
                  icon: Icons.send_rounded,
                  isLoading: formState.isSubmitting,
                  onPressed: formState.isDraftSaving
                      ? null
                      : () async {
                          final ok = await formNotifier.submitJob();
                          if (ok) onSubmitted();
                        },
                ),
              ),
            ],
          ),
          AppSpacing.vXl,
        ],
      ),
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
