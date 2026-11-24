import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../presentation/job_form_notifier.dart';

class Step2DateShift extends ConsumerWidget {
  const Step2DateShift({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(jobFormNotifierProvider);
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);
    final strings = ref.watch(stringsProvider);

    final shiftDateStr = formState.shiftDate != null
        ? '${formState.shiftDate!.day}/${formState.shiftDate!.month}/${formState.shiftDate!.year}'
        : strings.selectDateAction;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.dateShiftTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vXs,
          Text(
            strings.dateShiftSubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,

          // Shift Date Picker Card
          AppCard(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: formState.shiftDate ?? now.add(const Duration(days: 1)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 90)),
                helpText: strings.selectDateHelp,
              );
              if (picked != null) {
                formNotifier.updateShiftDate(picked);
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.workDateFieldLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        shiftDateStr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
          AppSpacing.vLg,

          // Shift Timings Row
          Row(
            children: [
              // Start Time
              Expanded(
                child: AppCard(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: formState.startTime,
                      helpText: strings.startTimeHelp,
                    );
                    if (picked != null) {
                      formNotifier.updateStartTime(picked);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.startTimeLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      AppSpacing.vXs,
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
                          AppSpacing.hXs,
                          Text(
                            formState.startTime.format(context),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.hMd,

              // End Time
              Expanded(
                child: AppCard(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: formState.endTime,
                      helpText: strings.endTimeHelp,
                    );
                    if (picked != null) {
                      formNotifier.updateEndTime(picked);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.endTimeLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      AppSpacing.vXs,
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
                          AppSpacing.hXs,
                          Text(
                            formState.endTime.format(context),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vLg,

          // Overnight Shift Toggle Card
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                strings.overnightShiftTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                strings.overnightShiftSubtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              value: formState.isOvernight,
              activeThumbColor: AppColors.primary,
              onChanged: formNotifier.updateIsOvernight,
            ),
          ),
        ],
      ),
    );
  }
}
