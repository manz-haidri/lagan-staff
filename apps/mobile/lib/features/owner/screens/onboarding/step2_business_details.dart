import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/owner_onboarding_notifier.dart';

class Step2BusinessDetails extends StatefulWidget {
  final OwnerOnboardingState state;
  final OwnerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step2BusinessDetails({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  State<Step2BusinessDetails> createState() => _Step2BusinessDetailsState();
}

class _Step2BusinessDetailsState extends State<Step2BusinessDetails> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descController;
  late final TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.businessName);
    _contactPersonController =
        TextEditingController(text: widget.state.contactPerson);
    _phoneController = TextEditingController(
      text: widget.state.contactPhone.isNotEmpty
          ? widget.state.contactPhone
          : widget.state.verifiedMobile,
    );
    _descController = TextEditingController(text: widget.state.description);
    _gstController = TextEditingController(text: widget.state.gstOrTradeId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _syncState() {
    widget.notifier.updateDetails(
      name: _nameController.text,
      contactPerson: _contactPersonController.text,
      contactPhone: _phoneController.text,
      description: _descController.text,
      gstOrTradeId: _gstController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.businessDetailsTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.businessDetailsSubtitle,
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
                      strings.verifiedPhoneCardTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.vXs,
                    Text(
                      widget.state.verifiedMobile.isNotEmpty
                          ? '+91 ${widget.state.verifiedMobile}'
                          : '+91 XXXXXXXXXX',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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

        // Business Name
        AppTextField(
          label: strings.businessNameLabel,
          hintText: strings.businessNameHint,
          controller: _nameController,
          prefixIcon: const Icon(Icons.storefront_rounded),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vMd,

        // Contact Person / Owner Name
        AppTextField(
          label: strings.contactPersonLabel,
          hintText: strings.contactPersonHint,
          controller: _contactPersonController,
          prefixIcon: const Icon(Icons.person_outline_rounded),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vMd,

        // Business Contact Phone
        AppTextField(
          label: strings.businessPhoneLabel,
          hintText: strings.mobileNumberHint,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vMd,

        // Business Description
        AppTextField(
          label: strings.businessDescriptionLabel,
          hintText: strings.businessDescriptionHint,
          controller: _descController,
          maxLines: 3,
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vMd,

        // GST / Trade ID (Optional)
        AppTextField(
          label: strings.gstNumberLabel,
          hintText: '09AAAAA0000A1Z5',
          controller: _gstController,
          prefixIcon: const Icon(Icons.receipt_long_outlined),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vLg,

        // Save Draft Button
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 170,
            child: AppSecondaryButton(
              label: strings.saveDraftButton,
              icon: Icons.save_outlined,
              onPressed: widget.state.isSavingDraft ? null : () async {
                _syncState();
                final messenger = ScaffoldMessenger.of(context);
                final saved = await widget.notifier.saveDraft();
                if (saved) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(strings.draftSavedSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
