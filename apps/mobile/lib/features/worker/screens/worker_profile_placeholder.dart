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
import '../../auth/presentation/auth_notifier.dart';
import '../models/worker_profile.dart';
import '../presentation/worker_onboarding_notifier.dart';

class WorkerProfilePlaceholderScreen extends ConsumerWidget {
  const WorkerProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final authState = ref.watch(authNotifierProvider);
    final workerProfileAsync = ref.watch(currentWorkerProfileProvider);

    final userProfile = authState.userProfile;
    final fallbackName = userProfile?.fullName ?? strings.workerFallbackName;
    final fallbackPhone = AuthHelpers.extractPhoneDisplay(
      userProfile?.phone ?? authState.phone ?? '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.workerProfileTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: strings.editProfile,
            onPressed: () async {
              await context.push('/worker/onboarding');
              ref.invalidate(currentWorkerProfileProvider);
            },
          ),
          const LanguageSelectorButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: workerProfileAsync.when(
            data: (profile) => _buildProfileBody(
              context,
              ref,
              profile,
              strings: strings,
              fallbackName: fallbackName,
              fallbackPhone: fallbackPhone,
            ),
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: AppLoader(message: strings.loadingProfile),
              ),
            ),
            error: (err, _) => _buildProfileBody(
              context,
              ref,
              null,
              strings: strings,
              fallbackName: fallbackName,
              fallbackPhone: fallbackPhone,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    WidgetRef ref,
    WorkerProfileModel? profile, {
    required AppStrings strings,
    required String fallbackName,
    required String fallbackPhone,
  }) {
    final name = (profile?.fullName.isNotEmpty == true) ? profile!.fullName : fallbackName;
    final phone = (profile?.phone.isNotEmpty == true) ? profile!.phone : fallbackPhone;
    final status = profile?.status ?? WorkerAccountStatus.pendingProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Avatar + Status Badge
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              if (profile?.isSelfieVerified == true)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        AppSpacing.vMd,
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.vXs,
        Text(
          '+91 $phone',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vSm,
        Center(
          child: status.isActive
              ? AppBadge.success(label: strings.activeStatus)
              : (status.isSuspended
                  ? AppBadge.error(label: strings.accountSuspendedTitle)
                  : AppBadge.pending(label: strings.profileIncompleteBadge)),
        ),
        AppSpacing.vLg,

        // Details Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                Icons.location_on_outlined,
                strings.areaLocality,
                profile?.locality.isNotEmpty == true
                    ? '${profile!.locality}, ${strings.ghazipurCity}'
                    : strings.notEntered,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.camera_front_outlined,
                strings.selfieStatusLabel,
                profile?.isSelfieVerified == true
                    ? strings.selfieVerifiedAndUploaded
                    : strings.selfiePendingUpload,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.badge_outlined,
                strings.accountTypeTitle,
                '${strings.workerRoleTitle} • ${strings.ghazipurWorkerNetwork}',
              ),
            ],
          ),
        ),
        AppSpacing.vLg,

        // Skills List Card
        if (profile != null && profile.skills.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.skillsSection,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.vSm,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.skills.map((skill) {
                    return Chip(
                      label: Text(skill.name),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          AppSpacing.vLg,
        ],

        // Action Buttons
        if (status.isPending) ...[
          AppPrimaryButton(
            label: strings.completeProfileButton,
            icon: Icons.edit_note_rounded,
            onPressed: () async {
              await context.push('/worker/onboarding');
              ref.invalidate(currentWorkerProfileProvider);
            },
          ),
          AppSpacing.vMd,
        ] else ...[
          AppPrimaryButton(
            label: strings.editProfile,
            icon: Icons.edit_outlined,
            onPressed: () async {
              await context.push('/worker/onboarding');
              ref.invalidate(currentWorkerProfileProvider);
            },
          ),
          AppSpacing.vMd,
        ],

        AppSecondaryButton(
          label: strings.signOut,
          icon: Icons.logout_rounded,
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        AppSpacing.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppSpacing.vXs,
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
