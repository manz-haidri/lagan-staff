import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_loaders.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/booking_model.dart';
import '../presentation/attendance_providers.dart';

class WorkerWorkHistoryScreen extends ConsumerStatefulWidget {
  const WorkerWorkHistoryScreen({super.key});

  @override
  ConsumerState<WorkerWorkHistoryScreen> createState() => _WorkerWorkHistoryScreenState();
}

class _WorkerWorkHistoryScreenState extends ConsumerState<WorkerWorkHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _filterKeys = ['all', 'completed', 'cancelled', 'history'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterKeys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    final tabs = [
      ('all', strings.tabAll),
      ('completed', strings.tabCompleted),
      ('cancelled', strings.tabCancelled),
      ('history', strings.tabPastShifts),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          strings.workHistoryScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [
          LanguageSelectorButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((t) => _buildHistoryList(t.$1, strings)).toList(),
      ),
    );
  }

  Widget _buildHistoryList(String filter, AppStrings strings) {
    final historyAsync = ref.watch(workerBookingsProvider(filter));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(workerBookingsProvider(filter)),
      child: historyAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: strings.noWorkHistoryTitle,
                  description: strings.noWorkHistoryDesc,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: records.length,
            separatorBuilder: (_, _) => AppSpacing.vMd,
            itemBuilder: (context, index) {
              final b = records[index];
              return _buildHistoryCard(b, strings);
            },
          );
        },
        loading: () => Center(child: AppLoader(message: strings.loadingHistory)),
        error: (e, _) => Center(child: Text('${strings.errorPrefix}$e')),
      ),
    );
  }

  Widget _buildHistoryCard(BookingModel b, AppStrings strings) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.categoryName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              _buildStatusBadge(b, strings),
            ],
          ),
          AppSpacing.vXs,
          Text(
            b.jobTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          AppSpacing.vXs,
          Text(
            '${strings.hostLabel}${b.businessName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 20),

          // Shift date & timing
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                '${b.shiftDate} • ${b.startTime}${strings.toTime}${b.endTime}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          AppSpacing.vXs,

          // Reporting Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${b.venueName != null ? '${b.venueName}, ' : ''}${b.locality}, ${b.city}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.vXs,

          // Agreed Wage (Explicit Non-Payment Disclaimer)
          Row(
            children: [
              const Icon(Icons.currency_rupee_rounded, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.agreedWagePaidByHost(b.agreedWage.toInt()),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingModel b, AppStrings strings) {
    if (b.isCompleted) {
      return AppBadge.success(label: strings.statusCompleted);
    }
    if (b.isCancelled) {
      return AppBadge.error(label: strings.tabCancelled);
    }
    if (b.attendanceStatus == AttendanceStatus.absent) {
      return AppBadge.error(label: AttendanceStatus.absent.displayNameFor(strings.language));
    }
    if (b.attendanceStatus == AttendanceStatus.noShow) {
      return AppBadge.neutral(label: AttendanceStatus.noShow.displayNameFor(strings.language));
    }
    if (b.isPresent) {
      return AppBadge.success(label: strings.statusPresent);
    }
    return AppBadge.neutral(label: b.bookingStatus.displayNameFor(strings.language));
  }
}
