import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/job_form_notifier.dart';

class Step3Payment extends ConsumerStatefulWidget {
  const Step3Payment({super.key});

  @override
  ConsumerState<Step3Payment> createState() => _Step3PaymentState();
}

class _Step3PaymentState extends ConsumerState<Step3Payment> {
  late final TextEditingController _wageController;
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    final form = ref.read(jobFormNotifierProvider);
    _wageController = TextEditingController(
      text: form.wageAmount > 0 ? form.wageAmount.toStringAsFixed(0) : '',
    );
    _instructionsController = TextEditingController(text: form.paymentInstructions);
  }

  @override
  void dispose() {
    _wageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(jobFormNotifierProvider);
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);
    final strings = ref.watch(stringsProvider);
    final isHindi = strings.language == AppLanguage.hindi;

    final presets = [450.0, 500.0, 600.0, 700.0, 800.0, 1000.0];

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.paymentTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vXs,
          Text(
            strings.paymentSubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,

          // Payment Card with Indian Rupee formatting
          AppCard(
            backgroundColor: AppColors.success.withValues(alpha: 0.05),
            borderColor: AppColors.success.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.wagePerWorkerLabel,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                AppSpacing.vSm,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '₹',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.success),
                    ),
                    AppSpacing.hSm,
                    Text(
                      formState.wageAmount.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    AppSpacing.hSm,
                    Text(
                      strings.perShiftSuffix,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                AppSpacing.vMd,

                // Quick Presets
                Text(
                  isHindi ? 'सामान्य दरें (त्वरित चयन):' : 'Popular Rates (Quick Select):',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                AppSpacing.vXs,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets.map((amount) {
                    final isSelected = formState.wageAmount == amount;
                    return ActionChip(
                      label: Text('₹${amount.toStringAsFixed(0)}'),
                      backgroundColor: isSelected ? AppColors.success : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      onPressed: () {
                        formNotifier.updateWage(amount);
                        _wageController.text = amount.toStringAsFixed(0);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          AppSpacing.vLg,

          // Manual Input for custom wage
          AppTextField(
            label: strings.customWageLabel,
            hintText: strings.customWageHint,
            controller: _wageController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed > 0) {
                formNotifier.updateWage(parsed);
              }
            },
          ),
          AppSpacing.vLg,

          // Payment Instructions
          AppTextField(
            label: strings.paymentNotesLabel,
            hintText: strings.paymentNotesHint,
            controller: _instructionsController,
            maxLines: 2,
            onChanged: formNotifier.updatePaymentInstructions,
          ),
        ],
      ),
    );
  }
}
