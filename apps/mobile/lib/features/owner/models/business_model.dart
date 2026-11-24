import '../../../core/localization/app_language.dart';

enum BusinessVerificationStatus {
  draft,
  pending,
  underReview,
  verified,
  rejected,
  suspended;

  static BusinessVerificationStatus fromString(String? value) {
    if (value == null) return BusinessVerificationStatus.draft;
    switch (value.toLowerCase()) {
      case 'pending':
        return BusinessVerificationStatus.pending;
      case 'under_review':
        return BusinessVerificationStatus.underReview;
      case 'verified':
        return BusinessVerificationStatus.verified;
      case 'rejected':
        return BusinessVerificationStatus.rejected;
      case 'suspended':
        return BusinessVerificationStatus.suspended;
      case 'draft':
      default:
        return BusinessVerificationStatus.draft;
    }
  }

  String get displayName => displayNameFor(AppLanguage.english);

  String displayNameFor(AppLanguage language) {
    switch (this) {
      case BusinessVerificationStatus.draft:
        return switch (language) {
          AppLanguage.hindi => 'प्रारूप (ड्राफ्ट)',
          AppLanguage.hinglish => 'Draft',
          AppLanguage.english => 'Draft',
        };
      case BusinessVerificationStatus.pending:
        return switch (language) {
          AppLanguage.hindi => 'समीक्षा प्रतीक्षित',
          AppLanguage.hinglish => 'Pending Review',
          AppLanguage.english => 'Pending Review',
        };
      case BusinessVerificationStatus.underReview:
        return switch (language) {
          AppLanguage.hindi => 'समीक्षा जारी',
          AppLanguage.hinglish => 'Under Review',
          AppLanguage.english => 'Under Review',
        };
      case BusinessVerificationStatus.verified:
        return switch (language) {
          AppLanguage.hindi => 'सत्यापित व्यवसाय',
          AppLanguage.hinglish => 'Verified Business',
          AppLanguage.english => 'Verified Business',
        };
      case BusinessVerificationStatus.rejected:
        return switch (language) {
          AppLanguage.hindi => 'अस्वीकृत',
          AppLanguage.hinglish => 'Rejected',
          AppLanguage.english => 'Rejected',
        };
      case BusinessVerificationStatus.suspended:
        return switch (language) {
          AppLanguage.hindi => 'खाता निलंबित',
          AppLanguage.hinglish => 'Suspended',
          AppLanguage.english => 'Suspended',
        };
    }
  }

  bool get isDraft => this == BusinessVerificationStatus.draft;
  bool get isPending => this == BusinessVerificationStatus.pending;
  bool get isUnderReview => this == BusinessVerificationStatus.underReview;
  bool get isVerified => this == BusinessVerificationStatus.verified;
  bool get isRejected => this == BusinessVerificationStatus.rejected;
  bool get isSuspended => this == BusinessVerificationStatus.suspended;
}

enum BusinessCategoryType {
  marriageHall,
  cateringAgency,
  tentHouse,
  eventOrganizer,
  djSound,
  other;

  static BusinessCategoryType fromString(String? value) {
    if (value == null) return BusinessCategoryType.marriageHall;
    switch (value.toLowerCase()) {
      case 'catering_agency':
      case 'catering':
        return BusinessCategoryType.cateringAgency;
      case 'tent_house':
      case 'tent':
        return BusinessCategoryType.tentHouse;
      case 'event_organizer':
      case 'event':
        return BusinessCategoryType.eventOrganizer;
      case 'dj_sound':
      case 'dj':
        return BusinessCategoryType.djSound;
      case 'other':
        return BusinessCategoryType.other;
      case 'marriage_hall':
      default:
        return BusinessCategoryType.marriageHall;
    }
  }

  String get code {
    switch (this) {
      case BusinessCategoryType.marriageHall:
        return 'marriage_hall';
      case BusinessCategoryType.cateringAgency:
        return 'catering_agency';
      case BusinessCategoryType.tentHouse:
        return 'tent_house';
      case BusinessCategoryType.eventOrganizer:
        return 'event_organizer';
      case BusinessCategoryType.djSound:
        return 'dj_sound';
      case BusinessCategoryType.other:
        return 'other';
    }
  }

  String displayNameFor(AppLanguage language) {
    switch (this) {
      case BusinessCategoryType.marriageHall:
        return switch (language) {
          AppLanguage.hindi => 'मैरिज लॉन / हॉल',
          AppLanguage.hinglish => 'Marriage Hall / Lawn',
          AppLanguage.english => 'Marriage Hall / Lawn',
        };
      case BusinessCategoryType.cateringAgency:
        return switch (language) {
          AppLanguage.hindi => 'कैटरिंग एजेंसी',
          AppLanguage.hinglish => 'Catering Agency',
          AppLanguage.english => 'Catering Agency',
        };
      case BusinessCategoryType.tentHouse:
        return switch (language) {
          AppLanguage.hindi => 'टेंट हाउस',
          AppLanguage.hinglish => 'Tent House',
          AppLanguage.english => 'Tent House',
        };
      case BusinessCategoryType.eventOrganizer:
        return switch (language) {
          AppLanguage.hindi => 'इवेंट ऑर्गनाइज़र',
          AppLanguage.hinglish => 'Event Organizer',
          AppLanguage.english => 'Event Organizer',
        };
      case BusinessCategoryType.djSound:
        return switch (language) {
          AppLanguage.hindi => 'डीजे / साउंड ऑपरेटर',
          AppLanguage.hinglish => 'DJ & Sound Operator',
          AppLanguage.english => 'DJ & Sound Operator',
        };
      case BusinessCategoryType.other:
        return switch (language) {
          AppLanguage.hindi => 'अन्य व्यापार',
          AppLanguage.hinglish => 'Other Business',
          AppLanguage.english => 'Other Business',
        };
    }
  }

  String get displayName => displayNameFor(AppLanguage.english);
}

class BusinessModel {
  final String id;
  final String createdBy;
  final String name;
  final BusinessCategoryType categoryType;
  final String? description;
  final String? contactPerson;
  final String contactPhone;
  final String country;
  final String state;
  final String district;
  final String city;
  final String locality;
  final String? address;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? gstOrTradeId;
  final BusinessVerificationStatus verificationStatus;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? verifiedAt;
  final bool isFirstJobApproved;
  final DateTime? createdAt;
  final List<dynamic> documents;

  const BusinessModel({
    required this.id,
    required this.createdBy,
    required this.name,
    this.categoryType = BusinessCategoryType.marriageHall,
    this.description,
    this.contactPerson,
    required this.contactPhone,
    this.country = 'India',
    this.state = 'Uttar Pradesh',
    this.district = 'Ghazipur',
    this.city = 'Ghazipur',
    required this.locality,
    this.address,
    this.pincode = '233001',
    this.latitude,
    this.longitude,
    this.gstOrTradeId,
    this.verificationStatus = BusinessVerificationStatus.draft,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.verifiedAt,
    this.isFirstJobApproved = false,
    this.createdAt,
    this.documents = const [],
  });

  bool get canEdit =>
      verificationStatus == BusinessVerificationStatus.draft ||
      verificationStatus == BusinessVerificationStatus.rejected;

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryType:
          BusinessCategoryType.fromString(json['business_type'] as String?),
      description: json['description'] as String?,
      contactPerson: json['contact_person'] as String?,
      contactPhone: json['contact_phone'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      state: json['state'] as String? ?? 'Uttar Pradesh',
      district: json['district'] as String? ?? 'Ghazipur',
      city: json['city'] as String? ?? 'Ghazipur',
      locality: json['locality'] as String? ?? 'Ghazipur',
      address: json['address'] as String?,
      pincode: json['pincode'] as String? ?? '233001',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      gstOrTradeId: json['gst_or_trade_id'] as String?,
      verificationStatus: BusinessVerificationStatus.fromString(
          json['verification_status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      isFirstJobApproved: json['is_first_job_approved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      documents: json['documents'] as List<dynamic>? ?? const [],
    );
  }
}
