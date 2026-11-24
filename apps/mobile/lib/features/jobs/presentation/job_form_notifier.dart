import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/job_repository.dart';
import '../models/category_model.dart';
import '../models/job_model.dart';

class JobFormState {
  final int currentStep;
  final String? jobId;
  final String? businessId;

  // Step 1: Info
  final String title;
  final String description;
  final String? categoryId;
  final List<String> skillIds;
  final int workersNeeded;

  // Step 2: Date & Shift
  final DateTime? shiftDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isOvernight;

  // Step 3: Payment
  final double wageAmount;
  final String paymentInstructions;

  // Step 4: Venue & Location
  final String venueName;
  final String reportingAddress;
  final String locality;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;

  // Step 5: Perks & Requirements
  final bool foodProvided;
  final String foodDetails;
  final bool transportProvided;
  final String transportDetails;
  final String specialInstructions;

  // Meta & UI States
  final bool isSubmitting;
  final bool isDraftSaving;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic>? submitResult;

  const JobFormState({
    this.currentStep = 0,
    this.jobId,
    this.businessId,
    this.title = '',
    this.description = '',
    this.categoryId,
    this.skillIds = const [],
    this.workersNeeded = 2,
    this.shiftDate,
    this.startTime = const TimeOfDay(hour: 18, minute: 0),
    this.endTime = const TimeOfDay(hour: 23, minute: 30),
    this.isOvernight = false,
    this.wageAmount = 600.0,
    this.paymentInstructions = '',
    this.venueName = '',
    this.reportingAddress = '',
    this.locality = 'Lanka',
    this.city = 'Ghazipur',
    this.pincode = '233001',
    this.latitude,
    this.longitude,
    this.foodProvided = true,
    this.foodDetails = 'रात का भोजन प्रदान किया जाएगा (Dinner provided)',
    this.transportProvided = false,
    this.transportDetails = '',
    this.specialInstructions = 'सफेद कमीज और काली पैंट अनिवार्य है। समय पर उपस्थिति दें।',
    this.isSubmitting = false,
    this.isDraftSaving = false,
    this.errorMessage,
    this.successMessage,
    this.submitResult,
  });

  JobFormState copyWith({
    int? currentStep,
    String? jobId,
    String? businessId,
    String? title,
    String? description,
    String? categoryId,
    List<String>? skillIds,
    int? workersNeeded,
    DateTime? shiftDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isOvernight,
    double? wageAmount,
    String? paymentInstructions,
    String? venueName,
    String? reportingAddress,
    String? locality,
    String? city,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? foodProvided,
    String? foodDetails,
    bool? transportProvided,
    String? transportDetails,
    String? specialInstructions,
    bool? isSubmitting,
    bool? isDraftSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    Map<String, dynamic>? submitResult,
  }) {
    return JobFormState(
      currentStep: currentStep ?? this.currentStep,
      jobId: jobId ?? this.jobId,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      skillIds: skillIds ?? this.skillIds,
      workersNeeded: workersNeeded ?? this.workersNeeded,
      shiftDate: shiftDate ?? this.shiftDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isOvernight: isOvernight ?? this.isOvernight,
      wageAmount: wageAmount ?? this.wageAmount,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      venueName: venueName ?? this.venueName,
      reportingAddress: reportingAddress ?? this.reportingAddress,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      foodProvided: foodProvided ?? this.foodProvided,
      foodDetails: foodDetails ?? this.foodDetails,
      transportProvided: transportProvided ?? this.transportProvided,
      transportDetails: transportDetails ?? this.transportDetails,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isDraftSaving: isDraftSaving ?? this.isDraftSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      submitResult: submitResult ?? this.submitResult,
    );
  }
}

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(jobRepositoryProvider).fetchCategories();
});

final skillsProvider = FutureProvider.family<List<SkillModel>, String?>((ref, categoryId) {
  return ref.watch(jobRepositoryProvider).fetchSkills(categoryId: categoryId);
});

final jobFormNotifierProvider =
    NotifierProvider<JobFormNotifier, JobFormState>(JobFormNotifier.new);

class JobFormNotifier extends Notifier<JobFormState> {
  late final JobRepository _repository;

  @override
  JobFormState build() {
    _repository = ref.read(jobRepositoryProvider);
    return JobFormState(
      shiftDate: DateTime.now().add(const Duration(days: 1)),
    );
  }

  void initForBusiness(String businessId, {String? defaultLocality, String? defaultAddress}) {
    state = state.copyWith(
      businessId: businessId,
      locality: (defaultLocality != null && defaultLocality.isNotEmpty) ? defaultLocality : state.locality,
      reportingAddress: (defaultAddress != null && defaultAddress.isNotEmpty) ? defaultAddress : state.reportingAddress,
    );
  }

  void loadExistingJob(JobModel job) {
    TimeOfDay parseTime(String timeStr) {
      try {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {
        return const TimeOfDay(hour: 18, minute: 0);
      }
    }

    state = state.copyWith(
      jobId: job.id,
      businessId: job.businessId,
      title: job.title,
      description: job.description ?? '',
      categoryId: job.categoryId,
      skillIds: job.skills.map((s) => s.id).toList(),
      workersNeeded: job.workersNeeded,
      shiftDate: DateTime.tryParse(job.shiftDate),
      startTime: parseTime(job.startTime),
      endTime: parseTime(job.endTime),
      isOvernight: job.isOvernight,
      wageAmount: job.wageAmount,
      paymentInstructions: job.paymentInstructions ?? '',
      venueName: job.venueName ?? '',
      reportingAddress: job.reportingAddress,
      locality: job.locality,
      city: job.city,
      pincode: job.pincode,
      latitude: job.latitude,
      longitude: job.longitude,
      foodProvided: job.foodProvided,
      foodDetails: job.foodDetails ?? '',
      transportProvided: job.transportProvided,
      transportDetails: job.transportDetails ?? '',
      specialInstructions: job.specialInstructions ?? '',
    );
  }

  void setStep(int step) {
    if (step >= 0 && step <= 5) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  void nextStep() {
    if (validateCurrentStep()) {
      if (state.currentStep < 5) {
        state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
      }
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(String value) => state = state.copyWith(description: value);
  void updateCategory(String value) => state = state.copyWith(categoryId: value);
  void toggleSkill(String skillId) {
    final list = List<String>.from(state.skillIds);
    if (list.contains(skillId)) {
      list.remove(skillId);
    } else {
      list.add(skillId);
    }
    state = state.copyWith(skillIds: list);
  }

  void updateWorkersNeeded(int value) => state = state.copyWith(workersNeeded: value.clamp(1, 100));
  void updateShiftDate(DateTime date) => state = state.copyWith(shiftDate: date);
  void updateStartTime(TimeOfDay time) => state = state.copyWith(startTime: time);
  void updateEndTime(TimeOfDay time) => state = state.copyWith(endTime: time);
  void updateIsOvernight(bool value) => state = state.copyWith(isOvernight: value);

  void updateWage(double value) => state = state.copyWith(wageAmount: value);
  void updatePaymentInstructions(String value) => state = state.copyWith(paymentInstructions: value);

  void updateVenueName(String value) => state = state.copyWith(venueName: value);
  void updateReportingAddress(String value) => state = state.copyWith(reportingAddress: value);
  void updateLocality(String value) => state = state.copyWith(locality: value);
  void updatePincode(String value) => state = state.copyWith(pincode: value);

  void updateFoodProvided(bool value) => state = state.copyWith(foodProvided: value);
  void updateFoodDetails(String value) => state = state.copyWith(foodDetails: value);
  void updateTransportProvided(bool value) => state = state.copyWith(transportProvided: value);
  void updateTransportDetails(String value) => state = state.copyWith(transportDetails: value);
  void updateSpecialInstructions(String value) => state = state.copyWith(specialInstructions: value);

  bool validateCurrentStep() {
    switch (state.currentStep) {
      case 0: // Step 1: Info
        if (state.title.trim().length < 3) {
          state = state.copyWith(errorMessage: 'कार्य का शीर्षक कम से कम 3 अक्षरों का होना चाहिए।');
          return false;
        }
        if (state.categoryId == null || state.categoryId!.isEmpty) {
          state = state.copyWith(errorMessage: 'कृपया कार्यकर्ता की श्रेणी (Category) चुनें।');
          return false;
        }
        if (state.workersNeeded < 1) {
          state = state.copyWith(errorMessage: 'कम से कम 1 कार्यकर्ता की आवश्यकता होनी चाहिए।');
          return false;
        }
        return true;

      case 1: // Step 2: Date & Shift
        if (state.shiftDate == null) {
          state = state.copyWith(errorMessage: 'कृपया कार्य की तिथि चुनें।');
          return false;
        }
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final selected = DateTime(state.shiftDate!.year, state.shiftDate!.month, state.shiftDate!.day);
        if (selected.isBefore(today)) {
          state = state.copyWith(errorMessage: 'कार्य की तिथि आज या भविष्य की होनी चाहिए।');
          return false;
        }
        return true;

      case 2: // Step 3: Payment
        if (state.wageAmount <= 0) {
          state = state.copyWith(errorMessage: 'प्रति शिफ्ट मानदेय शून्य से अधिक होना चाहिए।');
          return false;
        }
        return true;

      case 3: // Step 4: Venue & Location
        if (state.reportingAddress.trim().length < 5) {
          state = state.copyWith(errorMessage: 'कृपया पूर्ण पता (Address) दर्ज करें (कम से कम 5 अक्षर)।');
          return false;
        }
        if (state.locality.trim().isEmpty) {
          state = state.copyWith(errorMessage: 'कृपया मोहल्ला या क्षेत्र (Locality) चुनें या दर्ज करें।');
          return false;
        }
        if (state.pincode.trim().length != 6) {
          state = state.copyWith(errorMessage: 'कृपया सही 6-अंकीय पिनकोड दर्ज करें।');
          return false;
        }
        return true;

      case 4: // Step 5: Perks & Requirements
        return true;

      case 5: // Step 6: Review
        return true;

      default:
        return true;
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<bool> saveDraft() async {
    if (state.businessId == null) {
      state = state.copyWith(errorMessage: 'व्यापार ID अनुपलब्ध है।');
      return false;
    }

    state = state.copyWith(isDraftSaving: true, clearError: true);
    try {
      final res = await _repository.saveJobDraft(
        jobId: state.jobId,
        businessId: state.businessId!,
        categoryId: state.categoryId ?? '',
        title: state.title.isEmpty ? 'अप्रकाशित ड्राफ्ट (Draft Job)' : state.title,
        description: state.description,
        venueName: state.venueName,
        reportingAddress: state.reportingAddress,
        locality: state.locality,
        city: state.city,
        pincode: state.pincode,
        latitude: state.latitude,
        longitude: state.longitude,
        shiftDate: _formatDate(state.shiftDate ?? DateTime.now().add(const Duration(days: 1))),
        startTime: _formatTimeOfDay(state.startTime),
        endTime: _formatTimeOfDay(state.endTime),
        isOvernight: state.isOvernight,
        workersNeeded: state.workersNeeded,
        wageAmount: state.wageAmount,
        paymentInstructions: state.paymentInstructions,
        foodProvided: state.foodProvided,
        foodDetails: state.foodDetails,
        transportProvided: state.transportProvided,
        transportDetails: state.transportDetails,
        specialInstructions: state.specialInstructions,
        skillIds: state.skillIds,
      );

      final newJobId = res['job_id'] as String?;
      state = state.copyWith(
        jobId: newJobId ?? state.jobId,
        isDraftSaving: false,
        successMessage: 'ड्राफ्ट सुरक्षित कर लिया गया है।',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isDraftSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitJob() async {
    for (int i = 0; i < 5; i++) {
      state = state.copyWith(currentStep: i);
      if (!validateCurrentStep()) return false;
    }
    state = state.copyWith(currentStep: 5);

    if (state.businessId == null) {
      state = state.copyWith(errorMessage: 'व्यापार ID अनुपलब्ध है।');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = await _repository.submitJob(
        jobId: state.jobId,
        businessId: state.businessId!,
        categoryId: state.categoryId!,
        title: state.title,
        description: state.description,
        venueName: state.venueName,
        reportingAddress: state.reportingAddress,
        locality: state.locality,
        city: state.city,
        pincode: state.pincode,
        latitude: state.latitude,
        longitude: state.longitude,
        shiftDate: _formatDate(state.shiftDate!),
        startTime: _formatTimeOfDay(state.startTime),
        endTime: _formatTimeOfDay(state.endTime),
        isOvernight: state.isOvernight,
        workersNeeded: state.workersNeeded,
        wageAmount: state.wageAmount,
        paymentInstructions: state.paymentInstructions,
        foodProvided: state.foodProvided,
        foodDetails: state.foodDetails,
        transportProvided: state.transportProvided,
        transportDetails: state.transportDetails,
        specialInstructions: state.specialInstructions,
        skillIds: state.skillIds,
      );

      state = state.copyWith(
        isSubmitting: false,
        submitResult: res,
        successMessage: res['message'] as String? ?? 'कार्य सफलतापूर्वक सबमिट हो गया है।',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}
