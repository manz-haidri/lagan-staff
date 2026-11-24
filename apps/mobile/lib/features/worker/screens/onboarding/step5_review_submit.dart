import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../presentation/worker_onboarding_notifier.dart';

class Step5ReviewSubmit extends StatefulWidget {
  final WorkerOnboardingState state;
  final WorkerOnboardingNotifier notifier;
  final AppStrings strings;
  final VoidCallback onSubmit;

  const Step5ReviewSubmit({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
    required this.onSubmit,
  });

  @override
  State<Step5ReviewSubmit> createState() => _Step5ReviewSubmitState();
}

class _Step5ReviewSubmitState extends State<Step5ReviewSubmit> {
  bool _isDeclared = true;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    // Collect all selected skill names with localized display
    final selectedSkills = widget.state.categories
        .expand((c) => c.skills)
        .where((s) => widget.state.selectedSkillIds.contains(s.id))
        .map((s) => strings.localizedName(s.name))
        .toList();

    if (widget.state.customSkillName.trim().isNotEmpty) {
      selectedSkills.add('${strings.otherSkillLabel}: ${widget.state.customSkillName.trim()}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          strings.reviewDetailsTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.reviewDetailsSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        // Instant Activation Notice Card
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
                  Icons.bolt_rounded,
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
                      strings.instantActivationTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      strings.instantActivationDesc,
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
              // Top Row: Selfie Thumbnail + Name & Phone
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      image: widget.state.selfieBytes != null
                          ? DecorationImage(
                              image: MemoryImage(widget.state.selfieBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.state.selfieBytes == null
                        ? const Icon(Icons.person, color: AppColors.textMuted)
                        : null,
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.state.fullName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.vXs,
                        Text(
                          '${strings.verifiedMobileNumber}: +91 ${widget.state.phone}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppBadge.success(label: strings.statusVerified),
                ],
              ),
              const Divider(height: 28),

              // Location Summary
              Text(
                '${strings.locationAndArea}:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              AppSpacing.vXs,
              Text(
                '${widget.state.locality}, ${strings.ghazipurDistrict} (${strings.pincodeLabel}: ${widget.state.pincode})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Divider(height: 28),

              // Skills Summary
              Text(
                '${strings.requiredSkillsLabel}:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              AppSpacing.vSm,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedSkills.map((name) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                    strings.declarationText,
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
          label: strings.submitWorkerProfile,
          icon: Icons.check_circle_outline_rounded,
          isLoading: widget.state.isSubmitting,
          onPressed: _isDeclared && !widget.state.isSubmitting
              ? widget.onSubmit
              : null,
        ),
      ],
    );
  }
}
