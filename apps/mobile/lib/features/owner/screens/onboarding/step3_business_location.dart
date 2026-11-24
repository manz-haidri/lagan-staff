import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/owner_onboarding_notifier.dart';

class Step3BusinessLocation extends StatefulWidget {
  final OwnerOnboardingState state;
  final OwnerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step3BusinessLocation({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  State<Step3BusinessLocation> createState() => _Step3BusinessLocationState();
}

class _Step3BusinessLocationState extends State<Step3BusinessLocation> {
  late final TextEditingController _localityController;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;

  List<String> get _popularLocalities {
    if (widget.strings.language == AppLanguage.hindi) {
      return const [
        'लंका',
        'मिश्रा बाजार',
        'सिटी स्टेशन',
        'मुहम्मदाबाद',
        'जमानिया',
        'सैदपुर',
        'शास्त्री नगर',
        'जंगीपुर',
      ];
    }
    return const [
      'Lanka',
      'Mishra Bazar',
      'City Station',
      'Mohammadabad',
      'Zamania',
      'Saidpur',
      'Shastri Nagar',
      'Jangipur',
    ];
  }

  @override
  void initState() {
    super.initState();
    _localityController = TextEditingController(text: widget.state.locality);
    _addressController = TextEditingController(text: widget.state.address);
    _pincodeController = TextEditingController(text: widget.state.pincode);
  }

  @override
  void dispose() {
    _localityController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _syncState() {
    widget.notifier.updateLocation(
      locality: _localityController.text,
      address: _addressController.text,
      pincode: _pincodeController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final isHindi = strings.language == AppLanguage.hindi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.businessLocationTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.businessLocationSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        // Quick Locality Chips
        Text(
          strings.popularAreasTitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.vSm,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularLocalities.map((loc) {
            final isSelected = _localityController.text.trim() == loc;
            return ActionChip(
              label: Text(loc),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              backgroundColor:
                  isSelected ? AppColors.primary : AppColors.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onPressed: () {
                setState(() {
                  _localityController.text = loc;
                });
                _syncState();
              },
            );
          }).toList(),
        ),
        AppSpacing.vLg,

        // Locality Input
        AppTextField(
          label: strings.businessLocalityLabel,
          hintText: isHindi ? 'उदा. लंका, निकट पीजी कॉलेज गेट' : 'E.g. Lanka, near PG College Gate',
          controller: _localityController,
          prefixIcon: const Icon(Icons.location_on_outlined),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vMd,

        // Full Address / Landmark
        AppTextField(
          label: strings.venueAddressSummaryLabel,
          hintText: strings.venueAddressHint,
          controller: _addressController,
          maxLines: 2,
          prefixIcon: const Icon(Icons.home_work_outlined),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vMd,

        // Fixed District & City Display Cards
        Row(
          children: [
            Expanded(
              child: AppCard(
                backgroundColor: AppColors.surfaceMuted,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.cityDistrictLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      strings.ghazipurCity,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: AppCard(
                backgroundColor: AppColors.surfaceMuted,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.stateLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      strings.uttarPradeshState,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vMd,

        // PIN Code Input
        AppTextField(
          label: strings.businessPincodeLabel,
          hintText: '233001',
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.digitsOnly,
          ],
          prefixIcon: const Icon(Icons.pin_drop_outlined),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vSm,

        // Optional GPS Link Card
        AppCard(
          borderColor: widget.state.latitude != null
              ? AppColors.success
              : AppColors.border,
          child: Row(
            children: [
              Icon(
                widget.state.latitude != null
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: widget.state.latitude != null
                    ? AppColors.success
                    : AppColors.primary,
                size: 24,
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.state.latitude != null
                          ? (isHindi ? 'जीपीएस स्थान दर्ज' : 'GPS Linked')
                          : (isHindi ? 'सटीक मैप स्थान जोड़ें' : 'Optional GPS Location'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.state.latitude != null
                          ? (isHindi
                              ? 'अक्षांश: ${widget.state.latitude!.toStringAsFixed(4)}, रेखांश: ${widget.state.longitude!.toStringAsFixed(4)}'
                              : 'Lat: ${widget.state.latitude!.toStringAsFixed(4)}, Long: ${widget.state.longitude!.toStringAsFixed(4)}')
                          : (isHindi
                              ? 'कार्यकर्ताओं को लॉन ढूंढने में आसानी होगी (वैकल्पिक)'
                              : 'Helps workers easily locate venue (optional)'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.notifier.updateLocation(
                    locality: _localityController.text.isNotEmpty
                        ? _localityController.text
                        : (isHindi ? 'गाजीपुर सिटी' : 'Ghazipur City'),
                    address: _addressController.text,
                    pincode: _pincodeController.text.isNotEmpty
                        ? _pincodeController.text
                        : '233001',
                    latitude: 25.5840,
                    longitude: 83.5770,
                  );
                },
                child: Text(
                  widget.state.latitude != null ? strings.refresh : strings.linkLocationAction,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
