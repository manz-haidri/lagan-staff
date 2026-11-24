import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/owner_repository.dart';
import '../models/business_document_model.dart';
import '../models/business_model.dart';
import '../models/owner_job_history_item.dart';

class OwnerOnboardingState {
  final int currentStep;
  final String? businessId;
  final BusinessCategoryType categoryType;
  final String businessName;
  final String description;
  final String contactPerson;
  final String contactPhone;
  final String verifiedMobile;
  final String country;
  final String stateName;
  final String district;
  final String city;
  final String locality;
  final String address;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? gstOrTradeId;
  final List<BusinessDocumentModel> uploadedDocuments;
  final bool isSavingDraft;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;
  final BusinessVerificationStatus verificationStatus;

  const OwnerOnboardingState({
    this.currentStep = 0,
    this.businessId,
    this.categoryType = BusinessCategoryType.marriageHall,
    this.businessName = '',
    this.description = '',
    this.contactPerson = '',
    this.contactPhone = '',
    this.verifiedMobile = '',
    this.country = 'India',
    this.stateName = 'Uttar Pradesh',
    this.district = 'Ghazipur',
    this.city = 'Ghazipur',
    this.locality = '',
    this.address = '',
    this.pincode = '233001',
    this.latitude,
    this.longitude,
    this.gstOrTradeId,
    this.uploadedDocuments = const [],
    this.isSavingDraft = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
    this.verificationStatus = BusinessVerificationStatus.draft,
  });

  bool get isStep1Valid => true; // Category selected
  bool get isStep2Valid =>
      businessName.trim().length >= 2 &&
      (contactPhone.trim().length >= 10 || verifiedMobile.trim().length >= 10);
  bool get isStep3Valid =>
      locality.trim().length >= 2 &&
      RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode.trim());
  bool get isStep4Valid => true; // Documents are optional for MVP

  OwnerOnboardingState copyWith({
    int? currentStep,
    String? businessId,
    BusinessCategoryType? categoryType,
    String? businessName,
    String? description,
    String? contactPerson,
    String? contactPhone,
    String? verifiedMobile,
    String? country,
    String? stateName,
    String? district,
    String? city,
    String? locality,
    String? address,
    String? pincode,
    double? latitude,
    double? longitude,
    String? gstOrTradeId,
    List<BusinessDocumentModel>? uploadedDocuments,
    bool? isSavingDraft,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
    BusinessVerificationStatus? verificationStatus,
  }) {
    return OwnerOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      businessId: businessId ?? this.businessId,
      categoryType: categoryType ?? this.categoryType,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      verifiedMobile: verifiedMobile ?? this.verifiedMobile,
      country: country ?? this.country,
      stateName: stateName ?? this.stateName,
      district: district ?? this.district,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gstOrTradeId: gstOrTradeId ?? this.gstOrTradeId,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

class OwnerOnboardingNotifier extends Notifier<OwnerOnboardingState> {
  late final OwnerRepository _ownerRepo;

  @override
  OwnerOnboardingState build() {
    _ownerRepo = ref.read(ownerRepositoryProvider);
    return const OwnerOnboardingState();
  }

  void initializeFromProfile({
    required String ownerName,
    required String verifiedPhone,
  }) {
    state = state.copyWith(
      contactPerson: state.contactPerson.isEmpty ? ownerName : state.contactPerson,
      verifiedMobile: verifiedPhone,
      contactPhone: state.contactPhone.isEmpty ? verifiedPhone : state.contactPhone,
    );
  }

  void loadExistingBusiness(BusinessModel biz) {
    state = state.copyWith(
      businessId: biz.id,
      categoryType: biz.categoryType,
      businessName: biz.name,
      description: biz.description ?? '',
      contactPerson: biz.contactPerson ?? state.contactPerson,
      contactPhone: biz.contactPhone,
      locality: biz.locality,
      address: biz.address ?? '',
      pincode: biz.pincode,
      latitude: biz.latitude,
      longitude: biz.longitude,
      gstOrTradeId: biz.gstOrTradeId,
      verificationStatus: biz.verificationStatus,
      uploadedDocuments: biz.documents
          .map((d) => BusinessDocumentModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void setCategory(BusinessCategoryType cat) {
    state = state.copyWith(categoryType: cat, clearError: true);
  }

  void updateDetails({
    String? name,
    String? description,
    String? contactPerson,
    String? contactPhone,
    String? gstOrTradeId,
  }) {
    state = state.copyWith(
      businessName: name ?? state.businessName,
      description: description ?? state.description,
      contactPerson: contactPerson ?? state.contactPerson,
      contactPhone: contactPhone ?? state.contactPhone,
      gstOrTradeId: gstOrTradeId ?? state.gstOrTradeId,
      clearError: true,
    );
  }

  void updateLocation({
    required String locality,
    required String pincode,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    state = state.copyWith(
      locality: locality,
      pincode: pincode,
      address: address ?? state.address,
      latitude: latitude ?? state.latitude,
      longitude: longitude ?? state.longitude,
      clearError: true,
    );
  }

  /// Saves the current progress as a draft in database
  Future<bool> saveDraft() async {
    state = state.copyWith(isSavingDraft: true, clearError: true);
    try {
      final bizId = await _ownerRepo.saveBusinessDraft(
        businessId: state.businessId,
        name: state.businessName.isNotEmpty ? state.businessName : 'मेरा व्यवसाय (Draft)',
        businessType: state.categoryType.code,
        description: state.description,
        contactPerson: state.contactPerson,
        contactPhone: state.contactPhone.isNotEmpty ? state.contactPhone : state.verifiedMobile,
        locality: state.locality.isNotEmpty ? state.locality : 'Ghazipur',
        address: state.address,
        pincode: state.pincode.isNotEmpty ? state.pincode : '233001',
        latitude: state.latitude,
        longitude: state.longitude,
        gstOrTradeId: state.gstOrTradeId,
      );

      if (bizId != null) {
        state = state.copyWith(
          businessId: bizId,
          isSavingDraft: false,
          verificationStatus: BusinessVerificationStatus.draft,
        );
        return true;
      }
    } catch (e) {
      debugPrint('[OwnerOnboardingNotifier] saveDraft error: $e');
      state = state.copyWith(
        isSavingDraft: false,
        errorMessage: 'प्रारूप सहेजने में विफल (Save draft failed): $e',
      );
    }
    state = state.copyWith(isSavingDraft: false);
    return false;
  }

  /// Uploads proof file to private storage
  Future<bool> uploadDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String documentType,
    String mimeType = 'image/jpeg',
  }) async {
    // Ensure draft is saved first so we have a valid businessId
    if (state.businessId == null) {
      final saved = await saveDraft();
      if (!saved || state.businessId == null) {
        state = state.copyWith(errorMessage: 'कृपया पहले व्यापार विवरण सहेजें।');
        return false;
      }
    }

    try {
      final doc = await _ownerRepo.uploadBusinessDocument(
        businessId: state.businessId!,
        fileBytes: fileBytes,
        fileName: fileName,
        documentType: documentType,
        mimeType: mimeType,
      );

      final updated = List<BusinessDocumentModel>.from(state.uploadedDocuments)..add(doc);
      state = state.copyWith(uploadedDocuments: updated, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'दस्तावेज़ अपलोड में त्रुटि: $e');
      return false;
    }
  }

  /// Deletes an uploaded proof
  Future<void> deleteDocument(String documentId, String storagePath) async {
    try {
      await _ownerRepo.deleteBusinessDocument(documentId, storagePath);
      final updated = state.uploadedDocuments.where((d) => d.id != documentId).toList();
      state = state.copyWith(uploadedDocuments: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: 'दस्तावेज़ हटाने में त्रुटि: $e');
    }
  }

  /// Formally submits the business for Admin verification
  Future<bool> submitForVerification() async {
    if (!state.isStep2Valid) {
      state = state.copyWith(errorMessage: 'कृपया व्यापार नाम और संपर्क नंबर दर्ज करें।');
      return false;
    }
    if (!state.isStep3Valid) {
      state = state.copyWith(errorMessage: 'कृपया सही मोहल्ला और 6 अंकों का पिन कोड दर्ज करें।');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // 1. Ensure latest changes are saved in draft
      final bizId = await _ownerRepo.saveBusinessDraft(
        businessId: state.businessId,
        name: state.businessName,
        businessType: state.categoryType.code,
        description: state.description,
        contactPerson: state.contactPerson,
        contactPhone: state.contactPhone,
        locality: state.locality,
        address: state.address,
        pincode: state.pincode,
        latitude: state.latitude,
        longitude: state.longitude,
        gstOrTradeId: state.gstOrTradeId,
      );

      final targetId = bizId ?? state.businessId;
      if (targetId == null) {
        throw Exception('व्यवसाय आईडी अनुपलब्ध है।');
      }

      // 2. Submit for verification
      final success = await _ownerRepo.submitBusinessForVerification(targetId);
      if (success) {
        state = state.copyWith(
          businessId: targetId,
          isSubmitting: false,
          isSuccess: true,
          verificationStatus: BusinessVerificationStatus.pending,
        );
        return true;
      }
    } catch (e) {
      debugPrint('[OwnerOnboardingNotifier] submitForVerification error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'सत्यापन अनुरोध सबमिट करने में विफल: $e',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: false);
    return false;
  }
}

final ownerOnboardingNotifierProvider =
    NotifierProvider<OwnerOnboardingNotifier, OwnerOnboardingState>(
  OwnerOnboardingNotifier.new,
);

/// Provider to fetch and cache current owner's business
final currentOwnerBusinessProvider = FutureProvider<BusinessModel?>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return await repo.getMyBusiness();
});

/// Provider for owner business statistics
final ownerBusinessStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, businessId) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return await repo.fetchBusinessStats(businessId);
});

/// Provider for owner job history with optional filter
final ownerJobHistoryProvider = FutureProvider.family<List<OwnerJobHistoryItem>,
    ({String businessId, String? status})>((ref, args) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return await repo.fetchBusinessJobHistory(args.businessId,
      statusFilter: args.status);
});
