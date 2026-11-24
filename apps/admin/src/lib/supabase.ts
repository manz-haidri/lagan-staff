import { createClient, SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabasePublishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || '';

export const isSupabaseConfigured = Boolean(
  supabaseUrl &&
  supabaseUrl !== 'https://your-project-id.supabase.co' &&
  supabasePublishableKey &&
  supabasePublishableKey !== 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your_anon_key'
);

let _supabaseClient: SupabaseClient | null = null;

/**
 * Returns the shared browser Supabase client.
 * Safe for client-side queries protected by Row Level Security (RLS).
 */
export function getSupabaseClient(): SupabaseClient {
  if (!_supabaseClient) {
    if (!isSupabaseConfigured) {
      console.warn(
        '[LaganStaff Admin] Supabase credentials not configured in environment. Using fallback client.'
      );
    }
    _supabaseClient = createClient(
      supabaseUrl || 'https://placeholder-project.supabase.co',
      supabasePublishableKey || 'placeholder-publishable-key',
      {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
        },
      }
    );
  }
  return _supabaseClient;
}

export const supabase = getSupabaseClient();
