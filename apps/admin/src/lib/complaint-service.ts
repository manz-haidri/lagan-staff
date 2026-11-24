import { supabase, isSupabaseConfigured } from './supabase';

export interface AdminComplaintNote {
  id: string;
  admin_id: string;
  note: string;
  created_at: string;
}

export interface AdminComplaintRecord {
  id: string;
  submitted_by: string;
  submitted_by_name: string;
  reported_user_name?: string | null;
  business_name?: string | null;
  job_title?: string | null;
  category: 'worker_no_show' | 'owner_cancellation' | 'payment_dispute' | 'misbehaviour' | 'incorrect_job_info' | 'fake_profile' | 'other';
  description: string;
  evidence_path?: string | null;
  complaint_status: 'open' | 'under_review' | 'resolved' | 'dismissed';
  admin_notes?: string | null;
  submitted_at: string;
  resolved_at?: string | null;
  notes_history?: AdminComplaintNote[];
}

export const fallbackAdminComplaints: AdminComplaintRecord[] = [
  {
    id: 'cmp-ghz-001',
    submitted_by: 'usr-own-1',
    submitted_by_name: 'सुनील कुमार सिंह (राजवाड़ा लॉन)',
    reported_user_name: 'विकास यादव (Worker)',
    business_name: 'राजवाड़ा बैंक्वेट लॉन',
    job_title: '10 अनुभवी वेटर शादी समारोह के लिए',
    category: 'worker_no_show',
    description: 'कार्यकर्ता ने शिफ्ट की पुष्टि की थी परन्तु निर्धारित समय पर नहीं पहुंचे और कॉल भी नहीं उठाया।',
    evidence_path: null,
    complaint_status: 'under_review',
    admin_notes: 'कार्यकर्ता से संपर्क का प्रयास किया जा रहा है। उपस्थिति रिकॉर्ड में नो-शो अंकित है।',
    submitted_at: '2026-11-18T10:00:00Z',
    notes_history: [
      {
        id: 'cn-1',
        admin_id: 'admin-1',
        note: 'शिकायत दर्ज की गई। कार्यकर्ता का पिछला रिकॉर्ड जांचा जा रहा है।',
        created_at: '2026-11-18T10:15:00Z',
      },
    ],
  },
  {
    id: 'cmp-ghz-002',
    submitted_by: 'usr-2',
    submitted_by_name: 'सोनू वर्मा (Worker)',
    reported_user_name: 'शाही दावत कैटरर्स (Owner)',
    business_name: 'शाही दावत कैटरर्स',
    job_title: '4 हलवाई रसोई सहायक',
    category: 'payment_dispute',
    description: 'शिफ्ट समाप्ति के बाद तय मानदेय ₹750 के स्थान पर ₹600 का भुगतान किया गया।',
    evidence_path: null,
    complaint_status: 'open',
    submitted_at: '2026-11-18T11:30:00Z',
    notes_history: [],
  },
  {
    id: 'cmp-ghz-003',
    submitted_by: 'usr-3',
    submitted_by_name: 'अमित कुमार सिंह (Worker)',
    reported_user_name: 'काशी टेंट हाउस (Owner)',
    business_name: 'काशी टेंट हाउस',
    job_title: 'टेंट रिगर कार्य',
    category: 'owner_cancellation',
    description: 'शिफ्ट प्रारंभ होने से 30 मिनट पूर्व बिना कारण बताए कार्य रद्द कर दिया गया।',
    evidence_path: null,
    complaint_status: 'resolved',
    admin_notes: 'आयोजक को चेतावनी दी गई और भविष्य में 2 घंटे पूर्व सूचना देने का निर्देश दिया गया।',
    submitted_at: '2026-11-16T14:00:00Z',
    resolved_at: '2026-11-17T09:00:00Z',
    notes_history: [
      {
        id: 'cn-2',
        admin_id: 'admin-1',
        note: 'आयोजक और कार्यकर्ता दोनों से बातचीत कर समाधान किया गया।',
        created_at: '2026-11-17T09:00:00Z',
      },
    ],
  },
];

export async function fetchAdminComplaints(filters?: {
  status?: string;
  category?: string;
  search?: string;
}): Promise<AdminComplaintRecord[]> {
  if (!isSupabaseConfigured) {
    let result = [...fallbackAdminComplaints];
    if (filters?.status && filters.status !== 'all') {
      result = result.filter((c) => c.complaint_status === filters.status);
    }
    if (filters?.category && filters.category !== 'all') {
      result = result.filter((c) => c.category === filters.category);
    }
    if (filters?.search) {
      const q = filters.search.toLowerCase();
      result = result.filter(
        (c) =>
          c.description.toLowerCase().includes(q) ||
          c.submitted_by_name.toLowerCase().includes(q) ||
          (c.business_name && c.business_name.toLowerCase().includes(q))
      );
    }
    return result;
  }

  try {
    let query = supabase
      .from('complaints')
      .select('*, profiles!submitted_by(full_name), businesses(name), jobs(title)');

    if (filters?.status && filters.status !== 'all') {
      query = query.eq('complaint_status', filters.status);
    }
    if (filters?.category && filters.category !== 'all') {
      query = query.eq('category', filters.category);
    }

    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    if (data && data.length > 0) {
      return data.map((item) => ({
        id: item.id,
        submitted_by: item.submitted_by,
        submitted_by_name: item.profiles?.full_name || 'उपयोगकर्ता',
        reported_user_name: null,
        business_name: item.businesses?.name,
        job_title: item.jobs?.title,
        category: item.category,
        description: item.description,
        evidence_path: item.evidence_path,
        complaint_status: item.complaint_status,
        admin_notes: item.admin_notes,
        submitted_at: item.submitted_at || item.created_at,
        resolved_at: item.resolved_at,
      }));
    }
  } catch (err) {
    console.error('[ComplaintService] Fetch error:', err);
  }

  return fallbackAdminComplaints;
}

export async function fetchAdminComplaintDetail(id: string): Promise<AdminComplaintRecord | null> {
  const all = await fetchAdminComplaints();
  return all.find((c) => c.id === id) || null;
}

export async function resolveComplaint(
  complaintId: string,
  status: 'under_review' | 'resolved' | 'dismissed',
  notes?: string
): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    const found = fallbackAdminComplaints.find((c) => c.id === complaintId);
    if (found) {
      found.complaint_status = status;
      found.admin_notes = notes;
      return { success: true };
    }
  }

  try {
    const { data, error } = await supabase.rpc('admin_resolve_complaint', {
      p_complaint_id: complaintId,
      p_status: status,
      p_admin_notes: notes || null,
    });
    if (error) throw error;
    if (data?.success) return { success: true };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, error: msg };
  }

  return { success: true };
}

export async function addComplaintNote(
  complaintId: string,
  note: string
): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    const found = fallbackAdminComplaints.find((c) => c.id === complaintId);
    if (found) {
      found.notes_history = [
        ...(found.notes_history || []),
        { id: `cn-${Date.now()}`, admin_id: 'admin', note, created_at: new Date().toISOString() },
      ];
      return { success: true };
    }
  }

  try {
    const { data, error } = await supabase.rpc('admin_add_complaint_note', {
      p_complaint_id: complaintId,
      p_note: note,
    });
    if (error) throw error;
    if (data?.success) return { success: true };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, error: msg };
  }

  return { success: true };
}

export function formatComplaintCategory(cat: string): string {
  switch (cat) {
    case 'worker_no_show':
      return 'कार्यकर्ता अनुपस्थिति (No-Show)';
    case 'owner_cancellation':
      return 'आयोजक द्वारा अंतिम समय रद्दीकरण';
    case 'payment_dispute':
      return 'मानदेय / भुगतान विवाद';
    case 'misbehaviour':
      return 'अभद्र व्यवहार / अनुशासनहीनता';
    case 'incorrect_job_info':
      return 'गलत कार्य विवरण या स्थल';
    case 'fake_profile':
      return 'फर्जी प्रोफाइल / गलत पहचान';
    case 'other':
    default:
      return 'अन्य समस्या (Other)';
  }
}
