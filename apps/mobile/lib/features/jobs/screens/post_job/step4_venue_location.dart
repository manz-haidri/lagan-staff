import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/job_form_notifier.dart';

class Step4VenueLocation extends ConsumerStatefulWidget {
  const Step4VenueLocation({super.key});

  @override
  ConsumerState<Step4VenueLocation> createState() => _Step4VenueLocationState();
}

class _Step4VenueLocationState extends ConsumerState<Step4VenueLocation> {
  late final TextEditingController _venueController;
  late final TextEditingController _addressController;
  late final TextEditingController _localityController;
  late final TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    final form = ref.read(jobFormNotifierProvider);
    _venueController = TextEditingController(text: form.venueName);
    _addressController = TextEditingController(text: form.reportingAddress);
    _localityController = TextEditingController(text: form.locality);
    _pincodeController = TextEditingController(text: form.pincode);
  }

  @override
  void dispose() {
    _venueController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(jobFormNotifierProvider);
    final formNotifier = ref.read(jobFormNotifierProvider.notifier);
    final strings = ref.watch(stringsProvider);
    final isHindi = strings.language == AppLanguage.hindi;

    final ghazipurLocalities = isHindi
        ? [
            'लंका',
            'रविंद्रपुरी',
            'स्टेशन रोड',
            'मिश्रा बाजार',
            'गोरा बाजार',
            'रौजा',
            'जमानिया',
            'मुहम्मदाबाद',
            'सैदपुर',
            'दिलदारनगर',
            'जंगीपुर',
          ]
        : [
            'Lanka',
            'Ravindrapuri',
            'Station Road',
            'Mishra Bazar',
            'Gora Bazar',
            'Rauza',
            'Zamania',
            'Mohammadabad',
            'Saidpur',
            'Dildarnagar',
            'Jangipur',
          ];

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.venueLocationTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vXs,
          Text(
            strings.venueLocationSubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,

          // Venue Name
          AppTextField(
            label: strings.venueNameFieldLabel,
            hintText: strings.venueNameFieldHint,
            controller: _venueController,
            prefixIcon: const Icon(Icons.business_rounded, size: 20),
            onChanged: formNotifier.updateVenueName,
          ),
          AppSpacing.vMd,

          // Full Reporting Address
          AppTextField(
            label: strings.reportingAddressFieldLabel,
            hintText: strings.reportingAddressFieldHint,
            controller: _addressController,
            maxLines: 2,
            prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
            onChanged: formNotifier.updateReportingAddress,
          ),
          AppSpacing.vLg,

          // Locality selection
          Text(
            strings.jobLocalityFieldLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          AppSpacing.vXs,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ghazipurLocalities.map((loc) {
              final isSelected = formState.locality == loc;
              return ChoiceChip(
                label: Text(loc),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  if (selected) {
                    formNotifier.updateLocality(loc);
                    _localityController.text = loc;
                  }
                },
              );
            }).toList(),
          ),
          AppSpacing.vMd,

          // Custom Locality input
          AppTextField(
            label: strings.otherLocalityLabel,
            hintText: strings.otherLocalityHint,
            controller: _localityController,
            onChanged: formNotifier.updateLocality,
          ),
          AppSpacing.vMd,

          // PIN Code
          AppTextField(
            label: strings.jobPincodeFieldLabel,
            hintText: '233001',
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            onChanged: formNotifier.updatePincode,
          ),
        ],
      ),
    );
  }
}
