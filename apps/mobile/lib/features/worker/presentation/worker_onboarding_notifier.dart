import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/worker_repository.dart';
import '../models/published_job.dart';
import '../models/worker_profile.dart';
import '../models/worker_skill.dart';

class WorkerOnboardingState {
  static const maxSkills = 5;
  final int currentStep;
  final String fullName;
  final String phone;
  final List<SkillCategory> categories;
  final Set<String> selectedSkillIds;
  final String customSkillName;
  final String locality;
  final String city;
  final String district;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final Uint8List? selfieBytes;
  final String? selfieFileName;
  final bool isLoadingCategories;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;
  final WorkerProfileModel? completedProfile;

  const WorkerOnboardingState({
    this.currentStep = 0,
    this.fullName = '',
    this.phone = '',
    this.categories = const [],
    this.selectedSkillIds = const {},
    this.customSkillName = '',
    this.locality = '',
    this.city = 'Ghazipur',
    this.district = 'Ghazipur',
    this.pincode = '233001',
    this.latitude,
    this.longitude,
    this.selfieBytes,
    this.selfieFileName,
    this.isLoadingCategories = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
    this.completedProfile,
  });

  bool get isStep1Valid => fullName.trim().length >= 2;
  bool get isStep2Valid => selectedSkillIds.isNotEmpty && selectedSkillIds.length <= maxSkills;
  bool get isStep3Valid =>
      locality.trim().length >= 2 &&
      RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode.trim());
  bool get isStep4Valid =>
      (selfieBytes != null && selfieBytes!.isNotEmpty) ||
      (completedProfile?.isSelfieVerified == true &&
          (completedProfile?.selfieStoragePath?.isNotEmpty == true));

  WorkerOnboardingState copyWith({
    int? currentStep,
    String? fullName,
    String? phone,
    List<SkillCategory>? categories,
    Set<String>? selectedSkillIds,
    String? customSkillName,
    String? locality,
    String? city,
    String? district,
    String? pincode,
    double? latitude,
    double? longitude,
    Uint8List? selfieBytes,
    String? selfieFileName,
    bool? isLoadingCategories,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool discardSelfie = false,
    bool? isSuccess,
    WorkerProfileModel? completedProfile,
  }) {
    return WorkerOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      categories: categories ?? this.categories,
      selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
      customSkillName: customSkillName ?? this.customSkillName,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      district: district ?? this.district,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      selfieBytes: discardSelfie ? null : selfieBytes ?? this.selfieBytes,
      selfieFileName: discardSelfie ? null : selfieFileName ?? this.selfieFileName,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      completedProfile: completedProfile ?? this.completedProfile,
    );
  }
}

class WorkerOnboardingNotifier extends Notifier<WorkerOnboardingState> {
  late final WorkerRepository _workerRepo;

  @override
  WorkerOnboardingState build() {
    _workerRepo = ref.read(workerRepositoryProvider);
    // Asynchronously load categories & initial skills
    Future.microtask(() => loadCategories());
    return const WorkerOnboardingState();
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true);
    try {
      final list = await _workerRepo.fetchCategoriesWithSkills();
      state = state.copyWith(
        categories: list,
        isLoadingCategories: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        errorMessage: 'कौशल सूची लोड करने में त्रुटि (Failed to load categories)',
      );
    }
  }

  void initializeUserData({required String fullName, required String phone}) {
    if (state.phone != phone) {
      state = WorkerOnboardingState(categories: state.categories, isLoadingCategories: state.isLoadingCategories);
    }
    state = state.copyWith(
      fullName: state.fullName.isEmpty ? fullName : state.fullName,
      phone: phone,
    );
  }

  void loadExistingProfile(WorkerProfileModel profile) {
    final skillIds = profile.skills
        .map((s) => s.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    final customSkill = profile.skills
        .map((s) => s.customSkillName)
        .firstWhere((name) => name != null && name.isNotEmpty, orElse: () => null);

    state = state.copyWith(
      fullName: profile.fullName.isNotEmpty ? profile.fullName : state.fullName,
      phone: profile.phone.isNotEmpty ? profile.phone : state.phone,
      locality: profile.locality.isNotEmpty ? profile.locality : state.locality,
      city: profile.city.isNotEmpty ? profile.city : state.city,
      district: profile.district.isNotEmpty ? profile.district : state.district,
      pincode: profile.pincode.isNotEmpty ? profile.pincode : state.pincode,
      latitude: profile.latitude ?? state.latitude,
      longitude: profile.longitude ?? state.longitude,
      selectedSkillIds: skillIds.isNotEmpty ? skillIds : state.selectedSkillIds,
      customSkillName: customSkill ?? state.customSkillName,
      completedProfile: profile,
    );
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  void updateFullName(String name) {
    state = state.copyWith(fullName: name, clearError: true);
  }

  void toggleSkill(String skillId) {
    final updated = Set<String>.from(state.selectedSkillIds);
    if (updated.contains(skillId)) {
      updated.remove(skillId);
    } else if (updated.length < WorkerOnboardingState.maxSkills) {
      updated.add(skillId);
    }
    state = state.copyWith(selectedSkillIds: updated, clearError: true);
  }

  void updateCustomSkillName(String name) {
    state = state.copyWith(customSkillName: name, clearError: true);
  }

  void updateLocation({
    required String locality,
    required String pincode,
    double? latitude,
    double? longitude,
  }) {
    state = state.copyWith(
      locality: locality,
      pincode: pincode,
      latitude: latitude ?? state.latitude,
      longitude: longitude ?? state.longitude,
      clearError: true,
    );
  }

  void setSelfie(Uint8List bytes, String fileName) {
    state = state.copyWith(
      selfieBytes: bytes,
      selfieFileName: fileName,
      clearError: true,
    );
  }

  void clearSelfie() {
    state = state.copyWith(
      discardSelfie: true,
      clearError: true,
    );
  }

  /// Complete Worker Registration: Upload compressed selfie -> Run atomic RPC -> Automatic activation
  Future<bool> submitOnboarding({required String userId}) async {
    // 1. Validate all requirements
    if (!state.isStep1Valid) {
      state = state.copyWith(errorMessage: 'कृपया अपना पूरा नाम दर्ज करें (Name is required).');
      return false;
    }
    if (!state.isStep2Valid) {
      state = state.copyWith(errorMessage: 'कम से कम एक कार्य कौशल चुनें (Select at least 1 skill).');
      return false;
    }
    if (!state.isStep3Valid) {
      state = state.copyWith(errorMessage: 'कृपया सही मोहल्ला/स्थान और 6-अंकों का पिन कोड दर्ज करें।');
      return false;
    }
    if (!state.isStep4Valid) {
      state = state.copyWith(errorMessage: 'कृपया कैमरे से लाइव सेल्फी खींचें (Selfie is required).');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // 2. Upload Selfie to Private Storage bucket if a new selfie was taken
      final storagePath = (state.selfieBytes != null && state.selfieBytes!.isNotEmpty)
          ? await _workerRepo.uploadSelfie(
              userId: userId,
              imageBytes: state.selfieBytes!,
              extension: 'jpg',
            )
          : (state.completedProfile?.selfieStoragePath ?? '');

      // 3. Complete Onboarding via PostgreSQL RPC
      final completed = await _workerRepo.completeWorkerOnboarding(
        fullName: state.fullName,
        locality: state.locality,
        pincode: state.pincode,
        latitude: state.latitude,
        longitude: state.longitude,
        selfieStoragePath: storagePath,
        skillIds: state.selectedSkillIds.toList(),
        customSkill: state.customSkillName,
      );

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        completedProfile: completed,
      );

      return true;
    } catch (e) {
      debugPrint('[WorkerOnboardingNotifier] Error submitting onboarding: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'पंजीकरण पूरा नहीं हो सका: $e',
      );
      return false;
    }
  }
}

final workerOnboardingNotifierProvider =
    NotifierProvider<WorkerOnboardingNotifier, WorkerOnboardingState>(
  WorkerOnboardingNotifier.new,
);

/// Provider to fetch and cache current worker profile
final currentWorkerProfileProvider =
    FutureProvider<WorkerProfileModel?>((ref) async {
  final repo = ref.watch(workerRepositoryProvider);
  return await repo.getWorkerOnboardingStatus();
});

/// Provider to fetch available published jobs in Ghazipur
final publishedJobsProvider = FutureProvider<List<PublishedJob>>((ref) async {
  final repo = ref.watch(workerRepositoryProvider);
  return await repo.fetchPublishedJobs();
});
