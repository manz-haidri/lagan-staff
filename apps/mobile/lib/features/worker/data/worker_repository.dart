import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/published_job.dart';
import '../models/worker_profile.dart';
import '../models/worker_skill.dart';

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return WorkerRepository(Supabase.instance.client);
});

class WorkerRepository {
  final SupabaseClient _supabase;

  WorkerRepository(this._supabase);

  /// Fetch standard categories with skills from database with fallback support
  Future<List<SkillCategory>> fetchCategoriesWithSkills() async {
    try {
      final categoriesData = await _supabase
          .from('categories')
          .select('id, name, slug, description')
          .eq('is_active', true)
          .order('name', ascending: true);

      final skillsData = await _supabase
          .from('skills')
          .select('id, category_id, name')
          .eq('is_active', true)
          .order('name', ascending: true);

      final List<dynamic> categoriesList = categoriesData as List<dynamic>;
      final List<dynamic> skillsList = skillsData as List<dynamic>;

      if (categoriesList.isNotEmpty) {
        return categoriesList.map((catItem) {
          final catJson = catItem as Map<String, dynamic>;
          final catId = catJson['id'] as String;
          final catSkills = skillsList
              .map((s) => s as Map<String, dynamic>)
              .where((s) => s['category_id'] == catId)
              .map((s) => WorkerSkillItem.fromJson({
                    ...s,
                    'category_name': catJson['name'],
                  }))
              .toList();

          return SkillCategory.fromJson(catJson, skills: catSkills);
        }).toList();
      }
    } catch (e) {
      debugPrint('[WorkerRepository] Error fetching categories from DB: $e. Using local defaults.');
    }

    // Default Ghazipur master categories & skills fallback
    return _getDefaultCategories();
  }

  /// Uploads client-compressed selfie (<100KB) to the private 'worker-selfies' bucket
  Future<String> uploadSelfie({
    required String userId,
    required Uint8List imageBytes,
    String extension = 'jpg',
  }) async {
    final suffix = extension.toLowerCase();
    final contentType = switch (suffix) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError.value(extension, 'extension', 'Unsupported selfie format'),
    };
    final fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = '$userId/$fileName';

    if (imageBytes.lengthInBytes > 2 * 1024 * 1024) {
      throw Exception('Selfie image file is too large. Must be under 2MB.');
    }

    debugPrint(
      '[WorkerRepository] Uploading selfie: $storagePath (Size: ${(imageBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)',
    );

    try {
      await _supabase.storage.from('worker-selfies').uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      return storagePath;
    } catch (e) {
      debugPrint('[WorkerRepository] Selfie storage upload failed: $e');
      throw Exception('सेल्फी अपलोड विफल (Upload failed): $e');
    }
  }

  /// Atomic backend-validated RPC for Worker Onboarding and Automatic Activation
  Future<WorkerProfileModel> completeWorkerOnboarding({
    required String fullName,
    required String locality,
    required String pincode,
    double? latitude,
    double? longitude,
    required String selfieStoragePath,
    required List<String> skillIds,
    String? customSkill,
  }) async {
    try {
      final response = await _supabase.rpc(
        'complete_worker_onboarding',
        params: {
          'p_full_name': fullName.trim(),
          'p_locality': locality.trim(),
          'p_pincode': pincode.trim(),
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_selfie_path': selfieStoragePath,
          'p_skill_ids': skillIds,
          'p_custom_skill': customSkill?.trim().isEmpty == true ? null : customSkill?.trim(),
        },
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return WorkerProfileModel(
          id: response['worker_profile_id'] as String?,
          userId: response['user_id'] as String? ?? '',
          fullName: response['full_name'] as String? ?? fullName,
          phone: '',
          locality: response['locality'] as String? ?? locality,
          pincode: response['pincode'] as String? ?? pincode,
          latitude: latitude,
          longitude: longitude,
          selfieStoragePath: selfieStoragePath,
          status: WorkerAccountStatus.active,
          isSelfieVerified: true,
        );
      }

      throw Exception('Server returned invalid onboarding response.');
    } catch (e) {
      debugPrint('[WorkerRepository] complete_worker_onboarding RPC error: $e');
      rethrow;
    }
  }

  /// Retrieves the current worker's onboarding status and active details
  Future<WorkerProfileModel?> getWorkerOnboardingStatus() async {
    try {
      final response = await _supabase.rpc('get_worker_onboarding_status');
      if (response != null && response is Map<String, dynamic>) {
        if (response['authenticated'] == true && response['has_worker_profile'] == true) {
          return WorkerProfileModel.fromJson(response);
        } else if (response['authenticated'] == true) {
          // Profile exists in profiles table but worker_profile not created yet
          return WorkerProfileModel(
            userId: _supabase.auth.currentUser?.id ?? '',
            fullName: response['full_name'] as String? ?? '',
            phone: response['phone'] as String? ?? '',
            locality: '',
            pincode: '',
            status: WorkerAccountStatus.pendingProfile,
          );
        }
      }
    } catch (e) {
      debugPrint('[WorkerRepository] Error checking worker onboarding status: $e');
    }
    return null;
  }

  /// Fetches available published jobs for Ghazipur workers
  Future<List<PublishedJob>> fetchPublishedJobs() async {
    try {
      final data = await _supabase
          .from('jobs')
          .select('*, businesses(name, locality), categories(name)')
          .eq('status', 'published')
          .order('shift_date', ascending: true);

      final list = data as List<dynamic>;
      if (list.isNotEmpty) {
        return list
            .map((item) => PublishedJob.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[WorkerRepository] Error fetching published jobs: $e');
    }

    return [];
  }

  /// Default fallback categories and skills for Ghazipur region
  static List<SkillCategory> _getDefaultCategories() {
    return const [
      SkillCategory(
        id: 'cat-waiters',
        name: 'Waiters (वेटर)',
        slug: 'waiters',
        skills: [
          WorkerSkillItem(
            id: 'skill-w-1',
            categoryId: 'cat-waiters',
            name: 'Table Service (टेबल सेवा)',
            categoryName: 'Waiters',
          ),
          WorkerSkillItem(
            id: 'skill-w-2',
            categoryId: 'cat-waiters',
            name: 'Buffet Counter Service (बुफे व्यवस्था)',
            categoryName: 'Waiters',
          ),
          WorkerSkillItem(
            id: 'skill-w-3',
            categoryId: 'cat-waiters',
            name: 'Water & Drinks Serving (पानी व पेय सेवा)',
            categoryName: 'Waiters',
          ),
        ],
      ),
      SkillCategory(
        id: 'cat-cleaners',
        name: 'Cleaners (सफाई कर्मी)',
        slug: 'cleaners',
        skills: [
          WorkerSkillItem(
            id: 'skill-c-1',
            categoryId: 'cat-cleaners',
            name: 'Hall & Dining Area Cleaning (हॉल सफाई)',
            categoryName: 'Cleaners',
          ),
          WorkerSkillItem(
            id: 'skill-c-2',
            categoryId: 'cat-cleaners',
            name: 'Utensil & Dish Washing (बर्तन धुलाई)',
            categoryName: 'Cleaners',
          ),
          WorkerSkillItem(
            id: 'skill-c-3',
            categoryId: 'cat-cleaners',
            name: 'Waste Disposal (कचरा निस्तारण)',
            categoryName: 'Cleaners',
          ),
        ],
      ),
      SkillCategory(
        id: 'cat-halwai',
        name: 'Halwai Helpers (हलवाई सहायक)',
        slug: 'halwai_helpers',
        skills: [
          WorkerSkillItem(
            id: 'skill-h-1',
            categoryId: 'cat-halwai',
            name: 'Vegetable Cutting (सब्जी कटाई)',
            categoryName: 'Halwai Helpers',
          ),
          WorkerSkillItem(
            id: 'skill-h-2',
            categoryId: 'cat-halwai',
            name: 'Dough Preparation (आटा गूंथना)',
            categoryName: 'Halwai Helpers',
          ),
          WorkerSkillItem(
            id: 'skill-h-3',
            categoryId: 'cat-halwai',
            name: 'Frying & Cooking Support (तलने-पकाने में सहायता)',
            categoryName: 'Halwai Helpers',
          ),
        ],
      ),
      SkillCategory(
        id: 'cat-loaders',
        name: 'Loaders (लोडर / सामान ढुलाई)',
        slug: 'loaders',
        skills: [
          WorkerSkillItem(
            id: 'skill-l-1',
            categoryId: 'cat-loaders',
            name: 'Tent Equipment Loading (टेंट सामान लोड/अनलोड)',
            categoryName: 'Loaders',
          ),
          WorkerSkillItem(
            id: 'skill-l-2',
            categoryId: 'cat-loaders',
            name: 'Heavy Cooking Vessel Shifting (भारी पतीले उठाना)',
            categoryName: 'Loaders',
          ),
          WorkerSkillItem(
            id: 'skill-l-3',
            categoryId: 'cat-loaders',
            name: 'Furniture & Chairs Setup (कुर्सी-मेज लगाना)',
            categoryName: 'Loaders',
          ),
        ],
      ),
      SkillCategory(
        id: 'cat-event',
        name: 'Event Helpers (इवेंट सहायक)',
        slug: 'event_helpers',
        skills: [
          WorkerSkillItem(
            id: 'skill-e-1',
            categoryId: 'cat-event',
            name: 'Flower Decoration (फूल सजावट)',
            categoryName: 'Event Helpers',
          ),
          WorkerSkillItem(
            id: 'skill-e-2',
            categoryId: 'cat-event',
            name: 'Stage & Light Support (स्टेज व लाइट सहायता)',
            categoryName: 'Event Helpers',
          ),
          WorkerSkillItem(
            id: 'skill-e-3',
            categoryId: 'cat-event',
            name: 'Welcome Gate Helper (स्वागत द्वार सहायक)',
            categoryName: 'Event Helpers',
          ),
        ],
      ),
      SkillCategory(
        id: 'cat-other',
        name: 'Other (अन्य सहायक कार्य)',
        slug: 'other',
        skills: [
          WorkerSkillItem(
            id: 'skill-o-1',
            categoryId: 'cat-other',
            name: 'General Helper (सामान्य सहायक)',
            categoryName: 'Other',
          ),
        ],
      ),
    ];
  }
}
