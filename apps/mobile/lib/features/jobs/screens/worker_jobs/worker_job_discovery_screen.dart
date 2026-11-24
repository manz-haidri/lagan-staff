import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_loaders.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../models/job_filter_model.dart';
import '../../models/job_model.dart';
import '../../presentation/job_form_notifier.dart';
import '../../presentation/worker_jobs_notifier.dart';

class WorkerJobDiscoveryScreen extends ConsumerStatefulWidget {
  const WorkerJobDiscoveryScreen({super.key});

  @override
  ConsumerState<WorkerJobDiscoveryScreen> createState() => _WorkerJobDiscoveryScreenState();
}

class _WorkerJobDiscoveryScreenState extends ConsumerState<WorkerJobDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final workerState = ref.watch(workerJobsNotifierProvider);
    final workerNotifier = ref.read(workerJobsNotifierProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.availableJobsScreenTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          const LanguageSelectorButton(),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: strings.filtersTooltip,
                onPressed: () => _showFilterBottomSheet(context, ref, strings),
              ),
              if (workerState.filter.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${workerState.filter.activeFiltersCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: strings.refresh,
            onPressed: () => workerNotifier.loadJobs(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: strings.searchJobsHint,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            workerNotifier.updateSearchQuery(null);
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (val) {
                  setState(() {});
                  workerNotifier.updateSearchQuery(val.trim());
                },
              ),
            ),

            // Filter Chips Bar (Quick Category Filter)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white,
              child: categoriesAsync.when(
                data: (cats) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(strings.allCategories),
                          selected: workerState.filter.categoryId == null,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: workerState.filter.categoryId == null ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: workerState.filter.categoryId == null ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (_) => workerNotifier.updateCategory(null),
                        ),
                      ),
                      ...cats.map((cat) {
                        final isSelected = workerState.filter.categoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            onSelected: (_) => workerNotifier.updateCategory(isSelected ? null : cat.id),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // Active Filter Strip
            if (workerState.filter.hasActiveFilters) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      strings.filtersActive(workerState.filter.activeFiltersCount),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        workerNotifier.clearFilters();
                      },
                      child: Text(strings.clearAll, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],

            // Main Feed
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => workerNotifier.loadJobs(refresh: true),
                child: workerState.isLoading && workerState.jobs.isEmpty
                    ? Center(child: AppLoader(message: strings.searchingJobs))
                    : workerState.jobs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: AppSpacing.pagePadding,
                              child: EmptyStateWidget(
                                icon: Icons.event_busy_rounded,
                                title: strings.noJobsFoundTitle,
                                description: strings.noJobsFoundDesc,
                                actionLabel: workerState.filter.hasActiveFilters ? strings.clearAll : null,
                                onAction: workerState.filter.hasActiveFilters
                                    ? () {
                                        _searchController.clear();
                                        workerNotifier.clearFilters();
                                      }
                                    : null,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: AppSpacing.pagePadding,
                            itemCount: workerState.jobs.length + (workerState.hasMore ? 1 : 0),
                            separatorBuilder: (_, _) => AppSpacing.vMd,
                            itemBuilder: (context, index) {
                              if (index == workerState.jobs.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: AppSecondaryButton(
                                      label: strings.language == AppLanguage.hindi ? 'और कार्य लोड करें' : 'Load More Jobs',
                                      icon: Icons.expand_more_rounded,
                                      onPressed: () => workerNotifier.loadJobs(),
                                    ),
                                  ),
                                );
                              }

                              final job = workerState.jobs[index];
                              return _buildWorkerJobCard(context, job, strings);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerJobCard(BuildContext context, JobModel job, AppStrings strings) {
    final isHindi = strings.language == AppLanguage.hindi;

    return AppCard(
      onTap: () => context.push('/worker/jobs/${job.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job.businessName ?? (isHindi ? 'सत्यापित आयोजक' : 'Verified Host'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${job.wageAmount.toStringAsFixed(0)} ${isHindi ? '/ शिफ्ट' : '/ Shift'}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
              ),
            ],
          ),
          AppSpacing.vXs,
          Text(
            job.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          AppSpacing.vSm,

          // Timing & Date
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${job.shiftDate} • ${job.formattedShiftTime}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          AppSpacing.vXs,

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${job.venueName != null && job.venueName!.isNotEmpty ? '${job.venueName}, ' : ''}${job.locality}, ${job.city}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.vSm,

          // Required Skills Chips
          if (job.skills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: job.skills.take(3).map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    s.name,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
            AppSpacing.vSm,
          ],

          const Divider(height: 16),

          // Perks & Availability Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (job.foodProvided) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_rounded, size: 12, color: AppColors.info),
                          const SizedBox(width: 2),
                          Text(
                            isHindi ? 'भोजन' : 'Food',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (job.transportProvided) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_bus_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            isHindi ? 'वाहन' : 'Transport',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      job.availabilityStatusLabelFor(strings.language),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref, AppStrings strings) {
    final currentFilter = ref.read(workerJobsNotifierProvider).filter;
    final workerNotifier = ref.read(workerJobsNotifierProvider.notifier);
    final isHindi = strings.language == AppLanguage.hindi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        String? selectedCity = currentFilter.city;
        String? selectedLocality = currentFilter.locality;
        String? selectedShiftType = currentFilter.shiftType;
        String selectedDatePreset = 'all';
        DateTime? customDate = currentFilter.shiftDate;
        DateTime? customStartDate = currentFilter.startDate;
        DateTime? customEndDate = currentFilter.endDate;
        double minWage = currentFilter.minWage ?? 300.0;
        bool? food = currentFilter.foodProvided;
        bool? transport = currentFilter.transportProvided;

        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        if (currentFilter.shiftDate != null) {
          final filterDateStr = "${currentFilter.shiftDate!.year}-${currentFilter.shiftDate!.month.toString().padLeft(2, '0')}-${currentFilter.shiftDate!.day.toString().padLeft(2, '0')}";
          if (filterDateStr == todayStr) {
            selectedDatePreset = 'today';
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final cities = [
              ('all', isHindi ? 'सभी तहसीलें / शहर' : 'All Tehsils / Cities'),
              ('Ghazipur', isHindi ? 'गाजीपुर सदर' : 'Ghazipur Sadar'),
              ('Saidpur', isHindi ? 'सैदपुर' : 'Saidpur'),
              ('Zamania', isHindi ? 'जमानिया' : 'Zamania'),
              ('Mohammadabad', isHindi ? 'मोहम्मदाबाद' : 'Mohammadabad'),
            ];

            final localities = [
              'Lanka',
              'Ravindrapuri',
              'Station Road',
              'Mishra Bazar',
              'Gora Bazar',
              'Rauza',
              'Zamania',
              'Mohammadabad',
              'Saidpur',
            ];

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'फ़िल्टर विकल्प' : 'Filter Options',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const Divider(),

                    // City / Tehsil Filter
                    Text(
                      isHindi ? 'तहसील / नगर:' : 'City / Tehsil:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vXs,
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: cities.map((c) {
                        final isSelected = (selectedCity == null && c.$1 == 'all') || (selectedCity == c.$1);
                        return ChoiceChip(
                          label: Text(c.$2),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              selectedCity = selected ? (c.$1 == 'all' ? null : c.$1) : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    AppSpacing.vMd,

                    // Locality Filter
                    Text(
                      isHindi ? 'गाजीपुर क्षेत्र / मुहल्ला:' : 'Ghazipur Area / Locality:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vXs,
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: localities.map((loc) {
                        final isSelected = selectedLocality == loc;
                        return ChoiceChip(
                          label: Text(loc),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              selectedLocality = selected ? loc : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    AppSpacing.vMd,

                    // Date Selection Filter
                    Text(
                      isHindi ? 'तारीख:' : 'Shift Date:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vXs,
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(isHindi ? 'सभी तिथियां' : 'All Dates'),
                          selected: selectedDatePreset == 'all',
                          onSelected: (s) {
                            setModalState(() {
                              selectedDatePreset = 'all';
                              customDate = null;
                              customStartDate = null;
                              customEndDate = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(isHindi ? 'आज' : 'Today'),
                          selected: selectedDatePreset == 'today',
                          onSelected: (s) {
                            setModalState(() {
                              selectedDatePreset = 'today';
                              final today = DateTime.now();
                              customDate = DateTime(today.year, today.month, today.day);
                              customStartDate = null;
                              customEndDate = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(isHindi ? 'कल' : 'Tomorrow'),
                          selected: selectedDatePreset == 'tomorrow',
                          onSelected: (s) {
                            setModalState(() {
                              selectedDatePreset = 'tomorrow';
                              final tmrw = DateTime.now().add(const Duration(days: 1));
                              customDate = DateTime(tmrw.year, tmrw.month, tmrw.day);
                              customStartDate = null;
                              customEndDate = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(isHindi ? 'इस सप्ताह' : 'This Week'),
                          selected: selectedDatePreset == 'week',
                          onSelected: (s) {
                            setModalState(() {
                              selectedDatePreset = 'week';
                              final today = DateTime.now();
                              customDate = null;
                              customStartDate = DateTime(today.year, today.month, today.day);
                              customEndDate = DateTime(today.year, today.month, today.day).add(const Duration(days: 7));
                            });
                          },
                        ),
                      ],
                    ),
                    AppSpacing.vMd,

                    // Shift Timing Filter
                    Text(
                      isHindi ? 'शिफ्ट का समय:' : 'Shift Timing:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vXs,
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(isHindi ? 'सभी' : 'All'),
                          selected: selectedShiftType == null || selectedShiftType == 'all',
                          onSelected: (_) => setModalState(() => selectedShiftType = null),
                        ),
                        ChoiceChip(
                          label: Text(isHindi ? 'सुबह (5-12)' : 'Morning (5-12)'),
                          selected: selectedShiftType == 'morning',
                          onSelected: (s) => setModalState(() => selectedShiftType = s ? 'morning' : null),
                        ),
                        ChoiceChip(
                          label: Text(isHindi ? 'दोपहर/शाम (12-18)' : 'Evening (12-18)'),
                          selected: selectedShiftType == 'evening',
                          onSelected: (s) => setModalState(() => selectedShiftType = s ? 'evening' : null),
                        ),
                        ChoiceChip(
                          label: Text(isHindi ? 'रात (18+)' : 'Night (18+)'),
                          selected: selectedShiftType == 'night',
                          onSelected: (s) => setModalState(() => selectedShiftType = s ? 'night' : null),
                        ),
                      ],
                    ),
                    AppSpacing.vMd,

                    // Minimum Wage Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'न्यूनतम मानदेय:' : 'Minimum Wage:',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '₹${minWage.toInt()} ${isHindi ? '/ शिफ्ट' : '/ Shift'}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
                        ),
                      ],
                    ),
                    Slider(
                      value: minWage,
                      min: 300,
                      max: 1200,
                      divisions: 9,
                      activeColor: AppColors.success,
                      label: '₹${minWage.toInt()}',
                      onChanged: (val) {
                        setModalState(() => minWage = val);
                      },
                    ),
                    AppSpacing.vSm,

                    // Perks
                    Text(
                      isHindi ? 'सुविधाएं:' : 'Perks:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        FilterChip(
                          label: Text(isHindi ? 'भोजन सहित' : 'Food Provided'),
                          selected: food == true,
                          onSelected: (val) {
                            setModalState(() => food = val ? true : null);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(isHindi ? 'वाहन सुविधा' : 'Transport Provided'),
                          selected: transport == true,
                          onSelected: (val) {
                            setModalState(() => transport = val ? true : null);
                          },
                        ),
                      ],
                    ),
                    AppSpacing.vLg,

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            label: isHindi ? 'रीसेट' : 'Reset',
                            onPressed: () {
                              workerNotifier.clearFilters();
                              Navigator.pop(bottomSheetContext);
                            },
                          ),
                        ),
                        AppSpacing.hMd,
                        Expanded(
                          flex: 2,
                          child: AppPrimaryButton(
                            label: isHindi ? 'फ़िल्टर लागू करें' : 'Apply Filters',
                            onPressed: () {
                              workerNotifier.updateFilter(
                                JobFilterModel(
                                  searchQuery: currentFilter.searchQuery,
                                  categoryId: currentFilter.categoryId,
                                  city: selectedCity,
                                  locality: selectedLocality,
                                  shiftDate: customDate,
                                  startDate: customStartDate,
                                  endDate: customEndDate,
                                  shiftType: selectedShiftType,
                                  minWage: minWage > 300 ? minWage : null,
                                  foodProvided: food,
                                  transportProvided: transport,
                                  skillIds: currentFilter.skillIds,
                                ),
                              );
                              Navigator.pop(bottomSheetContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
