import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/job_filter_model.dart';
import '../models/job_model.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(Supabase.instance.client);
});

class JobRepository {
  final SupabaseClient _supabase;

  JobRepository(this._supabase);

  /// Fetch all worker categories
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name, slug, description')
          .order('name');

      return (response as List)
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback local categories if table not seeded
      return const [
        CategoryModel(id: 'cat-waiters', name: 'वेटर (Waiters)', slug: 'waiters'),
        CategoryModel(id: 'cat-cleaners', name: 'सफाई कर्मी (Cleaners)', slug: 'cleaners'),
        CategoryModel(id: 'cat-halwai', name: 'हलवाई हेल्पर (Halwai Helpers)', slug: 'halwai_helpers'),
        CategoryModel(id: 'cat-loaders', name: 'लोडर / सामान ढुलाई (Loaders)', slug: 'loaders'),
        CategoryModel(id: 'cat-event', name: 'इवेंट हेल्पर (Event Helpers)', slug: 'event_helpers'),
        CategoryModel(id: 'cat-other', name: 'अन्य कार्य (Other Workers)', slug: 'other'),
      ];
    }
  }

  /// Fetch skills, optionally filtered by category
  Future<List<SkillModel>> fetchSkills({String? categoryId}) async {
    try {
      var query = _supabase.from('skills').select('id, category_id, name');
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      final response = await query.order('name');
      return (response as List)
          .map((item) => SkillModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save or update a job draft
  Future<Map<String, dynamic>> saveJobDraft({
    String? jobId,
    required String businessId,
    required String categoryId,
    required String title,
    String? description,
    String? venueName,
    required String reportingAddress,
    required String locality,
    String city = 'Ghazipur',
    String pincode = '233001',
    double? latitude,
    double? longitude,
    required String shiftDate,
    required String startTime,
    required String endTime,
    bool isOvernight = false,
    required int workersNeeded,
    required double wageAmount,
    String? paymentInstructions,
    bool foodProvided = false,
    String? foodDetails,
    bool transportProvided = false,
    String? transportDetails,
    String? specialInstructions,
    List<String> skillIds = const [],
  }) async {
    try {
      final res = await _supabase.rpc('save_job_draft', params: {
        'p_job_id': jobId,
        'p_business_id': businessId,
        'p_category_id': categoryId,
        'p_title': title,
        'p_description': description,
        'p_venue_name': venueName,
        'p_reporting_address': reportingAddress,
        'p_locality': locality,
        'p_city': city,
        'p_pincode': pincode,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_shift_date': shiftDate,
        'p_start_time': startTime,
        'p_end_time': endTime,
        'p_is_overnight': isOvernight,
        'p_workers_needed': workersNeeded,
        'p_wage_amount': wageAmount,
        'p_payment_instructions': paymentInstructions,
        'p_food_provided': foodProvided,
        'p_food_details': foodDetails,
        'p_transport_provided': transportProvided,
        'p_transport_details': transportDetails,
        'p_special_instructions': specialInstructions,
        'p_skill_ids': skillIds,
      });

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw Exception('ड्राफ्ट सुरक्षित करने में त्रुटि: $e');
    }
  }

  /// Submit job for publishing or first-job administrative review
  Future<Map<String, dynamic>> submitJob({
    String? jobId,
    required String businessId,
    required String categoryId,
    required String title,
    String? description,
    String? venueName,
    required String reportingAddress,
    required String locality,
    String city = 'Ghazipur',
    String pincode = '233001',
    double? latitude,
    double? longitude,
    required String shiftDate,
    required String startTime,
    required String endTime,
    bool isOvernight = false,
    required int workersNeeded,
    required double wageAmount,
    String? paymentInstructions,
    bool foodProvided = false,
    String? foodDetails,
    bool transportProvided = false,
    String? transportDetails,
    String? specialInstructions,
    List<String> skillIds = const [],
  }) async {
    try {
      final res = await _supabase.rpc('submit_job', params: {
        'p_job_id': jobId,
        'p_business_id': businessId,
        'p_category_id': categoryId,
        'p_title': title,
        'p_description': description,
        'p_venue_name': venueName,
        'p_reporting_address': reportingAddress,
        'p_locality': locality,
        'p_city': city,
        'p_pincode': pincode,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_shift_date': shiftDate,
        'p_start_time': startTime,
        'p_end_time': endTime,
        'p_is_overnight': isOvernight,
        'p_workers_needed': workersNeeded,
        'p_wage_amount': wageAmount,
        'p_payment_instructions': paymentInstructions,
        'p_food_provided': foodProvided,
        'p_food_details': foodDetails,
        'p_transport_provided': transportProvided,
        'p_transport_details': transportDetails,
        'p_special_instructions': specialInstructions,
        'p_skill_ids': skillIds,
      });

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw Exception('कार्य सबमिट करने में विफल: $e');
    }
  }

  /// Cancel a job with reason and audit trail
  Future<void> cancelJob(String jobId, {String? reason}) async {
    try {
      await _supabase.rpc('owner_cancel_job', params: {
        'p_job_id': jobId,
        'p_cancellation_reason': reason,
      });
    } catch (e) {
      throw Exception('कार्य रद्द करने में त्रुटि: $e');
    }
  }

  /// Safely update non-critical details on a published job without re-triggering approval
  Future<Map<String, dynamic>> updatePublishedJob({
    required String jobId,
    String? description,
    String? venueName,
    String? reportingAddress,
    String? locality,
    String? paymentInstructions,
    bool? foodProvided,
    String? foodDetails,
    bool? transportProvided,
    String? transportDetails,
    String? specialInstructions,
  }) async {
    try {
      final res = await _supabase.rpc('update_published_job', params: {
        'p_job_id': jobId,
        'p_description': description,
        'p_venue_name': venueName,
        'p_reporting_address': reportingAddress,
        'p_locality': locality,
        'p_payment_instructions': paymentInstructions,
        'p_food_provided': foodProvided,
        'p_food_details': foodDetails,
        'p_transport_provided': transportProvided,
        'p_transport_details': transportDetails,
        'p_special_instructions': specialInstructions,
      });

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw Exception('प्रकाशित कार्य अपडेट करने में त्रुटि: $e');
    }
  }

  /// Retrieve jobs for an owner's business with search and expired support
  Future<List<JobModel>> getOwnerJobs({
    required String businessId,
    String? statusFilter,
    String? searchQuery,
    int limit = 40,
    int offset = 0,
  }) async {
    try {
      final res = await _supabase.rpc('get_owner_jobs', params: {
        'p_business_id': businessId,
        'p_status_filter': statusFilter == null || statusFilter.isEmpty ? 'all' : statusFilter,
        'p_search_query': searchQuery?.trim().isEmpty ?? true ? null : searchQuery!.trim(),
        'p_limit': limit,
        'p_offset': offset,
      });

      return (res as List)
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Direct table query fallback
      var query = _supabase
          .from('jobs')
          .select('*, categories(name), businesses(name, locality)')
          .eq('business_id', businessId);

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      if (statusFilter == 'expired') {
        query = query.eq('status', 'published').lt('shift_date', todayStr);
      } else if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.or('title.ilike.%${searchQuery.trim()}%,venue_name.ilike.%${searchQuery.trim()}%,locality.ilike.%${searchQuery.trim()}%');
      }

      final res = await query.order('created_at', ascending: false).limit(limit);
      return (res as List)
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  /// Retrieve available published jobs for active workers with comprehensive multi-attribute filtering
  Future<List<JobModel>> getAvailableJobsForWorker({
    JobFilterModel filter = JobFilterModel.empty,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final formattedDate = filter.shiftDate != null
          ? "${filter.shiftDate!.year.toString().padLeft(4, '0')}-${filter.shiftDate!.month.toString().padLeft(2, '0')}-${filter.shiftDate!.day.toString().padLeft(2, '0')}"
          : null;

      final formattedStartDate = filter.startDate != null
          ? "${filter.startDate!.year.toString().padLeft(4, '0')}-${filter.startDate!.month.toString().padLeft(2, '0')}-${filter.startDate!.day.toString().padLeft(2, '0')}"
          : null;

      final formattedEndDate = filter.endDate != null
          ? "${filter.endDate!.year.toString().padLeft(4, '0')}-${filter.endDate!.month.toString().padLeft(2, '0')}-${filter.endDate!.day.toString().padLeft(2, '0')}"
          : null;

      final res = await _supabase.rpc('get_available_jobs_for_worker', params: {
        'p_search_query': filter.searchQuery?.trim().isEmpty ?? true ? null : filter.searchQuery!.trim(),
        'p_category_id': filter.categoryId,
        'p_city': (filter.city == null || filter.city == 'all') ? null : filter.city,
        'p_locality': (filter.locality == null || filter.locality == 'all') ? null : filter.locality,
        'p_shift_date': formattedDate,
        'p_start_date': formattedStartDate,
        'p_end_date': formattedEndDate,
        'p_shift_type': (filter.shiftType == null || filter.shiftType == 'all') ? null : filter.shiftType,
        'p_min_wage': filter.minWage,
        'p_max_wage': filter.maxWage,
        'p_food_provided': filter.foodProvided,
        'p_transport_provided': filter.transportProvided,
        'p_skill_ids': filter.skillIds.isEmpty ? null : filter.skillIds,
        'p_limit': limit,
        'p_offset': offset,
      });

      return (res as List)
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback query directly on published jobs
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      var query = _supabase
          .from('jobs')
          .select('*, categories(name), businesses(name, locality)')
          .eq('status', 'published')
          .gte('shift_date', todayStr);

      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        query = query.or('title.ilike.%${filter.searchQuery!.trim()}%,venue_name.ilike.%${filter.searchQuery!.trim()}%,locality.ilike.%${filter.searchQuery!.trim()}%');
      }
      if (filter.categoryId != null) {
        query = query.eq('category_id', filter.categoryId!);
      }
      if (filter.city != null && filter.city!.isNotEmpty && filter.city != 'all') {
        query = query.ilike('city', '%${filter.city}%');
      }
      if (filter.locality != null && filter.locality!.isNotEmpty && filter.locality != 'all') {
        query = query.ilike('locality', '%${filter.locality}%');
      }
      if (filter.shiftDate != null) {
        final d = "${filter.shiftDate!.year.toString().padLeft(4, '0')}-${filter.shiftDate!.month.toString().padLeft(2, '0')}-${filter.shiftDate!.day.toString().padLeft(2, '0')}";
        query = query.eq('shift_date', d);
      }
      if (filter.startDate != null) {
        final d = "${filter.startDate!.year.toString().padLeft(4, '0')}-${filter.startDate!.month.toString().padLeft(2, '0')}-${filter.startDate!.day.toString().padLeft(2, '0')}";
        query = query.gte('shift_date', d);
      }
      if (filter.endDate != null) {
        final d = "${filter.endDate!.year.toString().padLeft(4, '0')}-${filter.endDate!.month.toString().padLeft(2, '0')}-${filter.endDate!.day.toString().padLeft(2, '0')}";
        query = query.lte('shift_date', d);
      }
      if (filter.minWage != null) {
        query = query.gte('wage_amount', filter.minWage!);
      }
      if (filter.maxWage != null) {
        query = query.lte('wage_amount', filter.maxWage!);
      }
      if (filter.foodProvided != null) {
        query = query.eq('food_provided', filter.foodProvided!);
      }
      if (filter.transportProvided != null) {
        query = query.eq('transport_provided', filter.transportProvided!);
      }

      final res = await query
          .order('shift_date', ascending: true)
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  /// Get single job details with linked skills
  Future<JobModel> getJobDetail(String jobId) async {
    try {
      final res = await _supabase
          .from('jobs')
          .select('*, categories(name), businesses(name, locality, business_type)')
          .eq('id', jobId)
          .single();

      // Fetch linked skills
      final skillsRes = await _supabase
          .from('job_skills')
          .select('skills(id, category_id, name)')
          .eq('job_id', jobId);

      final List<dynamic> skillsData = [];
      for (var row in (skillsRes as List)) {
        if (row['skills'] != null) {
          skillsData.add(row['skills']);
        }
      }

      final Map<String, dynamic> fullData = Map<String, dynamic>.from(res);
      fullData['skills'] = skillsData;

      return JobModel.fromJson(fullData);
    } catch (e) {
      throw Exception('कार्य विवरण लोड करने में विफल: $e');
    }
  }
}
