import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/worker_onboarding_notifier.dart';

class Step1PersonalDetails extends StatefulWidget {
  final WorkerOnboardingState state;
  final WorkerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step1PersonalDetails({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  State<Step1PersonalDetails> createState() => _Step1PersonalDetailsState();
}

class _Step1PersonalDetailsState extends State<Step1PersonalDetails> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.fullName);
  }

  @override
  void didUpdateWidget(covariant Step1PersonalDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.fullName != widget.state.fullName &&
        _nameController.text != widget.state.fullName) {
      _nameController.text = widget.state.fullName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          widget.strings.personalDetailsTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          widget.strings.personalDetailsSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        // Verified Mobile Card (Read-only)
        AppCard(
          backgroundColor: AppColors.surfaceMuted,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.strings.verifiedPhoneCardTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.vXs,
                    Text(
                      widget.state.phone.isNotEmpty
                          ? '+91 ${widget.state.phone}'
                          : '+91 XXXXXXXXXX',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
        AppSpacing.vLg,

        // Full Name Field
        AppTextField(
          label: widget.strings.workerFullNameLabel,
          hintText: widget.strings.workerFullNameHint,
          controller: _nameController,
          prefixIcon: const Icon(Icons.person_outline_rounded),
          onChanged: (val) => widget.notifier.updateFullName(val),
        ),
        AppSpacing.vSm,
        Text(
          widget.strings.workerFullNameNote,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
