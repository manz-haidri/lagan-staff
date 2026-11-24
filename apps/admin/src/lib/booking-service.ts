import { supabase, isSupabaseConfigured } from './supabase';

export interface AdminBookingRecord {
  id: string;
  job_id: string;
  job_title: string;
  venue_name: string;
  reporting_address: string;
  shift_date: string;
  shift_time: string;
  locality: string;
  worker_profile_id: string;
  worker_name: string;
  worker_phone: string;
  worker_locality: string;
  business_id: string;
  business_name: string;
  business_type: string;
  business_contact_phone: string;
  status: 'confirmed' | 'checked_in' | 'completed' | 'cancelled_by_worker' | 'cancelled_by_owner' | 'no_show';
  agreed_wage: number;
  checkin_code: string;
  attendance_status: 'pending' | 'checked_in' | 'present' | 'absent' | 'no_show';
  check_in_time: string | null;
  work_completion_status: 'pending' | 'completed';
  completed_at: string | null;
  owner_notes?: string | null;
  confirmed_at: string;
  created_at: string;
}

export const fallbackBookings: AdminBookingRecord[] = [
  {
    id: 'bk-ghz-501',
    job_id: 'job-ghz-001',
    job_title: '10 अनुभवी वेटर शादी समारोह के लिए',
    venue_name: 'राजवाड़ा बैंक्वेट लॉन',
    reporting_address: 'निकट पीजी कॉलेज गेट, मुख्य सड़क, लंका',
    shift_date: '2026-11-20',
    shift_time: '18:00 - 02:00',
    locality: 'Lanka',
    worker_profile_id: 'w-ghz-001',
    worker_name: 'राहुल कुमार (Rahul Kumar)',
    worker_phone: '+91 98765 43210',
    worker_locality: 'लहूराबीर, लंका',
    business_id: 'b-ghazipur-1',
    business_name: 'राजवाड़ा बैंक्वेट लॉन (Rajwada Banquet Lawn)',
    business_type: 'marriage_hall',
    business_contact_phone: '+91 98765 44332',
    status: 'checked_in',
    agreed_wage: 600,
    checkin_code: '7429',
    attendance_status: 'present',
    check_in_time: '2026-11-20T17:45:00Z',
    work_completion_status: 'pending',
    completed_at: null,
    owner_notes: 'ससमय उपस्थित हुए, उचित वेशभूषा में।',
    confirmed_at: '2026-11-18T10:00:00Z',
    created_at: '2026-11-18T10:00:00Z',
  },
  {
    id: 'bk-ghz-502',
    job_id: 'job-ghz-001',
    job_title: '10 अनुभवी वेटर शादी समारोह के लिए',
    venue_name: 'राजवाड़ा बैंक्वेट लॉन',
    reporting_address: 'निकट पीजी कॉलेज गेट, मुख्य सड़क, लंका',
    shift_date: '2026-11-20',
    shift_time: '18:00 - 02:00',
    locality: 'Lanka',
    worker_profile_id: 'w-ghz-002',
    worker_name: 'अमित कुमार सिंह (Amit Singh)',
    worker_phone: '+91 98765 43211',
    worker_locality: 'महुआबाग, गाजीपुर',
    business_id: 'b-ghazipur-1',
    business_name: 'राजवाड़ा बैंक्वेट लॉन (Rajwada Banquet Lawn)',
    business_type: 'marriage_hall',
    business_contact_phone: '+91 98765 44332',
    status: 'confirmed',
    agreed_wage: 600,
    checkin_code: '3812',
    attendance_status: 'pending',
    check_in_time: null,
    work_completion_status: 'pending',
    completed_at: null,
    owner_notes: null,
    confirmed_at: '2026-11-18T10:30:00Z',
    created_at: '2026-11-18T10:30:00Z',
  },
  {
    id: 'bk-ghz-503',
    job_id: 'job-ghz-002',
    job_title: '4 हलवाई सहायक (Halwai Assistants)',
    venue_name: 'शाही दरबार पैलेस',
    reporting_address: 'मिश्रबाजार मुख्य चौराहा',
    shift_date: '2026-11-19',
    shift_time: '14:00 - 23:00',
    locality: 'Mishra Bazar',
    worker_profile_id: 'w-ghz-003',
    worker_name: 'दीपक कुमार गुप्ता (Deepak Gupta)',
    worker_phone: '+91 98765 43212',
    worker_locality: 'गोराबाजार, गाजीपुर',
    business_id: 'b-ghazipur-2',
    business_name: 'शाही दरबार पैलेस व कैटरर्स',
    business_type: 'catering_agency',
    business_contact_phone: '+91 98765 88776',
    status: 'completed',
    agreed_wage: 700,
    checkin_code: '1904',
    attendance_status: 'present',
    check_in_time: '2026-11-19T13:50:00Z',
    work_completion_status: 'completed',
    completed_at: '2026-11-19T23:15:00Z',
    owner_notes: 'उत्कृष्ट कार्य किया, मिठाइयों की तैयारी में सहयोग दिया।',
    confirmed_at: '2026-11-17T14:00:00Z',
    created_at: '2026-11-17T14:00:00Z',
  },
  {
    id: 'bk-ghz-504',
    job_id: 'job-ghz-002',
    job_title: '4 हलवाई सहायक (Halwai Assistants)',
    venue_name: 'शाही दरबार पैलेस',
    reporting_address: 'मिश्रबाजार मुख्य चौराहा',
    shift_date: '2026-11-19',
    shift_time: '14:00 - 23:00',
    locality: 'Mishra Bazar',
    worker_profile_id: 'w-ghz-004',
    worker_name: 'सुरेश यादव (Suresh Yadav)',
    worker_phone: '+91 98765 43213',
    worker_locality: 'जमानिया मोड़',
    business_id: 'b-ghazipur-2',
    business_name: 'शाही दरबार पैलेस व कैटरर्स',
    business_type: 'catering_agency',
    business_contact_phone: '+91 98765 88776',
    status: 'no_show',
    agreed_wage: 700,
    checkin_code: '6251',
    attendance_status: 'no_show',
    check_in_time: null,
    work_completion_status: 'pending',
    completed_at: null,
    owner_notes: 'कार्यक्रम स्थल पर नहीं पहुंचे, कॉल का उत्तर नहीं दिया।',
    confirmed_at: '2026-11-17T15:00:00Z',
    created_at: '2026-11-17T15:00:00Z',
  },
];

export async function fetchMasterBookingsList(params?: {
  search?: string;
  status?: string;
  limit?: number;
}): Promise<AdminBookingRecord[]> {
  if (!isSupabaseConfigured) {
    let filtered = [...fallbackBookings];
    if (params?.status && params.status !== 'all') {
      filtered = filtered.filter((b) => b.status === params.status);
    }
    if (params?.search) {
      const q = params.search.toLowerCase();
      filtered = filtered.filter(
        (b) =>
          b.worker_name.toLowerCase().includes(q) ||
          b.worker_phone.includes(q) ||
          b.job_title.toLowerCase().includes(q) ||
          b.business_name.toLowerCase().includes(q) ||
          b.checkin_code.includes(q)
      );
    }
    return filtered;
  }

  try {
    let query = supabase
      .from('bookings')
      .select(`
        *,
        jobs (
          title, venue_name, reporting_address, shift_date, start_time, end_time, locality, wage_amount
        ),
        worker_profiles (
          id, full_name, mobile_number, locality
        ),
        businesses (
          id, name, business_type, contact_phone
        ),
        attendance_records (
          status, check_in_time, work_completion_status, completed_at, owner_notes
        )
      `)
      .order('created_at', { ascending: false });

    if (params?.status && params.status !== 'all') {
      query = query.eq('status', params.status);
    }
    if (params?.limit) {
      query = query.limit(params.limit);
    }

    const { data, error } = await query;
    if (error || !data || data.length === 0) {
      return fallbackBookings;
    }

    return data.map((row) => {
      const job = (row.jobs as Record<string, unknown>) || {};
      const worker = (row.worker_profiles as Record<string, unknown>) || {};
      const biz = (row.businesses as Record<string, unknown>) || {};
      const att = Array.isArray(row.attendance_records) && row.attendance_records.length > 0
        ? (row.attendance_records[0] as Record<string, unknown>)
        : {};

      return {
        id: String(row.id),
        job_id: String(row.job_id),
        job_title: String(job.title || 'कार्य'),
        venue_name: String(job.venue_name || 'वेन्यू'),
        reporting_address: String(job.reporting_address || ''),
        shift_date: String(job.shift_date || ''),
        shift_time: `${String(job.start_time || '').substring(0, 5)} - ${String(job.end_time || '').substring(0, 5)}`,
        locality: String(job.locality || 'Ghazipur'),
        worker_profile_id: String(row.worker_profile_id),
        worker_name: String(worker.full_name || 'श्रमिक'),
        worker_phone: String(worker.mobile_number || ''),
        worker_locality: String(worker.locality || 'Ghazipur'),
        business_id: String(row.business_id),
        business_name: String(biz.name || 'व्यवसाय'),
        business_type: String(biz.business_type || 'other'),
        business_contact_phone: String(biz.contact_phone || ''),
        status: (row.status as AdminBookingRecord['status']) || 'confirmed',
        agreed_wage: Number(row.agreed_wage || 0),
        checkin_code: String(row.checkin_code || '----'),
        attendance_status: (att.status as AdminBookingRecord['attendance_status']) || 'pending',
        check_in_time: (att.check_in_time as string) || null,
        work_completion_status: (att.work_completion_status as AdminBookingRecord['work_completion_status']) || 'pending',
        completed_at: (att.completed_at as string) || null,
        owner_notes: (att.owner_notes as string) || null,
        confirmed_at: String(row.confirmed_at || row.created_at),
        created_at: String(row.created_at),
      };
    });
  } catch (err) {
    console.warn('[Admin] fetchMasterBookingsList error:', err);
    return fallbackBookings;
  }
}

export async function fetchBookingDetail(id: string): Promise<AdminBookingRecord | null> {
  const list = await fetchMasterBookingsList();
  const found = list.find((b) => b.id === id);
  return found || null;
}
