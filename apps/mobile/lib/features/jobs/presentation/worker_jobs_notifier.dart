import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/job_repository.dart';
import '../models/job_filter_model.dart';
import '../models/job_model.dart';

class WorkerJobsState {
  final List<JobModel> jobs;
  final JobFilterModel filter;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final bool hasMore;
  final int offset;

  const WorkerJobsState({
    this.jobs = const [],
    this.filter = JobFilterModel.empty,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.hasMore = true,
    this.offset = 0,
  });

  WorkerJobsState copyWith({
    List<JobModel>? jobs,
    JobFilterModel? filter,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    bool? hasMore,
    int? offset,
  }) {
    return WorkerJobsState(
      jobs: jobs ?? this.jobs,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

final workerJobsNotifierProvider =
    NotifierProvider<WorkerJobsNotifier, WorkerJobsState>(WorkerJobsNotifier.new);

class WorkerJobsNotifier extends Notifier<WorkerJobsState> {
  late final JobRepository _repository;
  static const int _pageSize = 20;

  @override
  WorkerJobsState build() {
    _repository = ref.read(jobRepositoryProvider);
    Future.microtask(() => loadJobs());
    return const WorkerJobsState();
  }

  Future<void> loadJobs({bool refresh = false}) async {
    if (state.isLoading || state.isRefreshing) return;

    if (refresh) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final currentOffset = refresh ? 0 : state.offset;
      final newJobs = await _repository.getAvailableJobsForWorker(
        filter: state.filter,
        limit: _pageSize,
        offset: currentOffset,
      );

      final updatedJobs = refresh ? newJobs : [...state.jobs, ...newJobs];

      state = state.copyWith(
        jobs: updatedJobs,
        isLoading: false,
        isRefreshing: false,
        hasMore: newJobs.length >= _pageSize,
        offset: currentOffset + newJobs.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: 'उपलब्ध कार्य लोड करने में विफल: $e',
      );
    }
  }

  void updateFilter(JobFilterModel newFilter) {
    state = state.copyWith(filter: newFilter);
    loadJobs(refresh: true);
  }

  void updateSearchQuery(String? query) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        searchQuery: query,
        clearSearch: query == null || query.trim().isEmpty,
      ),
    );
    loadJobs(refresh: true);
  }

  void updateCategory(String? categoryId) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        categoryId: categoryId,
        clearCategory: categoryId == null,
      ),
    );
    loadJobs(refresh: true);
  }

  void updateCity(String? city) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        city: city,
        clearCity: city == null || city == 'all',
      ),
    );
    loadJobs(refresh: true);
  }

  void updateLocality(String? locality) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        locality: locality,
        clearLocality: locality == null || locality == 'all',
      ),
    );
    loadJobs(refresh: true);
  }

  void updateShiftType(String? shiftType) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        shiftType: shiftType,
        clearShiftType: shiftType == null || shiftType == 'all',
      ),
    );
    loadJobs(refresh: true);
  }

  void updateDate(DateTime? date) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        shiftDate: date,
        clearDate: date == null,
      ),
    );
    loadJobs(refresh: true);
  }

  void updateDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        startDate: start,
        clearStartDate: start == null,
        endDate: end,
        clearEndDate: end == null,
      ),
    );
    loadJobs(refresh: true);
  }

  void updateWageFilter(double? min, double? max) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        minWage: min,
        maxWage: max,
        clearWage: min == null && max == null,
      ),
    );
    loadJobs(refresh: true);
  }

  void updatePerks({bool? food, bool? transport}) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        foodProvided: food,
        clearFood: food == null,
        transportProvided: transport,
        clearTransport: transport == null,
      ),
    );
    loadJobs(refresh: true);
  }

  void updateSkills(List<String> skillIds) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        skillIds: skillIds,
      ),
    );
    loadJobs(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(filter: JobFilterModel.empty);
    loadJobs(refresh: true);
  }
}
