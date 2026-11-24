import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/auth_helpers.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_loaders.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../notifications/presentation/notification_center_notifier.dart';
import '../models/published_job.dart';
import '../models/worker_profile.dart';
import '../presentation/worker_onboarding_notifier.dart';

class WorkerHomeScreen extends ConsumerWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final workerProfileAsync = ref.watch(currentWorkerProfileProvider);
    final jobsAsync = ref.watch(publishedJobsProvider);
    final notifState = ref.watch(notificationCenterProvider);
    final strings = ref.watch(stringsProvider);

    final userProfile = authState.userProfile;
    final fullName = userProfile?.fullName ?? 'Worker';
    final phone = AuthHelpers.extractPhoneDisplay(
      userProfile?.phone ?? authState.phone ?? '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          strings.workerDashboardTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        actions: [
          const LanguageSelectorButton(),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: strings.notifications,
                onPressed: () => context.push('/notifications'),
              ),
              if (notifState.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notifState.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: strings.myProfileTooltip,
            onPressed: () => context.push('/worker/profile-placeholder'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: strings.signOut,
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(currentWorkerProfileProvider);
            ref.invalidate(publishedJobsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Worker Profile Status Card
                workerProfileAsync.when(
                  data: (profile) => _buildWorkerHeader(
                    context,
                    ref,
                    profile,
                    fallbackName: fullName,
                    fallbackPhone: phone,
                  ),
                  loading: () => AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const AppLoader(),
                          const SizedBox(width: 12),
                          Text(strings.checkingProfileStatus),
                        ],
                      ),
                    ),
                  ),
                  error: (e, st) => _buildWorkerHeader(
                    context,
                    ref,
                    null,
                    fallbackName: fullName,
                    fallbackPhone: phone,
                  ),
                ),
                AppSpacing.vMd,

                // Quick Bookings & History Navigation (Phase 7)
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: strings.upcomingBookings,
                        icon: Icons.event_available_rounded,
                        onPressed: () => context.push('/worker/bookings'),
                      ),
                    ),
                    AppSpacing.hSm,
                    Expanded(
                      child: AppSecondaryButton(
                        label: strings.workHistory,
                        icon: Icons.history_rounded,
                        onPressed: () => context.push('/worker/work-history'),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vLg,

                // Available Jobs Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        strings.availableJobsTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      label: Text(strings.filterAndSearch, style: const TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => context.push('/worker/jobs'),
                    ),
                  ],
                ),
                AppSpacing.vMd,

                // Jobs Feed
                jobsAsync.when(
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.work_off_outlined,
                        title: strings.noJobsAvailableTitle,
                        description: strings.noJobsAvailableSubtext,
                        actionLabel: strings.refresh,
                        onAction: () => ref.invalidate(publishedJobsProvider),
                      );
                    }

                    return Column(
                      children: jobs.map((job) => _buildJobCard(context, job, strings)).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: AppLoader(),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppCard(
                      borderColor: AppColors.error,
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                          AppSpacing.vSm,
                          Text(
                            'Error: $err',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          AppSpacing.vMd,
                          AppSecondaryButton(
                            label: strings.retry,
                            onPressed: () => ref.invalidate(publishedJobsProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppSpacing.vXl,

                // Footer
                Center(
                  child: Text(
                    strings.workerFooterNote,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerHeader(
    BuildContext context,
    WidgetRef ref,
    WorkerProfileModel? profile, {
    required String fallbackName,
    required String fallbackPhone,
  }) {
    final strings = ref.watch(stringsProvider);
    final name = (profile != null && profile.fullName.isNotEmpty) ? profile.fullName : fallbackName;
    final phone = (profile != null && profile.phone.isNotEmpty) ? profile.phone : fallbackPhone;
    final isSuspended = profile?.status == WorkerAccountStatus.suspended;
    final isPending = profile == null || profile.status == WorkerAccountStatus.pendingProfile;

    if (isSuspended) {
      return AppCard(
        backgroundColor: AppColors.error.withValues(alpha: 0.08),
        borderColor: AppColors.error,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                AppSpacing.hSm,
                Expanded(
                  child: Text(
                    strings.accountSuspendedTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vSm,
            Text(
              strings.accountSuspendedDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (isPending) {
      return AppCard(
        borderColor: AppColors.accent,
        backgroundColor: AppColors.accent.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    strings.helloName(name),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AppBadge.pending(label: strings.profileIncompleteBadge),
              ],
            ),
            AppSpacing.vSm,
            Text(
              strings.profileIncompleteDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            AppPrimaryButton(
              label: strings.completeProfileButton,
              icon: Icons.assignment_turned_in_rounded,
              onPressed: () => context.push('/worker/onboarding'),
            ),
          ],
        ),
      );
    }

    // Active Profile Card
    return AppCard(
      backgroundColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.helloName(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppBadge.success(label: strings.activeStatus),
            ],
          ),
          AppSpacing.vXs,
          Text(
            strings.verifiedMobileAndArea(phone, profile.locality),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (profile.skills.isNotEmpty) ...[
            AppSpacing.vMd,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.skills.take(4).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    skill.name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, PublishedJob job, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        onTap: () => context.push('/worker/jobs/${job.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Badge & Wage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.categoryName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '₹${job.wageAmount.toStringAsFixed(0)} ${job.wageRateUnitFor(strings.language)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            AppSpacing.vSm,

            // Job Title
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vXs,

            // Business & Location
            Row(
              children: [
                const Icon(
                  Icons.business_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                AppSpacing.hXs,
                Expanded(
                  child: Text(
                    '${job.businessName} • ${job.businessLocality}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vXs,

            // Date & Timing
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                AppSpacing.hXs,
                Expanded(
                  child: Text(
                    '${job.shiftDate} • ${job.startTime}${strings.toTime}${job.endTime}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),

            // Bottom Row: Spots Remaining & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.spotsRemainingCount(job.spotsRemaining, job.workersNeeded),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppBadge.success(label: strings.shiftIsOpen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
