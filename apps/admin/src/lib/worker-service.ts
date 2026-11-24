import { supabase, isSupabaseConfigured } from './supabase';

export interface AdminWorkerRecord {
  id: string;
  user_id: string;
  full_name: string;
  mobile_number: string;
  locality: string;
  city: string;
  pincode?: string;
  account_status: 'active' | 'suspended';
  review_status: 'not_reviewed' | 'reviewed' | 'needs_attention';
  review_notes?: string | null;
  reviewed_at?: string | null;
  selfie_url?: string | null;
  created_at: string;
  skills: string[];
  shifts_completed: number;
}

export const fallbackAdminWorkers: AdminWorkerRecord[] = [
  {
    id: 'wp-ghz-001',
    user_id: 'usr-1',
    full_name: 'राहुल कुमार (Rahul Kumar)',
    mobile_number: '+91 98765 43210',
    locality: 'लंका (Lanka)',
    city: 'Ghazipur',
    pincode: '233001',
    account_status: 'active',
    review_status: 'reviewed',
    selfie_url: null,
    created_at: '2026-11-17T10:00:00Z',
    skills: ['टेबल सर्विस (Table Service)', 'प्लेट हैंडलिंग (Plate Handling)'],
    shifts_completed: 14,
  },
  {
    id: 'wp-ghz-002',
    user_id: 'usr-2',
    full_name: 'सोनू वर्मा (Sonu Verma)',
    mobile_number: '+91 98765 11223',
    locality: 'महुआबाग (Mahuabagh)',
    city: 'Ghazipur',
    pincode: '233001',
    account_status: 'active',
    review_status: 'not_reviewed',
    selfie_url: null,
    created_at: '2026-11-18T06:30:00Z',
    skills: ['हलवाई हेल्पर (Halwai Helper)', 'सब्जी कटिंग'],
    shifts_completed: 8,
  },
  {
    id: 'wp-ghz-003',
    user_id: 'usr-3',
    full_name: 'अमित कुमार सिंह (Amit Singh)',
    mobile_number: '+91 98765 99887',
    locality: 'स्टेशन रोड (Station Road)',
    city: 'Ghazipur',
    pincode: '233001',
    account_status: 'active',
    review_status: 'needs_attention',
    review_notes: 'सेल्फी धुंधली है। कृपया पुनः सेल्फी अपलोड करने हेतु सूचित करें।',
    selfie_url: null,
    created_at: '2026-11-18T08:00:00Z',
    skills: ['टेंट रिगर (Tent Rigger)', 'लोडर (Loader)'],
    shifts_completed: 22,
  },
  {
    id: 'wp-ghz-004',
    user_id: 'usr-4',
    full_name: 'विकास यादव (Vikas Yadav)',
    mobile_number: '+91 98765 77665',
    locality: 'सैदपुर (Saidpur)',
    city: 'Saidpur',
    pincode: '233304',
    account_status: 'suspended',
    review_status: 'needs_attention',
    review_notes: 'लगातार 2 शिफ्ट में बिना सूचना के अनुपस्थित (No-show)।',
    selfie_url: null,
    created_at: '2026-11-15T12:00:00Z',
    skills: ['वेटर (Waiter)'],
    shifts_completed: 3,
  },
];

export async function fetchAdminWorkers(filters?: {
  accountStatus?: string;
  reviewStatus?: string;
  search?: string;
  locality?: string;
}): Promise<AdminWorkerRecord[]> {
  if (!isSupabaseConfigured) {
    let result = [...fallbackAdminWorkers];
    if (filters?.accountStatus && filters.accountStatus !== 'all') {
      result = result.filter((w) => w.account_status === filters.accountStatus);
    }
    if (filters?.reviewStatus && filters.reviewStatus !== 'all') {
      result = result.filter((w) => w.review_status === filters.reviewStatus);
    }
    if (filters?.search) {
      const q = filters.search.toLowerCase();
      result = result.filter(
        (w) =>
          w.full_name.toLowerCase().includes(q) ||
          w.mobile_number.includes(q) ||
          w.locality.toLowerCase().includes(q)
      );
    }
    return result;
  }

  try {
    let query = supabase
      .from('worker_profiles')
      .select('*, profiles!user_id(mobile_number), worker_skills(skills(name))');

    if (filters?.accountStatus && filters.accountStatus !== 'all') {
      query = query.eq('account_status', filters.accountStatus);
    }
    if (filters?.reviewStatus && filters.reviewStatus !== 'all') {
      query = query.eq('review_status', filters.reviewStatus);
    }
    if (filters?.search) {
      query = query.or(`full_name.ilike.%${filters.search}%,locality.ilike.%${filters.search}%`);
    }

    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    if (data && data.length > 0) {
      return data.map((item) => {
        const skills = (item.worker_skills || [])
          .map((ws: { skills?: { name?: string } }) => ws.skills?.name)
          .filter(Boolean) as string[];

        return {
          id: item.id,
          user_id: item.user_id,
          full_name: item.full_name,
          mobile_number: item.profiles?.mobile_number || '-',
          locality: item.locality,
          city: item.city || 'Ghazipur',
          pincode: item.pincode,
          account_status: item.account_status,
          review_status: item.review_status || 'not_reviewed',
          review_notes: item.review_notes,
          reviewed_at: item.reviewed_at,
          selfie_url: item.selfie_url,
          created_at: item.created_at,
          skills,
          shifts_completed: 0,
        };
      });
    }
  } catch (err) {
    console.error('[WorkerService] Fetch workers error:', err);
  }

  return fallbackAdminWorkers;
}

export async function fetchAdminWorkerDetail(id: string): Promise<AdminWorkerRecord | null> {
  const workers = await fetchAdminWorkers();
  return workers.find((w) => w.id === id) || null;
}

export async function reviewWorker(
  workerId: string,
  reviewStatus: 'reviewed' | 'needs_attention',
  notes?: string
): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    const found = fallbackAdminWorkers.find((w) => w.id === workerId);
    if (found) {
      found.review_status = reviewStatus;
      found.review_notes = notes;
      return { success: true };
    }
  }

  try {
    const { data, error } = await supabase.rpc('admin_review_worker', {
      p_worker_id: workerId,
      p_review_status: reviewStatus,
      p_notes: notes || null,
    });
    if (error) throw error;
    if (data?.success) return { success: true };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, error: msg };
  }

  return { success: true };
}

export async function suspendWorker(
  workerId: string,
  reason: string
): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    const found = fallbackAdminWorkers.find((w) => w.id === workerId);
    if (found) {
      found.account_status = 'suspended';
      found.review_notes = reason;
      return { success: true };
    }
  }

  try {
    const { data, error } = await supabase.rpc('admin_suspend_worker', {
      p_worker_id: workerId,
      p_reason: reason,
    });
    if (error) throw error;
    if (data?.success) return { success: true };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, error: msg };
  }

  return { success: true };
}

export async function reactivateWorker(workerId: string): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    const found = fallbackAdminWorkers.find((w) => w.id === workerId);
    if (found) {
      found.account_status = 'active';
      return { success: true };
    }
  }

  try {
    const { data, error } = await supabase.rpc('admin_reactivate_worker', {
      p_worker_id: workerId,
    });
    if (error) throw error;
    if (data?.success) return { success: true };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, error: msg };
  }

  return { success: true };
}

export async function getWorkerSelfieSignedUrl(storagePath: string): Promise<string | null> {
  if (!isSupabaseConfigured || !storagePath) {
    return null;
  }

  try {
    const { data, error } = await supabase.storage
      .from('worker-selfies')
      .createSignedUrl(storagePath, 3600); // 1 hour access
    if (error) throw error;
    return data?.signedUrl || null;
  } catch (err) {
    console.error('[WorkerService] Signed selfie URL error:', err);
    return null;
  }
}
