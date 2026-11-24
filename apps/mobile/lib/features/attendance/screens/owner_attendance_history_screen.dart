import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_loaders.dart';
import '../../../core/widgets/empty_state.dart';
import '../../jobs/data/job_repository.dart';
import '../../owner/presentation/owner_onboarding_notifier.dart';

class OwnerAttendanceHistoryScreen extends ConsumerWidget {
  const OwnerAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bizAsync = ref.watch(currentOwnerBusinessProvider);
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.attendanceHistoryTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          LanguageSelectorButton(),
          SizedBox(width: 8),
        ],
      ),
      body: bizAsync.when(
        data: (biz) {
          if (biz == null) {
            return Center(child: Text(strings.businessProfileIncomplete));
          }

          return _buildJobAttendanceList(context, ref, biz.id, strings);
        },
        loading: () => Center(child: AppLoader(message: strings.loadingRoster)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildJobAttendanceList(BuildContext context, WidgetRef ref, String businessId, AppStrings strings) {
    final jobsFuture = ref.watch(jobRepositoryProvider).getOwnerJobs(businessId: businessId, statusFilter: 'all');

    return FutureBuilder(
      future: jobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: AppLoader(message: strings.loadingRoster));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: EmptyStateWidget(
                icon: Icons.history_toggle_off_rounded,
                title: strings.noAttendanceHistoryTitle,
                description: strings.noAttendanceHistoryDesc,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: AppSpacing.pagePadding,
          itemCount: jobs.length,
          separatorBuilder: (_, _) => AppSpacing.vMd,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        job.categoryName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      Text(
                        '${job.workersConfirmed}/${job.workersNeeded} ${strings.workerRole}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  AppSpacing.vXs,
                  Text(
                    job.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  AppSpacing.vXs,
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${job.shiftDate} • ${job.formattedShiftTime}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${strings.shiftWageLabel} ₹${job.wageAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                      AppSecondaryButton(
                        label: strings.viewRoster,
                        icon: Icons.people_outline_rounded,
                        onPressed: () => context.push('/owner/attendance/${job.id}'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
