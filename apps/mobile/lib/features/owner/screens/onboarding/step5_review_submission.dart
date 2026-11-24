import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../models/business_model.dart';
import '../../presentation/owner_onboarding_notifier.dart';

class Step5ReviewSubmission extends StatefulWidget {
  final OwnerOnboardingState state;
  final OwnerOnboardingNotifier notifier;
  final AppStrings strings;
  final VoidCallback onSubmit;

  const Step5ReviewSubmission({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
    required this.onSubmit,
  });

  @override
  State<Step5ReviewSubmission> createState() => _Step5ReviewSubmissionState();
}

class _Step5ReviewSubmissionState extends State<Step5ReviewSubmission> {
  bool _isDeclared = true;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final isHindi = strings.language == AppLanguage.hindi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.reviewSubmissionTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.reviewSubmissionSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        // Verification Process Notice Card
        AppCard(
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'प्रशासकीय सत्यापन प्रक्रिया' : 'Admin Verification Process',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      strings.applicationSubmittedDesc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vLg,

        // Summary Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Name & Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.state.businessName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.vXs,
                        Text(
                          widget.state.categoryType.displayNameFor(strings.language),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppBadge.pending(
                    label: BusinessVerificationStatus.pending.displayNameFor(strings.language),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Owner & Contact
              _buildReviewRow(
                strings.contactPersonLabel,
                widget.state.contactPerson.isNotEmpty
                    ? widget.state.contactPerson
                    : (isHindi ? 'दर्ज नहीं' : 'Not Provided'),
              ),
              AppSpacing.vSm,
              _buildReviewRow(
                strings.verifiedPhoneCardTitle,
                '+91 ${widget.state.verifiedMobile}',
              ),
              AppSpacing.vSm,
              _buildReviewRow(
                strings.businessPhoneLabel,
                widget.state.contactPhone.isNotEmpty
                    ? widget.state.contactPhone
                    : '+91 ${widget.state.verifiedMobile}',
              ),
              const Divider(height: 24),

              // Location
              _buildReviewRow(
                strings.businessLocationTitle,
                '${widget.state.locality}, ${strings.ghazipurCity} (${strings.pincodeLabel.replaceAll('*', '')}: ${widget.state.pincode})',
              ),
              if (widget.state.address.isNotEmpty) ...[
                AppSpacing.vSm,
                _buildReviewRow(
                  strings.venueAddressSummaryLabel,
                  widget.state.address,
                ),
              ],
              const Divider(height: 24),

              // Documents & Proofs
              _buildReviewRow(
                strings.documentUploadTitle,
                widget.state.uploadedDocuments.isEmpty
                    ? (isHindi ? 'कोई नहीं (वैकल्पिक)' : 'None (Optional)')
                    : (isHindi
                        ? '${widget.state.uploadedDocuments.length} दस्तावेज़ संलग्न'
                        : '${widget.state.uploadedDocuments.length} documents attached'),
              ),
              if (widget.state.gstOrTradeId?.isNotEmpty == true) ...[
                AppSpacing.vSm,
                _buildReviewRow(
                  strings.gstNumberLabel,
                  widget.state.gstOrTradeId!,
                ),
              ],
            ],
          ),
        ),
        AppSpacing.vLg,

        // Declaration Checkbox
        InkWell(
          onTap: () {
            setState(() {
              _isDeclared = !_isDeclared;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _isDeclared,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isDeclared = val ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    strings.ownerDeclaration,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.vLg,

        // Submit Button
        AppPrimaryButton(
          label: strings.submitOwnerApplication,
          icon: Icons.send_rounded,
          isLoading: widget.state.isSubmitting,
          onPressed: _isDeclared && !widget.state.isSubmitting
              ? widget.onSubmit
              : null,
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
