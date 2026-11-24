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
import '../models/business_document_model.dart';
import '../models/business_model.dart';
import '../presentation/owner_onboarding_notifier.dart';

class OwnerProfilePlaceholderScreen extends ConsumerWidget {
  const OwnerProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final businessAsync = ref.watch(currentOwnerBusinessProvider);
    final strings = ref.watch(stringsProvider);

    final userProfile = authState.userProfile;
    final ownerName = userProfile?.fullName ?? strings.ownerRole;
    final ownerPhone = AuthHelpers.extractPhoneDisplay(
      userProfile?.phone ?? authState.phone ?? '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.businessProfileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: strings.editBusinessProfile,
            onPressed: () async {
              await context.push('/owner/onboarding');
              ref.invalidate(currentOwnerBusinessProvider);
            },
          ),
          const LanguageSelectorButton(),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: businessAsync.when(
            data: (biz) => _buildProfileContent(
              context,
              ref,
              biz,
              strings,
              ownerName: ownerName,
              ownerPhone: ownerPhone,
            ),
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: AppLoader(message: strings.loading),
              ),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    BusinessModel? biz,
    AppStrings strings, {
    required String ownerName,
    required String ownerPhone,
  }) {
    if (biz == null) {
      return Column(
        children: [
          const Icon(Icons.storefront_outlined, size: 64, color: AppColors.textMuted),
          AppSpacing.vMd,
          Text(
            strings.businessProfileIncomplete,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          AppSpacing.vSm,
          Text(
            strings.businessProfileIncompleteDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,
          AppPrimaryButton(
            label: strings.setupBusinessButton,
            onPressed: () => context.push('/owner/onboarding'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Avatar & Title
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.storefront_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),
        AppSpacing.vMd,
        Text(
          biz.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.vXs,
        Text(
          biz.categoryType.displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        AppSpacing.vSm,

        // Status Badge
        Center(
          child: _buildStatusBadge(biz, strings),
        ),
        AppSpacing.vLg,

        // Rejection banner if rejected
        if (biz.verificationStatus.isRejected) ...[
          AppCard(
            borderColor: AppColors.error,
            backgroundColor: AppColors.error.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.rejectionReasonLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                AppSpacing.vXs,
                Text(
                  biz.rejectionReason ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                AppSpacing.vMd,
                AppPrimaryButton(
                  label: strings.editAndResubmit,
                  icon: Icons.edit_note_rounded,
                  onPressed: () => context.push('/owner/onboarding'),
                ),
              ],
            ),
          ),
          AppSpacing.vLg,
        ],

        // Details Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow(
                Icons.person_outline_rounded,
                strings.ownerOrAuthorizedPerson,
                biz.contactPerson ?? ownerName,
              ),
              const Divider(height: 24),
              _buildRow(
                Icons.phone_outlined,
                strings.verifiedMobileNumber,
                '+91 $ownerPhone',
              ),
              const Divider(height: 24),
              _buildRow(
                Icons.call_outlined,
                strings.businessContactNumber,
                biz.contactPhone,
              ),
              const Divider(height: 24),
              _buildRow(
                Icons.place_outlined,
                strings.locationAndArea,
                '${biz.locality}, Ghazipur (${strings.pincode}: ${biz.pincode})',
              ),
              if (biz.address?.isNotEmpty == true) ...[
                const Divider(height: 24),
                _buildRow(
                  Icons.home_work_outlined,
                  strings.fullAddressLabel,
                  biz.address!,
                ),
              ],
              if (biz.description?.isNotEmpty == true) ...[
                const Divider(height: 24),
                _buildRow(
                  Icons.info_outline_rounded,
                  strings.descriptionLabel,
                  biz.description!,
                ),
              ],
              if (biz.gstOrTradeId?.isNotEmpty == true) ...[
                const Divider(height: 24),
                _buildRow(
                  Icons.receipt_long_outlined,
                  'GST / Trade ID',
                  biz.gstOrTradeId!,
                ),
              ],
            ],
          ),
        ),
        AppSpacing.vLg,

        // Attached Documents Card
        if (biz.documents.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.attachedDocumentsCount(biz.documents.length),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.vSm,
                ...biz.documents.map((d) {
                  final doc = BusinessDocumentModel.fromJson(d as Map<String, dynamic>);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${doc.typeDisplayName} (${doc.fileSizeFormatted})',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          AppSpacing.vLg,
        ],

        // Action Buttons
        if (!biz.verificationStatus.isSuspended) ...[
          AppPrimaryButton(
            label: strings.editBusinessProfile,
            icon: Icons.edit_outlined,
            onPressed: () async {
              await context.push('/owner/onboarding');
              ref.invalidate(currentOwnerBusinessProvider);
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

  Widget _buildStatusBadge(BusinessModel biz, AppStrings strings) {
    final label = biz.verificationStatus.displayNameFor(strings.language);
    switch (biz.verificationStatus) {
      case BusinessVerificationStatus.verified:
        return AppBadge.success(label: label);
      case BusinessVerificationStatus.rejected:
      case BusinessVerificationStatus.suspended:
        return AppBadge.error(label: label);
      case BusinessVerificationStatus.underReview:
        return AppBadge.neutral(label: label);
      case BusinessVerificationStatus.pending:
      case BusinessVerificationStatus.draft:
        return AppBadge.pending(label: label);
    }
  }

  Widget _buildRow(IconData icon, String label, String value) {
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
              const SizedBox(height: 2),
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
