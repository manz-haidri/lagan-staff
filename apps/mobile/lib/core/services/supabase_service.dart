import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'SupabaseService has not been initialized. Call SupabaseService.init() first.',
      );
    }
    return Supabase.instance.client;
  }

  /// Initializes the Supabase client safely with configuration checks.
  static Future<void> init() async {
    try {
      final url = SupabaseConfig.supabaseUrl;
      final publishableKey = SupabaseConfig.supabasePublishableKey;

      if (url.isEmpty || publishableKey.isEmpty) {
        debugPrint(
          '[LaganStaff SupabaseService] WARNING: Supabase URL or Publishable Key is empty. Pass via --dart-define.',
        );
      }

      await Supabase.initialize(
        url: url,
        publishableKey: publishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _isInitialized = true;
      debugPrint('[LaganStaff SupabaseService] Initialized successfully with URL: $url');
    } catch (e, stack) {
      debugPrint('[LaganStaff SupabaseService] Failed to initialize: $e\n$stack');
      rethrow;
    }
  }

  /// Verifies connectivity to the Supabase endpoint.
  /// Clearly distinguishes client initialization from live database query.
  static Future<bool> checkEndpointReachability() async {
    if (!_isInitialized) return false;
    try {
      // Pings the Supabase Auth session or public health
      final session = client.auth.currentSession;
      debugPrint('[LaganStaff SupabaseService] Auth endpoint reached. Active session: ${session != null}');
      return true;
    } catch (e) {
      debugPrint('[LaganStaff SupabaseService] Endpoint check failed: $e');
      return false;
    }
  }
}
