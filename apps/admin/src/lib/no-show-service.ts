import { supabase, isSupabaseConfigured } from './supabase';

export interface AdminNoShowRecord {
  id: string;
  booking_id: string;
  worker_id: string;
  worker_name: string;
  worker_phone: string;
  business_id: string;
  business_name: string;
  job_id: string;
  job_title: string;
  shift_date: string;
  marked_at: string;
  notes?: string | null;
  worker_total_no_shows: number;
}

export const fallbackAdminNoShows: AdminNoShowRecord[] = [
  {
    id: 'att-ns-1',
    booking_id: 'bk-w4-1',
    worker_id: 'wp-ghz-004',
    worker_name: 'विकास यादव (Vikas Yadav)',
    worker_phone: '+91 98765 77665',
    business_id: 'b-ghazipur-1',
    business_name: 'राजवाड़ा बैंक्वेट लॉन',
    job_id: 'job-ghz-001',
    job_title: '10 अनुभवी वेटर शादी समारोह के लिए',
    shift_date: '2026-11-18',
    marked_at: '2026-11-18T19:00:00Z',
    notes: 'गेट पर रिपोर्टिंग समय समाप्त होने तक नहीं पहुंचे। कोई पूर्व सूचना नहीं।',
    worker_total_no_shows: 2,
  },
];

export async function fetchAdminNoShows(filters?: {
  search?: string;
  businessId?: string;
}): Promise<AdminNoShowRecord[]> {
  if (!isSupabaseConfigured) {
    let result = [...fallbackAdminNoShows];
    if (filters?.businessId && filters.businessId !== 'all') {
      result = result.filter((ns) => ns.business_id === filters.businessId);
    }
    if (filters?.search) {
      const q = filters.search.toLowerCase();
      result = result.filter(
        (ns) =>
          ns.worker_name.toLowerCase().includes(q) ||
          ns.business_name.toLowerCase().includes(q) ||
          ns.job_title.toLowerCase().includes(q)
      );
    }
    return result;
  }

  try {
    const { data, error } = await supabase
      .from('attendance_records')
      .select(
        'id, booking_id, job_id, worker_profile_id, attendance_status, marked_at, notes, jobs(title, shift_date, business_id, businesses(name)), worker_profiles(full_name, profiles(mobile_number))'
      )
      .eq('attendance_status', 'no_show')
      .order('marked_at', { ascending: false });

    if (error) throw error;
    if (data && data.length > 0) {
      return (data as unknown[]).map((item: unknown) => {
        const raw = item as {
          id: string;
          booking_id: string;
          job_id: string;
          worker_profile_id: string;
          marked_at: string;
          notes?: string | null;
          jobs?: { title?: string; shift_date?: string; business_id?: string; businesses?: { name?: string } };
          worker_profiles?: { full_name?: string; profiles?: { mobile_number?: string } };
        };

        return {
          id: raw.id,
          booking_id: raw.booking_id,
          worker_id: raw.worker_profile_id,
          worker_name: raw.worker_profiles?.full_name || 'कार्यकर्ता',
          worker_phone: raw.worker_profiles?.profiles?.mobile_number || '-',
          business_id: raw.jobs?.business_id || '',
          business_name: raw.jobs?.businesses?.name || 'आयोजक',
          job_id: raw.job_id,
          job_title: raw.jobs?.title || 'शिफ्ट',
          shift_date: raw.jobs?.shift_date || '',
          marked_at: raw.marked_at,
          notes: raw.notes,
          worker_total_no_shows: 1,
        };
      });
    }
  } catch (err) {
    console.error('[NoShowService] Fetch error:', err);
  }

  return fallbackAdminNoShows;
}
