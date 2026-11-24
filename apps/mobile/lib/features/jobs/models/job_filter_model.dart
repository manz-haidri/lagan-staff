class JobFilterModel {
  final String? searchQuery;
  final String? categoryId;
  final String? city;
  final String? locality;
  final DateTime? shiftDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? shiftType; // 'all', 'morning', 'evening', 'night'
  final double? minWage;
  final double? maxWage;
  final bool? foodProvided;
  final bool? transportProvided;
  final List<String> skillIds;

  const JobFilterModel({
    this.searchQuery,
    this.categoryId,
    this.city,
    this.locality,
    this.shiftDate,
    this.startDate,
    this.endDate,
    this.shiftType,
    this.minWage,
    this.maxWage,
    this.foodProvided,
    this.transportProvided,
    this.skillIds = const [],
  });

  bool get hasActiveFilters =>
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      categoryId != null ||
      (city != null && city!.isNotEmpty && city != 'all') ||
      (locality != null && locality!.isNotEmpty && locality != 'all') ||
      shiftDate != null ||
      startDate != null ||
      endDate != null ||
      (shiftType != null && shiftType != 'all') ||
      minWage != null ||
      maxWage != null ||
      foodProvided != null ||
      transportProvided != null ||
      skillIds.isNotEmpty;

  int get activeFiltersCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) count++;
    if (categoryId != null) count++;
    if (city != null && city!.isNotEmpty && city != 'all') count++;
    if (locality != null && locality!.isNotEmpty && locality != 'all') count++;
    if (shiftDate != null) count++;
    if (startDate != null || endDate != null) count++;
    if (shiftType != null && shiftType != 'all') count++;
    if (minWage != null || maxWage != null) count++;
    if (foodProvided != null) count++;
    if (transportProvided != null) count++;
    if (skillIds.isNotEmpty) count++;
    return count;
  }

  JobFilterModel copyWith({
    String? searchQuery,
    bool clearSearch = false,
    String? categoryId,
    bool clearCategory = false,
    String? city,
    bool clearCity = false,
    String? locality,
    bool clearLocality = false,
    DateTime? shiftDate,
    bool clearDate = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? shiftType,
    bool clearShiftType = false,
    double? minWage,
    double? maxWage,
    bool clearWage = false,
    bool? foodProvided,
    bool clearFood = false,
    bool? transportProvided,
    bool clearTransport = false,
    List<String>? skillIds,
  }) {
    return JobFilterModel(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      city: clearCity ? null : (city ?? this.city),
      locality: clearLocality ? null : (locality ?? this.locality),
      shiftDate: clearDate ? null : (shiftDate ?? this.shiftDate),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      shiftType: clearShiftType ? null : (shiftType ?? this.shiftType),
      minWage: clearWage ? null : (minWage ?? this.minWage),
      maxWage: clearWage ? null : (maxWage ?? this.maxWage),
      foodProvided: clearFood ? null : (foodProvided ?? this.foodProvided),
      transportProvided: clearTransport ? null : (transportProvided ?? this.transportProvided),
      skillIds: skillIds ?? this.skillIds,
    );
  }

  static const JobFilterModel empty = JobFilterModel();
}
