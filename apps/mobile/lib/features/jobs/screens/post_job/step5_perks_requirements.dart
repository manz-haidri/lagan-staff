import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/job_form_notifier.dart';

class Step5PerksRequirements extends ConsumerStatefulWidget {
  const Step5PerksRequirements({super.key});

  @override
  ConsumerState<Step5PerksRequirements> createState() => _Step5PerksRequirementsState();
}

class _Step5PerksRequirementsState extends ConsumerState<Step5PerksRequirements> {
  late final TextEditingController _foodDetailsController;
  late final TextEditingController _transportDetailsController;
  late final TextEditingController _specialInstructionsController;

  @override
  void initState() {
    super.initState();
    final form = ref.read(jobFormNotifierProvider);
    _foodDetailsController = TextEditingController(text: form.foodDetails);
    _transportDetailsController = TextEditingController(text: form.transportDetails);
    _specialInstructionsController = TextEditingController(text: form.specialInstructions);
  }

  @override
  void dispose() {
    _foodDetailsController.dispose();
    _transportDetailsController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(jobFormNotifierProvider);
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);
    final strings = ref.watch(stringsProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.perksRequirementsTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vXs,
          Text(
            strings.perksRequirementsSubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,

          // Food Perk Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
                  title: Text(
                    strings.foodProvidedTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    strings.foodProvidedSubtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: formState.foodProvided,
                  activeThumbColor: AppColors.primary,
                  onChanged: formNotifier.updateFoodProvided,
                ),
                if (formState.foodProvided) ...[
                  AppSpacing.vSm,
                  AppTextField(
                    label: strings.foodDetailsFieldLabel,
                    hintText: strings.foodDetailsFieldHint,
                    controller: _foodDetailsController,
                    onChanged: formNotifier.updateFoodDetails,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.vMd,

          // Transportation Perk Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.directions_bus_rounded, color: AppColors.primary),
                  title: Text(
                    strings.transportProvidedTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    strings.transportProvidedSubtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: formState.transportProvided,
                  activeThumbColor: AppColors.primary,
                  onChanged: formNotifier.updateTransportProvided,
                ),
                if (formState.transportProvided) ...[
                  AppSpacing.vSm,
                  AppTextField(
                    label: strings.transportDetailsFieldLabel,
                    hintText: strings.transportDetailsFieldHint,
                    controller: _transportDetailsController,
                    onChanged: formNotifier.updateTransportDetails,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.vLg,

          // Special Instructions / Dress Code
          AppTextField(
            label: strings.specialRequirementsFieldLabel,
            hintText: strings.specialRequirementsFieldHint,
            controller: _specialInstructionsController,
            maxLines: 3,
            prefixIcon: const Icon(Icons.info_outline_rounded, size: 20),
            onChanged: formNotifier.updateSpecialInstructions,
          ),
        ],
      ),
    );
  }
}
