import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'live_selfie_check.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../presentation/worker_onboarding_notifier.dart';

class Step4SelfieCapture extends StatefulWidget {
  final WorkerOnboardingState state;
  final WorkerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step4SelfieCapture({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  State<Step4SelfieCapture> createState() => _Step4SelfieCaptureState();
}

class _Step4SelfieCaptureState extends State<Step4SelfieCapture> {
  bool _isCapturing = false;
  String? _captureError;

  Future<void> _captureSelfie() async {
    setState(() {
      _isCapturing = true;
      _captureError = null;
    });

    try {
      widget.notifier.clearSelfie();
      final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => LiveSelfieCheck(language: widget.strings.language)),
      );
      if (mounted && bytes != null) widget.notifier.setSelfie(bytes, 'live-selfie.jpg');
    } catch (e) {
      if (!mounted) return;
      debugPrint('[Step4SelfieCapture] Camera capture error: $e');
      setState(() {
        _captureError = '${widget.strings.cameraErrorPrefix}$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final hasSelfie = widget.state.selfieBytes != null;
    final sizeKb = hasSelfie
        ? (widget.state.selfieBytes!.lengthInBytes / 1024).toStringAsFixed(1)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          strings.selfieVerificationTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          strings.selfieVerificationSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        // Instructions Card
        AppCard(
          backgroundColor: AppColors.surfaceMuted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.selfieRulesTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strings.selfieRulesDesc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vLg,

        // Preview or Camera Trigger Area
        Center(
          child: hasSelfie
              ? Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.success, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                        image: DecorationImage(
                          image: MemoryImage(widget.state.selfieBytes!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    AppSpacing.vSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        AppSpacing.hXs,
                        Text(
                          '${strings.selfieReady} ($sizeKb KB • ${strings.compressed})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vMd,
                    SizedBox(
                      width: 180,
                      child: AppSecondaryButton(
                        label: strings.retakePhoto,
                        icon: Icons.camera_alt_outlined,
                        onPressed: _isCapturing ? null : _captureSelfie,
                      ),
                    ),
                  ],
                )
              : widget.state.completedProfile?.isSelfieVerified == true
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                              size: 48,
                            ),
                          ),
                          AppSpacing.vMd,
                          Text(
                            strings.selfieVerifiedAndUploaded,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          AppSpacing.vXs,
                          Text(
                            strings.language == AppLanguage.hindi
                                ? 'आपकी वर्तमान सेल्फी सत्यापित है। यदि आप नई फोटो लेना चाहते हैं तो नीचे क्लिक करें।'
                                : 'Your current selfie is verified. Tap below if you want to update it.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.vMd,
                          SizedBox(
                            width: 200,
                            child: AppSecondaryButton(
                              label: strings.retakePhoto,
                              icon: Icons.camera_alt_outlined,
                              onPressed: _isCapturing ? null : _captureSelfie,
                            ),
                          ),
                        ],
                      ),
                    )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural_rounded,
                          color: AppColors.primary,
                          size: 56,
                        ),
                      ),
                      AppSpacing.vMd,
                      Text(
                        strings.language == AppLanguage.hindi
                            ? 'अभी तक कोई सेल्फी नहीं ली गई है'
                            : 'No selfie taken yet',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.vSm,
                      Text(
                        strings.language == AppLanguage.hindi
                            ? 'फ्रंट कैमरा शुरू करने के लिए नीचे दिए बटन पर क्लिक करें'
                            : 'Tap the button below to open the front camera',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.vLg,
                      SizedBox(
                        width: 240,
                        child: AppPrimaryButton(
                          label: strings.takeSelfieButton,
                          icon: Icons.camera_front_rounded,
                          isLoading: _isCapturing,
                          onPressed: _captureSelfie,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        if (_captureError != null) ...[
          AppSpacing.vMd,
          Text(
            _captureError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
