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
import '../models/business_model.dart';
import '../models/owner_job_history_item.dart';
import '../presentation/owner_onboarding_notifier.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final businessAsync = ref.watch(currentOwnerBusinessProvider);
    final notifState = ref.watch(notificationCenterProvider);
    final strings = ref.watch(stringsProvider);

    final userProfile = authState.userProfile;
    final ownerName = userProfile?.fullName ?? 'Business Owner';
    final ownerPhone = AuthHelpers.extractPhoneDisplay(
      userProfile?.phone ?? authState.phone ?? '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.ownerDashboardTitle),
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
            icon: const Icon(Icons.storefront_outlined),
            tooltip: strings.businessProfileTooltip,
            onPressed: () => context.push('/owner/profile'),
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
      floatingActionButton: businessAsync.asData?.value?.verificationStatus.isVerified == true
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                strings.postJobButton,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              onPressed: () => context.push('/jobs/create'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(currentOwnerBusinessProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Business Status Banner
                businessAsync.when(
                  data: (biz) => _buildBusinessHeader(
                    context,
                    ref,
                    biz,
                    strings: strings,
                    ownerName: ownerName,
                    ownerPhone: ownerPhone,
                  ),
                  loading: () => AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const AppLoader(),
                          const SizedBox(width: 12),
                          Text(strings.checkingBusinessStatus),
                        ],
                      ),
                    ),
                  ),
                  error: (e, _) => _buildBusinessHeader(
                    context,
                    ref,
                    null,
                    strings: strings,
                    ownerName: ownerName,
                    ownerPhone: ownerPhone,
                  ),
                ),
                AppSpacing.vLg,

                // Quick Navigation Hub
                Row(
                  children: [
                    Expanded(
                      child: _buildNavCard(
                        icon: Icons.work_outline_rounded,
                        title: strings.myJobsTitle,
                        subtitle: strings.myJobsSubtitle,
                        onTap: () => context.push('/jobs/my-jobs'),
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: _buildNavCard(
                        icon: Icons.how_to_reg_rounded,
                        title: strings.attendanceHistoryScreenTitle,
                        subtitle: strings.language == AppLanguage.hindi ? 'शिफ्ट उपस्थिति' : 'Shift Attendance',
                        onTap: () => context.push('/owner/attendance-history'),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: _buildNavCard(
                        icon: Icons.store_rounded,
                        title: strings.businessProfileScreenTitle,
                        subtitle: strings.language == AppLanguage.hindi ? 'प्रोफाइल एवं दस्तावेज़' : 'Profile & Docs',
                        onTap: () => context.push('/owner/profile'),
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: _buildNavCard(
                        icon: Icons.history_rounded,
                        title: strings.ownerJobHistoryTitle,
                        subtitle: strings.ownerJobHistorySubtitle,
                        onTap: () => context.push('/owner/job-history'),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vLg,

                // Real Statistics Section
                businessAsync.when(
                  data: (biz) {
                    if (biz == null) return const SizedBox.shrink();
                    return _buildStatsSection(ref, biz.id, strings);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
                AppSpacing.vLg,

                // Recent Job History Preview Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.ownerJobHistoryTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/owner/job-history'),
                      child: Text(
                        strings.language == AppLanguage.hindi ? 'सभी देखें' : 'View All',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSm,

                // Recent Jobs Feed
                businessAsync.when(
                  data: (biz) {
                    if (biz == null) {
                      return EmptyStateWidget(
                        icon: Icons.storefront_outlined,
                        title: strings.noJobsPostedTitle,
                        description: strings.noJobsPostedDesc,
                        actionLabel: strings.language == AppLanguage.hindi ? 'व्यापार सेट करें' : 'Setup Business',
                        onAction: () => context.push('/owner/onboarding'),
                      );
                    }

                    return _buildRecentJobsFeed(ref, biz.id, strings);
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: AppLoader(message: strings.loadingHistory)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('${strings.errorPrefix}$e'),
                  ),
                ),
                AppSpacing.vXl,

                // Footer
                Center(
                  child: Text(
                    strings.language == AppLanguage.hindi
                        ? 'LaganStaff • गाजीपुर व्यापार एवं शादी नेटवर्क'
                        : 'LaganStaff • Ghazipur Business Network',
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

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          AppSpacing.vSm,
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHeader(
    BuildContext context,
    WidgetRef ref,
    BusinessModel? biz, {
    required AppStrings strings,
    required String ownerName,
    required String ownerPhone,
  }) {
    final isHindi = strings.language == AppLanguage.hindi;

    if (biz == null || biz.verificationStatus.isDraft) {
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
                    strings.helloName(ownerName),
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
              isHindi
                  ? 'गाजीपुर में शादी और आयोजनों के लिए अस्थायी कार्यकर्ता खोजने हेतु अपने व्यापार का पंजीकरण पूरा करें।'
                  : 'Complete your business profile to hire workforce for events and marriage halls in Ghazipur.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            AppPrimaryButton(
              label: strings.completeBusinessProfilePrompt,
              icon: Icons.add_business_rounded,
              onPressed: () => context.push('/owner/onboarding'),
            ),
          ],
        ),
      );
    }

    if (biz.verificationStatus.isPending) {
      return AppCard(
        borderColor: AppColors.warning,
        backgroundColor: AppColors.warning.withValues(alpha: 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    biz.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AppBadge.pending(label: strings.verificationPendingTitle),
              ],
            ),
            AppSpacing.vXs,
            Text(
              '${biz.categoryType.displayName} • ${biz.locality}, ${isHindi ? 'गाजीपुर' : 'Ghazipur'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            Text(
              isHindi
                  ? 'आपका व्यापार सत्यापन आवेदन LaganStaff एडमिन के पास जमा है। समीक्षा पूरी होते ही सत्यापन स्थिति अपडेट हो जाएगी।'
                  : 'Your business verification application is submitted to the admin. Status will update once reviewed.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        ),
      );
    }

    if (biz.verificationStatus.isUnderReview) {
      return AppCard(
        borderColor: AppColors.info,
        backgroundColor: AppColors.info.withValues(alpha: 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    biz.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AppBadge.neutral(label: strings.underReviewTitle),
              ],
            ),
            AppSpacing.vXs,
            Text(
              '${biz.categoryType.displayName} • ${biz.locality}, ${isHindi ? 'गाजीपुर' : 'Ghazipur'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            Text(
              isHindi
                  ? 'व्यवस्थापक द्वारा आपके दस्तावेजों और स्थान की पुष्टि की जा रही है।'
                  : 'Administrator is currently verifying your documents and location.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (biz.verificationStatus.isRejected) {
      return AppCard(
        borderColor: AppColors.error,
        backgroundColor: AppColors.error.withValues(alpha: 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    biz.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AppBadge.error(label: strings.tabRejected),
              ],
            ),
            AppSpacing.vSm,
            Text(
              '${isHindi ? 'अस्वीकृति का कारण:' : 'Rejection Reason:'} ${biz.rejectionReason ?? (isHindi ? 'विवरण अपूर्ण है।' : 'Details incomplete.')}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            AppSpacing.vSm,
            Text(
              isHindi
                  ? 'कृपया विवरण में सुधार करें और पुनः सत्यापन के लिए सबमिट करें।'
                  : 'Please update your details and resubmit for verification.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            AppPrimaryButton(
              label: isHindi ? 'सुधारें व पुनः सबमिट करें' : 'Edit & Resubmit',
              icon: Icons.edit_note_rounded,
              onPressed: () => context.push('/owner/onboarding'),
            ),
          ],
        ),
      );
    }

    if (biz.verificationStatus.isSuspended) {
      return AppCard(
        borderColor: AppColors.error,
        backgroundColor: AppColors.error.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                Text(
                  strings.suspendedBusinessTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isHindi
                  ? 'आपका व्यापार खाता व्यवस्थापक द्वारा निलंबित कर दिया गया है। अधिक जानकारी के लिए सपोर्ट से संपर्क करें।'
                  : 'Your business account has been suspended by the administrator. Contact support for help.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Verified Business Active Banner
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
                  biz.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppBadge.success(label: strings.verifiedBusinessTitle),
            ],
          ),
          AppSpacing.vXs,
          Text(
            '${biz.categoryType.displayName} • ${biz.locality}, ${isHindi ? 'गाजीपुर' : 'Ghazipur'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSpacing.vSm,
          Text(
            '${isHindi ? 'मालिक:' : 'Owner:'} $ownerName • ${isHindi ? 'फोन:' : 'Phone:'} +91 $ownerPhone',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          AppSpacing.vMd,
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              strings.postJobButton,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            onPressed: () => context.push('/jobs/create'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref, String businessId, AppStrings strings) {
    final statsAsync = ref.watch(ownerBusinessStatsProvider(businessId));
    final isHindi = strings.language == AppLanguage.hindi;

    return statsAsync.when(
      data: (stats) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: isHindi ? 'कुल कार्य' : 'Total Jobs',
                value: '${stats['total_jobs'] ?? 0}',
                color: AppColors.primary,
              ),
            ),
            AppSpacing.hSm,
            Expanded(
              child: _buildStatCard(
                label: isHindi ? 'सक्रिय' : 'Active',
                value: '${stats['active_jobs'] ?? 0}',
                color: AppColors.success,
              ),
            ),
            AppSpacing.hSm,
            Expanded(
              child: _buildStatCard(
                label: isHindi ? 'पूर्ण' : 'Completed',
                value: '${stats['completed_jobs'] ?? 0}',
                color: AppColors.info,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          AppSpacing.vXs,
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJobsFeed(WidgetRef ref, String businessId, AppStrings strings) {
    final historyAsync = ref.watch(ownerJobHistoryProvider(
      (businessId: businessId, status: null),
    ));

    return historyAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.work_outline_rounded,
            title: strings.noJobsPostedTitle,
            description: strings.noJobsPostedDesc,
          );
        }

        return Column(
          children: jobs.take(3).map((job) => _buildJobCard(job, strings)).toList(),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: AppLoader(message: strings.loadingHistory)),
      ),
      error: (e, _) => Text('${strings.errorPrefix}$e'),
    );
  }

  Widget _buildJobCard(OwnerJobHistoryItem job, AppStrings strings) {
    final isHindi = strings.language == AppLanguage.hindi;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job.categoryName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '₹${job.wageAmount.toStringAsFixed(0)} ${isHindi ? job.wageRateUnit : '/ Shift'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            AppSpacing.vXs,
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vXs,
            Text(
              '${job.shiftDate} • ${job.startTime}${strings.toTime}${job.endTime} • ${job.reportingAddress}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${job.workersConfirmed}/${job.workersNeeded} ${isHindi ? 'कार्यकर्ता' : 'workers'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                AppBadge.neutral(label: job.statusDisplayNameFor(strings.language)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
