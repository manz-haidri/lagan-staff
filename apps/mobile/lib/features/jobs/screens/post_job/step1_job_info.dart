import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_loaders.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/job_form_notifier.dart';

class Step1JobInfo extends ConsumerStatefulWidget {
  const Step1JobInfo({super.key});

  @override
  ConsumerState<Step1JobInfo> createState() => _Step1JobInfoState();
}

class _Step1JobInfoState extends ConsumerState<Step1JobInfo> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final form = ref.read(jobFormNotifierProvider);
    _titleController = TextEditingController(text: form.title);
    _descController = TextEditingController(text: form.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(jobFormNotifierProvider);
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);
    final skillsAsync = ref.watch(skillsProvider(formState.categoryId));
    final strings = ref.watch(stringsProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.jobInfoTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vXs,
          Text(
            strings.jobInfoSubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,

          // Job Title
          AppTextField(
            label: strings.jobTitleFieldLabel,
            hintText: strings.jobTitleFieldHint,
            controller: _titleController,
            onChanged: formNotifier.updateTitle,
          ),
          AppSpacing.vMd,

          // Category Selector
          Text(
            strings.workerCategoryLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          AppSpacing.vXs,
          categoriesAsync.when(
            data: (categories) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = formState.categoryId == cat.id;
                  return ChoiceChip(
                    label: Text(strings.localizedName(cat.name)),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        formNotifier.updateCategory(cat.id);
                      }
                    },
                  );
                }).toList(),
              );
            },
            loading: () => AppLoader(message: strings.loadingCategories),
            error: (e, _) => Text('${strings.categoryLoadError}$e'),
          ),
          AppSpacing.vLg,

          // Skills Selector
          if (formState.categoryId != null) ...[
            Text(
              strings.requiredSkillsLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            AppSpacing.vXs,
            skillsAsync.when(
              data: (skills) {
                if (skills.isEmpty) {
                  return Text(
                    strings.noSpecificSkills,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((skill) {
                    final isSelected = formState.skillIds.contains(skill.id);
                    return FilterChip(
                      label: Text(strings.localizedName(skill.name)),
                      selected: isSelected,
                      selectedColor: AppColors.success.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.success,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.success : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (_) => formNotifier.toggleSkill(skill.id),
                    );
                  }).toList(),
                );
              },
              loading: () => const AppLoader(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            AppSpacing.vLg,
          ],

          // Number of Workers Needed
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.workersNeededLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      strings.workersNeededSubtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: formState.workersNeeded > 1 ? AppColors.primary : AppColors.border,
                      onPressed: formState.workersNeeded > 1
                          ? () => formNotifier.updateWorkersNeeded(formState.workersNeeded - 1)
                          : null,
                    ),
                    Text(
                      '${formState.workersNeeded}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.primary,
                      onPressed: () => formNotifier.updateWorkersNeeded(formState.workersNeeded + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vLg,

          // Description
          AppTextField(
            label: strings.jobDescriptionFieldLabel,
            hintText: strings.jobDescriptionFieldHint,
            controller: _descController,
            maxLines: 3,
            onChanged: formNotifier.updateDescription,
          ),
        ],
      ),
    );
  }
}
