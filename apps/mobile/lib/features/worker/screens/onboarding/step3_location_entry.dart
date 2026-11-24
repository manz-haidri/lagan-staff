import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_text_fields.dart';
import '../../presentation/worker_onboarding_notifier.dart';

class Step3LocationDetails extends StatefulWidget {
  final WorkerOnboardingState state;
  final WorkerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step3LocationDetails({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  State<Step3LocationDetails> createState() => _Step3LocationDetailsState();
}

class _Step3LocationDetailsState extends State<Step3LocationDetails> {
  late final TextEditingController _localityController;
  late final TextEditingController _pincodeController;

  List<String> get _popularLocalities {
    if (widget.strings.language == AppLanguage.hindi) {
      return const [
        'लंका',
        'मिश्रा बाजार',
        'सिटी स्टेशन',
        'शास्त्री नगर',
        'मुहम्मदाबाद',
        'जमानिया',
        'सैदपुर',
        'जंगीपुर',
      ];
    }
    return const [
      'Lanka',
      'Mishra Bazar',
      'City Station',
      'Shastri Nagar',
      'Mohammadabad',
      'Zamania',
      'Saidpur',
      'Jangipur',
    ];
  }

  @override
  void initState() {
    super.initState();
    _localityController = TextEditingController(text: widget.state.locality);
    _pincodeController = TextEditingController(text: widget.state.pincode);
  }

  @override
  void didUpdateWidget(covariant Step3LocationDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.locality != widget.state.locality &&
        _localityController.text != widget.state.locality) {
      _localityController.text = widget.state.locality;
    }
    if (oldWidget.state.pincode != widget.state.pincode &&
        _pincodeController.text != widget.state.pincode) {
      _pincodeController.text = widget.state.pincode;
    }
  }

  @override
  void dispose() {
    _localityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _syncState() {
    widget.notifier.updateLocation(
      locality: _localityController.text,
      pincode: _pincodeController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          strings.workerLocationTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.workerLocationSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        // Quick Locality Chips
        Text(
          strings.quickSelect,
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
            final isSelected = _localityController.text.trim().toLowerCase() == loc.toLowerCase();
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
          label: strings.localityLabel,
          hintText: strings.localityHint,
          controller: _localityController,
          prefixIcon: const Icon(Icons.location_on_outlined),
          onChanged: (_) => _syncState(),
        ),
        AppSpacing.vMd,

        // District & City Cards (Fixed Ghazipur)
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
                      strings.cityFixedLabel,
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
                      strings.districtFixedLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      strings.ghazipurDistrict,
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
          label: strings.pincodeLabel,
          hintText: strings.pincodeHint,
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

        // Optional GPS Quick Button
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
                          ? strings.gpsLinked
                          : strings.optionalGpsTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.state.latitude != null
                          ? '${widget.state.latitude!.toStringAsFixed(4)}, ${widget.state.longitude!.toStringAsFixed(4)}'
                          : strings.optionalGpsSubtitle,
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
                        : strings.ghazipurCity,
                    pincode: _pincodeController.text.isNotEmpty
                        ? _pincodeController.text
                        : '233001',
                    latitude: 25.5840,
                    longitude: 83.5770,
                  );
                },
                child: Text(
                  widget.state.latitude != null ? strings.edit : strings.linkGps,
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
