import { supabase, isSupabaseConfigured } from './supabase';

export interface AdminJobSkill {
  id: string;
  name: string;
}

export interface AdminJobRecord {
  id: string;
  business_id: string;
  business_name: string;
  business_category: string;
  business_verification_status: string;
  contact_person?: string | null;
  contact_phone: string;
  category_id: string;
  category_name: string;
  title: string;
  description?: string | null;
  venue_name?: string | null;
  reporting_address: string;
  locality: string;
  city: string;
  pincode: string;
  latitude?: number | null;
  longitude?: number | null;
  shift_date: string;
  start_time: string;
  end_time: string;
  is_overnight: boolean;
  workers_needed: number;
  workers_confirmed: number;
  wage_amount: number;
  wage_rate_unit: string;
  payment_instructions?: string | null;
  food_provided: boolean;
  food_details?: string | null;
  transport_provided: boolean;
  transport_details?: string | null;
  special_instructions?: string | null;
  is_first_job: boolean;
  status: 'draft' | 'pending_admin_approval' | 'published' | 'filled' | 'in_progress' | 'completed' | 'cancelled' | 'rejected';
  admin_rejection_reason?: string | null;
  approved_by?: string | null;
  approved_at?: string | null;
  published_at?: string | null;
  created_at: string;
  skills: AdminJobSkill[];
}

export const fallbackPendingJobs: AdminJobRecord[] = [
  {
    id: 'job-ghz-001',
    business_id: 'b-ghazipur-1',
    business_name: 'राजवाड़ा बैंक्वेट लॉन (Rajwada Banquet Lawn)',
    business_category: 'marriage_hall',
    business_verification_status: 'verified',
    contact_person: 'सुनील कुमार सिंह',
    contact_phone: '+91 98765 44332',
    category_id: 'cat-waiters',
    category_name: 'वेटर (Waiters)',
    title: '10 अनुभवी वेटर शादी समारोह के लिए (First Job Submission)',
    description: 'शाम के भव्य शादी समारोह में वीआईपी डायनिंग और ड्रिंक्स सर्विंग हेतु 10 कुशल वेटर।',
    venue_name: 'राजवाड़ा बैंक्वेट लॉन, मुख्य द्वार',
    reporting_address: 'निकट पीजी कॉलेज गेट, मुख्य सड़क, लंका',
    locality: 'Lanka',
    city: 'Ghazipur',
    pincode: '233001',
    latitude: 25.5840,
    longitude: 83.5770,
    shift_date: '2026-11-25',
    start_time: '18:00:00',
    end_time: '23:30:00',
    is_overnight: false,
    workers_needed: 10,
    workers_confirmed: 0,
    wage_amount: 650.0,
    wage_rate_unit: 'per_shift',
    payment_instructions: 'शिफ्ट समाप्ति के उपरांत चेक-आउट के समय नकद भुगतान।',
    food_provided: true,
    food_details: 'रात का भोजन (Dinner) और शाम की चाय',
    transport_provided: false,
    special_instructions: 'सफेद कमीज, काली पैंट, काले जूते अनिवार्य हैं। 17:30 बजे रिपोर्ट करें।',
    is_first_job: true,
    status: 'pending_admin_approval',
    created_at: '2026-11-18T09:15:00Z',
    skills: [
      { id: 'sk-1', name: 'टेबल सर्विस' },
      { id: 'sk-2', name: 'ट्रे हैंडलिंग' },
    ],
  },
  {
    id: 'job-ghz-002',
    business_id: 'b-ghazipur-2',
    business_name: 'शाही दावत कैटरर्स (Shahi Dawat Caterers)',
    business_category: 'catering_agency',
    business_verification_status: 'verified',
    contact_person: 'मोहम्मद असलम',
    contact_phone: '+91 98765 22119',
    category_id: 'cat-halwai',
    category_name: 'हलवाई हेल्पर (Halwai Helpers)',
    title: '4 हलवाई रसोई सहायक (First Job Submission)',
    description: 'शादी के भोजन निर्माण में मुख्य हलवाई के सहयोग हेतु अनुभवी रसोइया सहायक।',
    venue_name: 'शाही दावत सेंट्रल किचन',
    reporting_address: 'मिश्रा बाजार, कोतवाली के पीछे',
    locality: 'Mishra Bazar',
    city: 'Ghazipur',
    pincode: '233001',
    latitude: 25.5810,
    longitude: 83.5720,
    shift_date: '2026-11-26',
    start_time: '08:00:00',
    end_time: '16:00:00',
    is_overnight: false,
    workers_needed: 4,
    workers_confirmed: 0,
    wage_amount: 750.0,
    wage_rate_unit: 'per_shift',
    payment_instructions: 'कार्य समाप्ति पर तुरंत भुगतान।',
    food_provided: true,
    food_details: 'सुबह का नाश्ता और दोपहर का भोजन',
    transport_provided: true,
    transport_details: 'गाजीपुर रेलवे स्टेशन से पिकअप',
    special_instructions: 'साफ-सुथरे कपड़े और एप्रन। स्वच्छता का पूरा ध्यान रखें।',
    is_first_job: true,
    status: 'pending_admin_approval',
    created_at: '2026-11-18T08:45:00Z',
    skills: [
      { id: 'sk-3', name: 'सब्जी कटिंग' },
      { id: 'sk-4', name: 'भोजन परोसना' },
    ],
  },
];

export const fallbackMasterJobs: AdminJobRecord[] = [
  ...fallbackPendingJobs,
  {
    id: 'job-ghz-003',
    business_id: 'b-ghazipur-3',
    business_name: 'रॉयल हेरिटेज लॉन',
    business_category: 'marriage_hall',
    business_verification_status: 'verified',
    contact_person: 'अनिल कुशवाहा',
    contact_phone: '+91 98765 11223',
    category_id: 'cat-cleaners',
    category_name: 'सफाई कर्मी (Cleaners)',
    title: '6 सफाई कर्मी मैरिज हॉल नाइट शिफ्ट',
    description: 'कार्यक्रम उपरांत लॉन एवं टेबल की पूर्ण स्वच्छता।',
    venue_name: 'रॉयल हेरिटेज लॉन',
    reporting_address: 'रविंद्रपुरी रोड, गाजीपुर',
    locality: 'Ravindrapuri',
    city: 'Ghazipur',
    pincode: '233001',
    shift_date: '2026-11-24',
    start_time: '22:00:00',
    end_time: '04:00:00',
    is_overnight: true,
    workers_needed: 6,
    workers_confirmed: 4,
    wage_amount: 550.0,
    wage_rate_unit: 'per_shift',
    food_provided: true,
    transport_provided: false,
    is_first_job: false,
    status: 'published',
    published_at: '2026-11-17T12:00:00Z',
    created_at: '2026-11-17T11:30:00Z',
    skills: [{ id: 'sk-5', name: 'हॉल सफाई' }],
  },
];

/**
 * Fetch pending first-job submissions for Admin Approval Queue
 */
export async function fetchJobApprovalsQueue(): Promise<AdminJobRecord[]> {
  if (!isSupabaseConfigured) {
    return fallbackPendingJobs;
  }

  try {
    const { data, error } = await supabase
      .from('jobs')
      .select(`
        *,
        categories(name),
        businesses(name, business_type, contact_person, contact_phone, locality, address, verification_status),
        job_skills(skills(id, name))
      `)
      .eq('status', 'pending_admin_approval')
      .order('created_at', { ascending: true });

    if (error || !data) {
      console.warn('[Admin] fetchJobApprovalsQueue query fallback:', error?.message);
      return fallbackPendingJobs;
    }

    return data.map(formatDbJobRecord);
  } catch (err) {
    console.warn('[Admin] fetchJobApprovalsQueue error:', err);
    return fallbackPendingJobs;
  }
}

/**
 * Fetch detailed job record by ID
 */
export async function fetchJobDetail(jobId: string): Promise<AdminJobRecord | null> {
  if (!isSupabaseConfigured) {
    const found = fallbackMasterJobs.find((j) => j.id === jobId);
    return found || fallbackPendingJobs[0];
  }

  try {
    const { data, error } = await supabase
      .from('jobs')
      .select(`
        *,
        categories(name),
        businesses(name, business_type, contact_person, contact_phone, locality, address, verification_status),
        job_skills(skills(id, name))
      `)
      .eq('id', jobId)
      .single();

    if (error || !data) {
      const found = fallbackMasterJobs.find((j) => j.id === jobId);
      return found || null;
    }

    return formatDbJobRecord(data);
  } catch (err) {
    console.warn('[Admin] fetchJobDetail error:', err);
    return fallbackMasterJobs.find((j) => j.id === jobId) || null;
  }
}

/**
 * Execute atomic Admin review for First-Job approval / rejection
 */
export async function adminReviewFirstJob(params: {
  jobId: string;
  action: 'approve' | 'reject';
  rejectionReason?: string;
  internalNotes?: string;
}): Promise<{ success: boolean; message: string }> {
  if (!isSupabaseConfigured) {
    // In local demo mode, simulate successful decision
    const target = fallbackPendingJobs.find((j) => j.id === params.jobId);
    if (target) {
      if (params.action === 'approve') {
        target.status = 'published';
        target.published_at = new Date().toISOString();
      } else {
        target.status = 'rejected';
        target.admin_rejection_reason = params.rejectionReason;
      }
    }
    return {
      success: true,
      message: params.action === 'approve'
        ? 'प्रथम कार्य स्वीकृत किया गया। व्यवसाय के लिए आगामी ऑटो-पब्लिशिंग अनलॉक हो गई है।'
        : 'कार्य अस्वीकृत किया गया।',
    };
  }

  try {
    const { data, error } = await supabase.rpc('admin_review_first_job', {
      p_job_id: params.jobId,
      p_action: params.action,
      p_rejection_reason: params.rejectionReason || null,
      p_internal_notes: params.internalNotes || null,
    });

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,
      message: (data as { message?: string })?.message || 'समीक्षा निर्णय सफलतापूर्वक दर्ज हुआ।',
    };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`व्यवस्थापक समीक्षा विफल: ${message}`);
  }
}

/**
 * Fetch Master Jobs Directory with filters and search
 */
export async function fetchMasterJobsList(params?: {
  search?: string;
  status?: string;
  category?: string;
  page?: number;
  limit?: number;
}): Promise<{ jobs: AdminJobRecord[]; total: number }> {
  if (!isSupabaseConfigured) {
    let filtered = [...fallbackMasterJobs];
    if (params?.status && params.status !== 'all') {
      filtered = filtered.filter((j) => j.status === params.status);
    }
    if (params?.search) {
      const q = params.search.toLowerCase();
      filtered = filtered.filter(
        (j) =>
          j.title.toLowerCase().includes(q) ||
          j.business_name.toLowerCase().includes(q) ||
          j.locality.toLowerCase().includes(q)
      );
    }
    return { jobs: filtered, total: filtered.length };
  }

  try {
    let query = supabase.from('jobs').select(
      `
        *,
        categories(name),
        businesses(name, business_type, contact_person, contact_phone, locality, address, verification_status),
        job_skills(skills(id, name))
      `,
      { count: 'exact' }
    );

    if (params?.status && params.status !== 'all') {
      query = query.eq('status', params.status);
    }
    if (params?.category && params.category !== 'all') {
      query = query.eq('category_id', params.category);
    }
    if (params?.search) {
      query = query.or(`title.ilike.%${params.search}%,locality.ilike.%${params.search}%,venue_name.ilike.%${params.search}%`);
    }

    const page = params?.page || 1;
    const limit = params?.limit || 20;
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, error, count } = await query
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error || !data) {
      return { jobs: fallbackMasterJobs, total: fallbackMasterJobs.length };
    }

    return {
      jobs: data.map(formatDbJobRecord),
      total: count || data.length,
    };
  } catch (err) {
    console.warn('[Admin] fetchMasterJobsList error:', err);
    return { jobs: fallbackMasterJobs, total: fallbackMasterJobs.length };
  }
}

// Helper to format raw database record into AdminJobRecord
function formatDbJobRecord(row: Record<string, unknown>): AdminJobRecord {
  const biz = (row.businesses as Record<string, unknown>) || {};
  const cat = (row.categories as Record<string, unknown>) || {};
  const jobSkills = (row.job_skills as Array<Record<string, unknown>>) || [];

  const parsedSkills: AdminJobSkill[] = [];
  for (const js of jobSkills) {
    if (js.skills && typeof js.skills === 'object') {
      const s = js.skills as Record<string, unknown>;
      parsedSkills.push({
        id: String(s.id || ''),
        name: String(s.name || ''),
      });
    }
  }

  return {
    id: String(row.id || ''),
    business_id: String(row.business_id || ''),
    business_name: String(biz.name || row.business_name || 'व्यापार प्रतिष्ठान'),
    business_category: String(biz.business_type || 'other'),
    business_verification_status: String(biz.verification_status || 'verified'),
    contact_person: (biz.contact_person as string) || null,
    contact_phone: String(biz.contact_phone || '+91 98765 00000'),
    category_id: String(row.category_id || ''),
    category_name: String(cat.name || 'इवेंट कार्य'),
    title: String(row.title || ''),
    description: (row.description as string) || null,
    venue_name: (row.venue_name as string) || null,
    reporting_address: String(row.reporting_address || ''),
    locality: String(row.locality || 'Ghazipur'),
    city: String(row.city || 'Ghazipur'),
    pincode: String(row.pincode || '233001'),
    latitude: typeof row.latitude === 'number' ? row.latitude : null,
    longitude: typeof row.longitude === 'number' ? row.longitude : null,
    shift_date: String(row.shift_date || ''),
    start_time: String(row.start_time || ''),
    end_time: String(row.end_time || ''),
    is_overnight: Boolean(row.is_overnight),
    workers_needed: Number(row.workers_needed || 1),
    workers_confirmed: Number(row.workers_confirmed || 0),
    wage_amount: Number(row.wage_amount || 500),
    wage_rate_unit: String(row.wage_rate_unit || 'per_shift'),
    payment_instructions: (row.payment_instructions as string) || null,
    food_provided: Boolean(row.food_provided),
    food_details: (row.food_details as string) || null,
    transport_provided: Boolean(row.transport_provided),
    transport_details: (row.transport_details as string) || null,
    special_instructions: (row.special_instructions as string) || null,
    is_first_job: Boolean(row.is_first_job),
    status: (row.status as AdminJobRecord['status']) || 'draft',
    admin_rejection_reason: (row.admin_rejection_reason as string) || null,
    approved_by: (row.approved_by as string) || null,
    approved_at: (row.approved_at as string) || null,
    published_at: (row.published_at as string) || null,
    created_at: String(row.created_at || new Date().toISOString()),
    skills: parsedSkills,
  };
}

/**
 * Administrative Emergency Cancellation of a Job
 */
export async function adminCancelJob(params: {
  jobId: string;
  reason: string;
}): Promise<{ success: boolean; message: string }> {
  if (!isSupabaseConfigured) {
    const target = fallbackMasterJobs.find((j) => j.id === params.jobId);
    if (target) {
      target.status = 'cancelled';
    }
    return {
      success: true,
      message: 'कार्य सफलतापूर्वक व्यवस्थापक द्वारा निरस्त किया गया (Demo Mode)।',
    };
  }

  try {
    const { data, error } = await supabase.rpc('admin_cancel_job', {
      p_job_id: params.jobId,
      p_reason: params.reason,
    });

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,
      message: (data as { message?: string })?.message || 'कार्य सफलतापूर्वक निरस्त किया गया।',
    };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`कार्य निरस्तीकरण विफल: ${message}`);
  }
}

