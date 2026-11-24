import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../models/business_model.dart';
import '../../presentation/owner_onboarding_notifier.dart';

class Step1CategorySelection extends StatelessWidget {
  final OwnerOnboardingState state;
  final OwnerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step1CategorySelection({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isHindi = strings.language == AppLanguage.hindi;

    final categories = [
      (
        BusinessCategoryType.marriageHall,
        isHindi ? 'मैरिज लॉन / हॉल' : 'Marriage Lawn / Hall',
        isHindi
            ? 'शादी लॉन, बारात घर, बैंक्वेट हॉल'
            : 'Marriage Lawn, Banquet Hall, Barat Ghar',
        Icons.roofing_rounded,
      ),
      (
        BusinessCategoryType.cateringAgency,
        isHindi ? 'कैटरिंग एजेंसी' : 'Catering Agency',
        isHindi
            ? 'शादी, पार्टी, हलवाई व खाना परोसने वाली एजेंसी'
            : 'Wedding, Party, Cooking & Catering Services',
        Icons.restaurant_rounded,
      ),
      (
        BusinessCategoryType.tentHouse,
        isHindi ? 'टेंट हाउस' : 'Tent House',
        isHindi
            ? 'शामियाना, कुर्सी, टेबल, पर्दा व स्टेज सामग्री'
            : 'Tent, Chairs, Tables, Curtains & Stage Equipment',
        Icons.holiday_village_rounded,
      ),
      (
        BusinessCategoryType.eventOrganizer,
        isHindi ? 'इवेंट ऑर्गनाइज़र' : 'Event Organizer',
        isHindi
            ? 'सम्पूर्ण शादी व सांस्कृतिक कार्यक्रम प्रबंधक'
            : 'Complete Wedding & Event Management',
        Icons.celebration_rounded,
      ),
      (
        BusinessCategoryType.djSound,
        isHindi ? 'डीजे / साउंड ऑपरेटर' : 'DJ & Sound Operator',
        isHindi
            ? 'साउंड सिस्टम, म्यूजिक, लाइट व जनरेटर'
            : 'Sound System, Music, Lighting & Generator',
        Icons.speaker_group_rounded,
      ),
      (
        BusinessCategoryType.other,
        isHindi ? 'अन्य व्यापार' : 'Other Business',
        isHindi
            ? 'अन्य शादी व कार्यक्रम संबंधित प्रतिष्ठान'
            : 'Other Event & Hospitality Businesses',
        Icons.business_center_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.ownerCategoryTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.ownerCategorySubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        ...categories.map((item) {
          final type = item.$1;
          final title = item.$2;
          final subtitle = item.$3;
          final icon = item.$4;
          final isSelected = state.categoryType == type;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => notifier.setCategory(type),
              borderColor: isSelected ? AppColors.primary : AppColors.border,
              backgroundColor: isSelected
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : AppColors.surface,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.vXs,
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
