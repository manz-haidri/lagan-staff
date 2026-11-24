import { supabase, isSupabaseConfigured } from './supabase';

export interface BusinessVerificationDocument {
  id: string;
  business_id: string;
  document_type: string;
  storage_path: string;
  file_name: string;
  file_size_bytes: number;
  mime_type: string;
  created_at: string;
}

export interface AdminBusinessRecord {
  id: string;
  name: string;
  business_type: string;
  description?: string | null;
  contact_person?: string | null;
  contact_phone: string;
  country: string;
  state: string;
  district: string;
  city: string;
  locality: string;
  address?: string | null;
  pincode: string;
  latitude?: number | null;
  longitude?: number | null;
  gst_or_trade_id?: string | null;
  verification_status: 'draft' | 'pending' | 'under_review' | 'verified' | 'rejected' | 'suspended';
  rejection_reason?: string | null;
  submitted_at?: string | null;
  reviewed_at?: string | null;
  reviewed_by?: string | null;
  verified_at?: string | null;
  is_first_job_approved: boolean;
  created_at: string;
  documents?: BusinessVerificationDocument[];
}

export interface AdminAuditLog {
  id: string;
  admin_id: string;
  action_type: string;
  entity_type: string;
  entity_id: string;
  details: Record<string, unknown>;
  created_at: string;
}

// Fallback Ghazipur sample businesses for unconfigured/demo environments
export const fallbackAdminBusinesses: AdminBusinessRecord[] = [
  {
    id: 'b-ghazipur-1',
    name: 'राजवाड़ा बैंक्वेट लॉन (Rajwada Banquet Lawn)',
    business_type: 'marriage_hall',
    description: '1500 व्यक्तियों की क्षमता, वातानुकूलित मंडप व पार्किंग सुविधा।',
    contact_person: 'सुनील कुमार सिंह',
    contact_phone: '9876543210',
    country: 'India',
    state: 'Uttar Pradesh',
    district: 'Ghazipur',
    city: 'Ghazipur',
    locality: 'लंका (Lanka)',
    address: 'निकट पीजी कॉलेज गेट, मुख्य सड़क, लंका',
    pincode: '233001',
    latitude: 25.5840,
    longitude: 83.5770,
    gst_or_trade_id: '09AAAAA0000A1Z5',
    verification_status: 'pending',
    submitted_at: '2026-11-18T08:30:00Z',
    is_first_job_approved: false,
    created_at: '2026-11-18T08:00:00Z',
    documents: [
      {
        id: 'doc-1',
        business_id: 'b-ghazipur-1',
        document_type: 'visiting_card',
        storage_path: 'b-ghazipur-1/visiting_card.jpg',
        file_name: 'visiting_card.jpg',
        file_size_bytes: 84200,
        mime_type: 'image/jpeg',
        created_at: '2026-11-18T08:15:00Z',
      },
      {
        id: 'doc-2',
        business_id: 'b-ghazipur-1',
        document_type: 'business_photo',
        storage_path: 'b-ghazipur-1/lawn_entrance.jpg',
        file_name: 'lawn_entrance.jpg',
        file_size_bytes: 312000,
        mime_type: 'image/jpeg',
        created_at: '2026-11-18T08:20:00Z',
      },
    ],
  },
  {
    id: 'b-ghazipur-2',
    name: 'शाही दावत कैटरिंग एजेंसी (Shahi Dawat Caterers)',
    business_type: 'catering_agency',
    description: 'अवधी व पारंपरिक शादी भोज विशेषज्ञ, कुशल हलवाई एवं वेटर टीम।',
    contact_person: 'मो. असलम अंसारी',
    contact_phone: '9876543211',
    country: 'India',
    state: 'Uttar Pradesh',
    district: 'Ghazipur',
    city: 'Ghazipur',
    locality: 'महुआबाग (Mahuabagh)',
    address: 'दुकान नं. 12, महुआबाग चौराहा',
    pincode: '233001',
    verification_status: 'under_review',
    submitted_at: '2026-11-17T14:00:00Z',
    is_first_job_approved: false,
    created_at: '2026-11-17T12:00:00Z',
    documents: [
      {
        id: 'doc-3',
        business_id: 'b-ghazipur-2',
        document_type: 'gst_certificate',
        storage_path: 'b-ghazipur-2/gst_certificate.pdf',
        file_name: 'gst_certificate.pdf',
        file_size_bytes: 420000,
        mime_type: 'application/pdf',
        created_at: '2026-11-17T13:45:00Z',
      },
    ],
  },
  {
    id: 'b-ghazipur-3',
    name: 'रॉयल हेरिटेज मैरिज लॉन (Royal Heritage)',
    business_type: 'marriage_hall',
    description: 'रॉयल थीम आधारित मैरिज वेन्यू व डेकोरेशन।',
    contact_person: 'अमित श्रीवास्तव',
    contact_phone: '9876543212',
    country: 'India',
    state: 'Uttar Pradesh',
    district: 'Ghazipur',
    city: 'Ghazipur',
    locality: 'सिटी स्टेशन (City Station)',
    pincode: '233001',
    verification_status: 'verified',
    submitted_at: '2026-11-15T10:00:00Z',
    reviewed_at: '2026-11-15T12:30:00Z',
    verified_at: '2026-11-15T12:30:00Z',
    is_first_job_approved: true,
    created_at: '2026-11-15T09:00:00Z',
  },
  {
    id: 'b-ghazipur-4',
    name: 'काशी टेंट हाउस एवं लाइट डेकोरेशन',
    business_type: 'tent_house',
    description: 'वाटरप्रूफ जर्मन हैंगर, शामियाना, स्टेज व एलईडी लाइट व्यवस्था।',
    contact_person: 'संजय कुशवाहा',
    contact_phone: '9876543213',
    country: 'India',
    state: 'Uttar Pradesh',
    district: 'Ghazipur',
    city: 'Ghazipur',
    locality: 'मुहम्मदाबाद (Mohammadabad)',
    pincode: '233212',
    verification_status: 'rejected',
    rejection_reason: 'दिए गए पते और संपर्क नंबर का सत्यापन नहीं हो सका। कृपया सही लैंडमार्क दर्ज करें।',
    submitted_at: '2026-11-16T11:00:00Z',
    reviewed_at: '2026-11-16T16:00:00Z',
    is_first_job_approved: false,
    created_at: '2026-11-16T10:00:00Z',
  },
];

/**
 * Fetch all businesses with optional search & filters
 */
export async function fetchAdminBusinesses(filters?: {
  status?: string;
  category?: string;
  search?: string;
}): Promise<AdminBusinessRecord[]> {
  if (!isSupabaseConfigured) {
    let result = [...fallbackAdminBusinesses];
    if (filters?.status && filters.status !== 'all') {
      result = result.filter((b) => b.verification_status === filters.status);
    }
    if (filters?.category && filters.category !== 'all') {
      result = result.filter((b) => b.business_type === filters.category);
    }
    if (filters?.search) {
      const q = filters.search.toLowerCase();
      result = result.filter(
        (b) =>
          b.name.toLowerCase().includes(q) ||
          b.locality.toLowerCase().includes(q) ||
          (b.contact_person && b.contact_person.toLowerCase().includes(q))
      );
    }
    return result;
  }

  try {
    let query = supabase
      .from('businesses')
      .select('*, business_verification_documents(*)');

    if (filters?.status && filters.status !== 'all') {
      query = query.eq('verification_status', filters.status);
    }
    if (filters?.category && filters.category !== 'all') {
      query = query.eq('business_type', filters.category);
    }
    if (filters?.search) {
      query = query.or(
        `name.ilike.%${filters.search}%,locality.ilike.%${filters.search}%,contact_person.ilike.%${filters.search}%`
      );
    }

    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    if (data && data.length > 0) {
      return data.map((item) => ({
        ...item,
        documents: item.business_verification_documents || [],
      })) as AdminBusinessRecord[];
    }
  } catch (err) {
    console.error('[BusinessService] Error querying businesses:', err);
  }

  return fallbackAdminBusinesses;
}

/**
 * Fetch single business details with documents & audit history
 */
export async function fetchAdminBusinessDetail(id: string): Promise<{
  business: AdminBusinessRecord | null;
  auditLogs: AdminAuditLog[];
}> {
  if (!isSupabaseConfigured) {
    const found = fallbackAdminBusinesses.find((b) => b.id === id) || null;
    return {
      business: found,
      auditLogs: [
        {
          id: 'log-demo-1',
          admin_id: 'admin-system',
          action_type: found?.verification_status === 'verified' ? 'approve' : 'pending_submission',
          entity_type: 'business',
          entity_id: id,
          details: { status: found?.verification_status },
          created_at: new Date().toISOString(),
        },
      ],
    };
  }

  try {
    const { data: biz, error: bizError } = await supabase
      .from('businesses')
      .select('*, business_verification_documents(*)')
      .eq('id', id)
      .single();

    if (bizError) throw bizError;

    const { data: logs } = await supabase
      .from('admin_audit_logs')
      .select('*')
      .eq('entity_type', 'business')
      .eq('entity_id', id)
      .order('created_at', { ascending: false });

    return {
      business: {
        ...biz,
        documents: biz.business_verification_documents || [],
      } as AdminBusinessRecord,
      auditLogs: (logs || []) as AdminAuditLog[],
    };
  } catch (err) {
    console.error('[BusinessService] Detail fetch error:', err);
    const found = fallbackAdminBusinesses.find((b) => b.id === id) || null;
    return { business: found, auditLogs: [] };
  }
}

/**
 * Perform Admin Review Action via secure database RPC
 */
export async function performAdminBusinessReview(params: {
  businessId: string;
  action: 'approve' | 'reject' | 'mark_under_review' | 'suspend' | 'reactivate';
  rejectionReason?: string;
}): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    // Demo fallback simulator
    const found = fallbackAdminBusinesses.find((b) => b.id === params.businessId);
    if (found) {
      if (params.action === 'approve' || params.action === 'reactivate') {
        found.verification_status = 'verified';
      } else if (params.action === 'reject') {
        found.verification_status = 'rejected';
        found.rejection_reason = params.rejectionReason;
      } else if (params.action === 'mark_under_review') {
        found.verification_status = 'under_review';
      } else if (params.action === 'suspend') {
        found.verification_status = 'suspended';
      }
      return { success: true };
    }
  }

  try {
    const { data, error } = await supabase.rpc('admin_review_business', {
      p_business_id: params.businessId,
      p_action: params.action,
      p_rejection_reason: params.rejectionReason || null,
    });

    if (error) throw error;
    if (data && data.success) {
      return { success: true };
    }
    return { success: false, error: 'RPC failed' };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('[BusinessService] Review action error:', message);
    return { success: false, error: message };
  }
}

/**
 * Generate a temporary signed download URL for private business documents
 */
export async function getDocumentSignedUrl(storagePath: string): Promise<string | null> {
  if (!isSupabaseConfigured) {
    return '#demo-document-view';
  }

  try {
    const { data, error } = await supabase.storage
      .from('business-documents')
      .createSignedUrl(storagePath, 3600); // 1 hour validity

    if (error) throw error;
    return data?.signedUrl || null;
  } catch (err) {
    console.error('[BusinessService] Signed URL error:', err);
    return null;
  }
}

export function formatCategoryName(categoryType: string): string {
  switch (categoryType) {
    case 'marriage_hall':
      return 'मैरिज लॉन / हॉल (Marriage Hall)';
    case 'catering_agency':
      return 'कैटरिंग एजेंसी (Catering Agency)';
    case 'tent_house':
      return 'टेंट हाउस (Tent House)';
    case 'event_organizer':
      return 'इवेंट ऑर्गनाइज़र (Event Organizer)';
    case 'dj_sound':
      return 'डीजे व साउंड (DJ & Sound)';
    case 'other':
    default:
      return 'अन्य व्यापार (Other)';
  }
}
