import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_loaders.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/worker_onboarding_notifier.dart';

class Step2SkillsSelection extends StatefulWidget {
  final WorkerOnboardingState state;
  final WorkerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step2SkillsSelection({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  State<Step2SkillsSelection> createState() => _Step2SkillsSelectionState();
}

class _Step2SkillsSelectionState extends State<Step2SkillsSelection> {
  late final TextEditingController _customSkillController;

  @override
  void initState() {
    super.initState();
    _customSkillController =
        TextEditingController(text: widget.state.customSkillName);
  }

  @override
  void dispose() {
    _customSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    if (widget.state.isLoadingCategories) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AppLoader(message: strings.loadingSkills),
        ),
      );
    }

    final hasOtherSelected = widget.state.categories
        .where((c) => c.slug == 'other')
        .expand((c) => c.skills)
        .any((s) => widget.state.selectedSkillIds.contains(s.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          strings.selectSkillsTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.selectSkillsSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vMd,

        // Selection Counter Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.selectedSkillsCount(widget.state.selectedSkillIds.length),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.state.selectedSkillIds.isEmpty
                    ? AppColors.error
                    : AppColors.primary,
              ),
            ),
            if (widget.state.selectedSkillIds.isEmpty)
              Text(
                strings.atLeastOneSkillRequired,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        AppSpacing.vMd,

        // Categories & Skills List
        ...widget.state.categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category.slug),
                        size: 20,
                        color: AppColors.primary,
                      ),
                      AppSpacing.hSm,
                      Expanded(
                        child: Text(
                          strings.localizedName(category.name),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.skills.map((skill) {
                      final isSelected =
                          widget.state.selectedSkillIds.contains(skill.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(strings.localizedName(skill.name)),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceMuted,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        onSelected: isSelected || widget.state.selectedSkillIds.length < WorkerOnboardingState.maxSkills
                            ? (_) => widget.notifier.toggleSkill(skill.id)
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),

        // Custom skill field if 'Other' is selected
        if (hasOtherSelected) ...[
          AppSpacing.vSm,
          AppTextField(
            label: strings.otherSkillLabel,
            hintText: strings.otherSkillHint,
            controller: _customSkillController,
            prefixIcon: const Icon(Icons.handyman_outlined),
            onChanged: (val) => widget.notifier.updateCustomSkillName(val),
          ),
          AppSpacing.vMd,
        ],
      ],
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'waiters':
        return Icons.room_service_rounded;
      case 'cleaners':
        return Icons.cleaning_services_rounded;
      case 'halwai_helpers':
        return Icons.soup_kitchen_rounded;
      case 'loaders':
        return Icons.local_shipping_rounded;
      case 'event_helpers':
        return Icons.celebration_rounded;
      case 'other':
      default:
        return Icons.construction_rounded;
    }
  }
}
