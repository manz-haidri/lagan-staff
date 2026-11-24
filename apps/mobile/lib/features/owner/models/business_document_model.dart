import '../../../core/localization/app_language.dart';

class BusinessDocumentModel {
  final String id;
  final String businessId;
  final String documentType;
  final String storagePath;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final DateTime? createdAt;

  const BusinessDocumentModel({
    required this.id,
    required this.businessId,
    required this.documentType,
    required this.storagePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    this.createdAt,
  });

  String displayNameFor(AppLanguage language) {
    switch (documentType) {
      case 'visiting_card':
        return switch (language) {
          AppLanguage.hindi => 'विजिटिंग कार्ड',
          AppLanguage.hinglish => 'Visiting Card',
          AppLanguage.english => 'Visiting Card',
        };
      case 'gst_certificate':
        return switch (language) {
          AppLanguage.hindi => 'जीएसटी प्रमाण पत्र',
          AppLanguage.hinglish => 'GST Certificate',
          AppLanguage.english => 'GST Certificate',
        };
      case 'business_registration':
        return switch (language) {
          AppLanguage.hindi => 'व्यापार पंजीकरण',
          AppLanguage.hinglish => 'Business Registration',
          AppLanguage.english => 'Business Registration',
        };
      case 'business_photo':
        return switch (language) {
          AppLanguage.hindi => 'प्रतिष्ठान फोटो',
          AppLanguage.hinglish => 'Business Photo',
          AppLanguage.english => 'Business Photo',
        };
      case 'other':
      default:
        return switch (language) {
          AppLanguage.hindi => 'अन्य प्रमाण',
          AppLanguage.hinglish => 'Other Document',
          AppLanguage.english => 'Other Document',
        };
    }
  }

  String get typeDisplayName => displayNameFor(AppLanguage.english);

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory BusinessDocumentModel.fromJson(Map<String, dynamic> json) {
    return BusinessDocumentModel(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      documentType: json['document_type'] as String? ?? 'other',
      storagePath: json['storage_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? 'document',
      fileSizeBytes: int.tryParse(json['file_size_bytes']?.toString() ?? '0') ?? 0,
      mimeType: json['mime_type'] as String? ?? 'image/jpeg',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
