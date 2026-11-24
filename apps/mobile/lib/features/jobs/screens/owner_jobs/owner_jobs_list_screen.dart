import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_loaders.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../owner/presentation/owner_onboarding_notifier.dart';
import '../../models/job_model.dart';
import '../../models/job_status.dart';
import '../../presentation/owner_jobs_notifier.dart';

class OwnerJobsListScreen extends ConsumerStatefulWidget {
  const OwnerJobsListScreen({super.key});

  @override
  ConsumerState<OwnerJobsListScreen> createState() => _OwnerJobsListScreenState();
}

class _OwnerJobsListScreenState extends ConsumerState<OwnerJobsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _tabKeys = [
    'all',
    'pending_admin_approval',
    'published',
    'draft',
    'rejected',
    'expired',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabKeys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final bizAsync = ref.watch(currentOwnerBusinessProvider);

    final tabs = [
      ('all', strings.tabAll),
      ('pending_admin_approval', strings.tabPendingApproval),
      ('published', strings.tabLive),
      ('draft', strings.tabDraft),
      ('rejected', strings.tabRejected),
      ('expired', strings.tabExpired),
      ('cancelled', strings.tabCancelled),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.myJobsScreenTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(strings.postJobButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => context.push('/jobs/create'),
      ),
      body: bizAsync.when(
        data: (biz) {
          if (biz == null) {
            return Center(child: Text(strings.language == AppLanguage.hindi ? 'व्यापार प्रोफाइल उपलब्ध नहीं है।' : 'Business profile not available.'));
          }

          return Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: strings.searchMyJobsHint,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: tabs.map((tab) {
                    return _buildJobList(biz.id, tab.$1, strings);
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: AppLoader(message: strings.loadingHistory)),
        error: (e, _) => Center(child: Text('${strings.errorPrefix}$e')),
      ),
    );
  }

  Widget _buildJobList(String businessId, String status, AppStrings strings) {
    final jobsAsync = ref.watch(ownerJobsListProvider(
      (businessId: businessId, status: status, searchQuery: _searchQuery.isEmpty ? null : _searchQuery),
    ));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(ownerJobsListProvider(
          (businessId: businessId, status: status, searchQuery: _searchQuery.isEmpty ? null : _searchQuery),
        ));
      },
      child: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: EmptyStateWidget(
                  icon: Icons.work_outline_rounded,
                  title: strings.noJobsPostedTitle,
                  description: strings.noJobsPostedDesc,
                  actionLabel: _searchQuery.isNotEmpty ? strings.clearAll : strings.postJobButton,
                  onAction: () {
                    if (_searchQuery.isNotEmpty) {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    } else {
                      context.push('/jobs/create');
                    }
                  },
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: jobs.length,
            separatorBuilder: (_, _) => AppSpacing.vMd,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _buildJobCard(context, job, strings);
            },
          );
        },
        loading: () => Center(child: AppLoader(message: strings.loadingHistory)),
        error: (e, _) => Center(child: Text('${strings.errorPrefix}$e')),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job, AppStrings strings) {
    final isHindi = strings.language == AppLanguage.hindi;

    return AppCard(
      onTap: () => context.push('/jobs/detail/${job.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.categoryName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              _buildStatusBadge(job, strings),
            ],
          ),
          AppSpacing.vXs,
          Text(
            job.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          AppSpacing.vXs,
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${job.shiftDate} • ${job.formattedShiftTime}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          AppSpacing.vXs,
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${job.locality}, ${job.city}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${job.wageAmount.toStringAsFixed(0)} ${isHindi ? '/ शिफ्ट' : '/ Shift'}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.success),
              ),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    strings.workersNeeded(job.workersNeeded),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(JobModel job, AppStrings strings) {
    if (job.isExpired) {
      return AppBadge.neutral(label: strings.tabExpired);
    }
    switch (job.status) {
      case JobStatus.published:
        return AppBadge.success(label: strings.tabLive);
      case JobStatus.pendingAdminApproval:
        return AppBadge.pending(label: strings.tabPendingApproval);
      case JobStatus.draft:
        return AppBadge.neutral(label: strings.tabDraft);
      case JobStatus.rejected:
        return AppBadge.error(label: strings.tabRejected);
      case JobStatus.cancelled:
        return AppBadge.error(label: strings.tabCancelled);
      default:
        return AppBadge.neutral(label: job.status.displayNameFor(strings.language));
    }
  }
}
