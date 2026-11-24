import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/document_evidence.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../presentation/owner_onboarding_notifier.dart';

class Step4DocumentUpload extends StatefulWidget {
  final OwnerOnboardingState state;
  final OwnerOnboardingNotifier notifier;
  final AppStrings strings;

  const Step4DocumentUpload({
    super.key,
    required this.state,
    required this.notifier,
    required this.strings,
  });

  @override
  State<Step4DocumentUpload> createState() => _Step4DocumentUploadState();
}

class _Step4DocumentUploadState extends State<Step4DocumentUpload> {
  String _selectedDocType = 'visiting_card';
  bool _isUploading = false;
  String? _uploadError;

  Map<String, String> _getDocTypes(AppStrings strings) {
    final isHindi = strings.language == AppLanguage.hindi;
    return {
      'visiting_card': isHindi ? 'विजिटिंग कार्ड' : 'Visiting Card',
      'business_photo': isHindi ? 'प्रतिष्ठान / लॉन की फोटो' : 'Business Photo',
      'business_registration': isHindi ? 'पंजीकरण प्रमाण पत्र' : 'Registration Document',
      'gst_certificate': isHindi ? 'जीएसटी प्रमाण पत्र' : 'GST Certificate',
      'other': isHindi ? 'अन्य व्यावसायिक प्रमाण' : 'Other Proof',
    };
  }

  Future<void> _pickAndUpload() async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file != null && mounted) {
        final text = await const MethodChannel('laganstaff/document').invokeMethod<String>('readText', file.path);
        if (!mounted) return;
        final issue = checkDocumentEvidence(_selectedDocType, text ?? '', widget.state.businessName);
        final hindi = widget.strings.language == AppLanguage.hindi;
        if (issue != null) {
          setState(() => _uploadError = switch (issue) {
            DocumentIssue.unreadable => hindi ? 'लिखावट साफ़ नहीं है। रोशनी में फिर फोटो लें।' : 'Text is unreadable. Retake the photo in good light.',
            DocumentIssue.businessName => hindi ? 'फोटो में फॉर्म वाला पूरा व्यवसाय नाम साफ़ दिखाएँ।' : 'Show the full business name entered in Step 2. For a premises photo, include the signboard.',
            DocumentIssue.gst => hindi ? 'जीएसटी प्रमाणपत्र का शीर्षक और पूरा GSTIN दिखाएँ।' : 'Show the GST certificate heading and the full 15-character GSTIN.',
            DocumentIssue.registration => hindi ? 'पंजीकरण या लाइसेंस का शीर्षक दिखाएँ।' : 'Include the registration or licence heading in the photo.',
          });
          return;
        }
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        final success = await widget.notifier.uploadDocument(
          fileBytes: bytes,
          fileName: file.name,
          documentType: _selectedDocType,
          mimeType: 'image/jpeg',
        );

        if (!success && mounted) {
          setState(() {
            _uploadError = widget.state.errorMessage ??
                (widget.strings.language == AppLanguage.hindi
                    ? 'दस्तावेज़ अपलोड विफल रहा।'
                    : 'Document upload failed.');
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[Step4DocumentUpload] Pick error: $e');
      setState(() {
        _uploadError = '${widget.strings.errorPrefix}$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final isHindi = strings.language == AppLanguage.hindi;
    final docTypes = _getDocTypes(strings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.documentUploadTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        AppSpacing.vXs,
        Text(
          isHindi ? 'मूल दस्तावेज़ या व्यवसाय के साइनबोर्ड की साफ़ फोटो लें। पूरा व्यवसाय नाम दिखना चाहिए।' : 'Photograph the original document or business signboard. Include the full business name from Step 2.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vLg,

        // Optional Notice Card
        AppCard(
          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
          borderColor: AppColors.primary.withValues(alpha: 0.2),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              AppSpacing.hMd,
              Expanded(
                child: Text(
                  isHindi
                      ? 'दस्तावेज़ वैकल्पिक हैं। अपलोड से पहले लिखावट जाँची जाती है। अंतिम सत्यापन एडमिन करेगा।'
                      : 'Documents are optional. Text is checked before upload. An admin reviews the evidence before verifying your business.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vLg,

        // Document Type Selector
        Text(
          isHindi ? 'प्रमाण का प्रकार चुनें:' : 'Select Document Type:',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.vSm,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDocType,
              isExpanded: true,
              items: docTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isUploading ? null : (val) {
                if (val != null) {
                  setState(() {
                    _selectedDocType = val;
                  });
                }
              },
            ),
          ),
        ),
        AppSpacing.vMd,

        // Upload Button
        AppSecondaryButton(
          label: _isUploading ? strings.loading : strings.uploadDocumentButton,
          icon: Icons.upload_file_rounded,
          onPressed: _isUploading ? null : _pickAndUpload,
        ),

        if (_uploadError != null) ...[
          AppSpacing.vSm,
          Text(
            _uploadError!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
        AppSpacing.vLg,

        // Uploaded Documents List
        Text(
          '${isHindi ? "अपलोड किए गए दस्तावेज़" : "Uploaded Documents"} (${widget.state.uploadedDocuments.length}):',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.vSm,

        if (widget.state.uploadedDocuments.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, style: BorderStyle.none),
            ),
            child: Center(
              child: Text(
                isHindi ? 'अभी कोई दस्तावेज़ संलग्न नहीं है (वैकल्पिक)' : 'No documents attached yet (Optional)',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...widget.state.uploadedDocuments.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.displayNameFor(strings.language),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${doc.fileName} • ${doc.fileSizeFormatted}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 20),
                      tooltip: strings.deleteDocumentTooltip,
                      onPressed: () =>
                          widget.notifier.deleteDocument(doc.id, doc.storagePath),
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
