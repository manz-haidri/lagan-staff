import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_document_model.dart';
import '../models/business_model.dart';
import '../models/owner_job_history_item.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository(Supabase.instance.client);
});

class OwnerRepository {
  final SupabaseClient _supabase;

  OwnerRepository(this._supabase);

  /// Fetch the current owner's primary business and uploaded documents
  Future<BusinessModel?> getMyBusiness() async {
    try {
      final response = await _supabase.rpc('get_my_business');
      if (response != null && response is Map<String, dynamic>) {
        if (response['authenticated'] == true && response['has_business'] == true) {
          final bizData = response['business'] as Map<String, dynamic>;
          return BusinessModel.fromJson(bizData);
        }
      }
    } catch (e) {
      debugPrint('[OwnerRepository] get_my_business RPC error: $e');
    }
    return null;
  }

  /// Upsert business profile as draft (allows continuing later)
  Future<String?> saveBusinessDraft({
    String? businessId,
    required String name,
    required String businessType,
    String? description,
    String? contactPerson,
    required String contactPhone,
    required String locality,
    String? address,
    required String pincode,
    double? latitude,
    double? longitude,
    String? gstOrTradeId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'save_business_profile_draft',
        params: {
          'p_business_id': businessId,
          'p_name': name.trim(),
          'p_business_type': businessType,
          'p_description': description?.trim().isEmpty == true ? null : description?.trim(),
          'p_contact_person': contactPerson?.trim().isEmpty == true ? null : contactPerson?.trim(),
          'p_contact_phone': contactPhone.trim(),
          'p_locality': locality.trim(),
          'p_address': address?.trim().isEmpty == true ? null : address?.trim(),
          'p_pincode': pincode.trim(),
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_gst_or_trade_id': gstOrTradeId?.trim().isEmpty == true ? null : gstOrTradeId?.trim(),
        },
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return response['business_id'] as String?;
      }
    } catch (e) {
      debugPrint('[OwnerRepository] save_business_profile_draft error: $e');
      rethrow;
    }
    return null;
  }

  /// Submit business profile for Admin verification (transitions draft/rejected -> pending)
  Future<bool> submitBusinessForVerification(String businessId) async {
    try {
      final response = await _supabase.rpc(
        'submit_business_for_verification',
        params: {'p_business_id': businessId},
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint('[OwnerRepository] submit_business_for_verification error: $e');
      rethrow;
    }
    return false;
  }

  /// Uploads optional verification proof to private 'business-documents' bucket
  Future<BusinessDocumentModel> uploadBusinessDocument({
    required String businessId,
    required Uint8List fileBytes,
    required String fileName,
    required String documentType,
    String mimeType = 'image/jpeg',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Authentication required.');
    }

    if (fileBytes.lengthInBytes > 10 * 1024 * 1024) {
      throw Exception('File size exceeds maximum limit of 10MB.');
    }

    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final storagePath = '$businessId/doc_${documentType}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      // 1. Upload to Supabase Storage
      await _supabase.storage.from('business-documents').uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      // 2. Insert record in business_verification_documents table
      final record = await _supabase
          .from('business_verification_documents')
          .insert({
            'business_id': businessId,
            'document_type': documentType,
            'storage_path': storagePath,
            'file_name': fileName,
            'file_size_bytes': fileBytes.lengthInBytes,
            'mime_type': mimeType,
            'uploaded_by': userId,
          })
          .select()
          .single();

      return BusinessDocumentModel.fromJson(record);
    } catch (e) {
      debugPrint('[OwnerRepository] Error uploading business document: $e');
      throw Exception('दस्तावेज़ अपलोड विफल (Upload failed): $e');
    }
  }

  /// Deletes a previously uploaded document
  Future<void> deleteBusinessDocument(String documentId, String storagePath) async {
    try {
      await _supabase.storage.from('business-documents').remove([storagePath]);
      await _supabase
          .from('business_verification_documents')
          .delete()
          .eq('id', documentId);
    } catch (e) {
      debugPrint('[OwnerRepository] Error deleting business document: $e');
      rethrow;
    }
  }

  /// Fetch real previous job history for this business (read-only, no fake records)
  Future<List<OwnerJobHistoryItem>> fetchBusinessJobHistory(
    String businessId, {
    String? statusFilter,
  }) async {
    try {
      var query = _supabase
          .from('jobs')
          .select('*, categories(name)')
          .eq('business_id', businessId);

      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }

      final data = await query.order('created_at', ascending: false);

      final list = data as List<dynamic>;
      return list
          .map((item) => OwnerJobHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OwnerRepository] Error fetching business job history: $e');
      return [];
    }
  }

  /// Fetch business statistics (total, active, completed jobs)
  Future<Map<String, int>> fetchBusinessStats(String businessId) async {
    try {
      final response = await _supabase.rpc(
        'get_owner_business_stats',
        params: {'p_business_id': businessId},
      );

      if (response is Map<String, dynamic>) {
        return {
          'total_jobs': int.tryParse(response['total_jobs']?.toString() ?? '0') ?? 0,
          'active_jobs': int.tryParse(response['active_jobs']?.toString() ?? '0') ?? 0,
          'completed_jobs': int.tryParse(response['completed_jobs']?.toString() ?? '0') ?? 0,
        };
      }
    } catch (e) {
      debugPrint('[OwnerRepository] Error fetching business stats: $e');
    }

    return {'total_jobs': 0, 'active_jobs': 0, 'completed_jobs': 0};
  }
}
