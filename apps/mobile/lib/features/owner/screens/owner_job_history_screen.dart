import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_loaders.dart';
import '../../../core/widgets/empty_state.dart';
import '../presentation/owner_onboarding_notifier.dart';

class OwnerJobHistoryScreen extends ConsumerStatefulWidget {
  const OwnerJobHistoryScreen({super.key});

  @override
  ConsumerState<OwnerJobHistoryScreen> createState() =>
      _OwnerJobHistoryScreenState();
}

class _OwnerJobHistoryScreenState extends ConsumerState<OwnerJobHistoryScreen> {
  String _selectedFilter = 'all';

  List<(String, String)> _getFilterOptions(AppStrings strings) => [
    ('all', strings.filterAll),
    ('published', strings.filterPublished),
    ('completed', strings.filterCompleted),
    ('cancelled', strings.filterCancelled),
  ];

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(currentOwnerBusinessProvider);
    final strings = ref.watch(stringsProvider);
    final filterOptions = _getFilterOptions(strings);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.ownerJobHistoryTitle),
        actions: const [
          LanguageSelectorButton(),
          SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: businessAsync.when(
          data: (biz) {
            if (biz == null) {
              return EmptyStateWidget(
                icon: Icons.storefront_outlined,
                title: strings.businessProfileIncomplete,
                description: strings.businessProfileIncompleteDesc,
                actionLabel: strings.setupBusinessButton,
                onAction: () => context.push('/owner/onboarding'),
              );
            }

            return Column(
              children: [
                // Filter Chips Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.surface,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((opt) {
                        final key = opt.$1;
                        final label = opt.$2;
                        final isSelected = _selectedFilter == key;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceMuted,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedFilter = key;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Jobs List
                Expanded(
                  child: _buildJobsList(
                    biz.id,
                    strings,
                    statusFilter: _selectedFilter == 'all' ? null : _selectedFilter,
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: AppLoader(message: strings.loading),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e'),
          ),
        ),
      ),
    );
  }

  Widget _buildJobsList(String businessId, AppStrings strings, {String? statusFilter}) {
    final historyAsync = ref.watch(ownerJobHistoryProvider(
      (businessId: businessId, status: statusFilter),
    ));

    return historyAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history_rounded,
            title: strings.noJobHistoryTitle,
            description: strings.noJobHistoryDesc,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(ownerJobHistoryProvider);
          },
          child: ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.categoryName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            '₹${job.wageAmount.toStringAsFixed(0)} ${job.wageRateUnitFor(strings.language)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vSm,
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.vXs,
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.reportingAddress,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vXs,
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${job.shiftDate} • ${job.startTime} - ${job.endTime}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.workersConfirmedCount(job.workersConfirmed, job.workersNeeded),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppBadge.neutral(label: job.statusDisplayNameFor(strings.language)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: AppLoader(message: strings.loading),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e'),
      ),
    );
  }
}
