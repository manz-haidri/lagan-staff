class SupabaseConfig {
  // Replace these with your active Supabase project credentials
  // or pass via --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://earfrohtxyicikqagrtu.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_5vZQ462hQIX-PPTG1pvSFA_51mqRtKu',
  );
}
