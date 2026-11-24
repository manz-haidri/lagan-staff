import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/job_repository.dart';
import '../models/job_model.dart';

class OwnerJobsFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String status) => state = status;
}

final ownerJobsFilterProvider =
    NotifierProvider<OwnerJobsFilterNotifier, String>(OwnerJobsFilterNotifier.new);

typedef OwnerJobsParams = ({String businessId, String status, String? searchQuery});

final ownerJobsListProvider = FutureProvider.family<List<JobModel>, OwnerJobsParams>(
  (ref, params) async {
    final repo = ref.watch(jobRepositoryProvider);
    return repo.getOwnerJobs(
      businessId: params.businessId,
      statusFilter: params.status,
      searchQuery: params.searchQuery,
    );
  },
);

final jobDetailProvider = FutureProvider.family<JobModel, String>(
  (ref, jobId) async {
    final repo = ref.watch(jobRepositoryProvider);
    return repo.getJobDetail(jobId);
  },
);
