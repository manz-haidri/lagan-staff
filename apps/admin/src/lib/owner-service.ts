import { supabase, isSupabaseConfigured } from './supabase';

export interface AdminOwnerBusinessSummary {
  id: string;
  name: string;
  business_type: string;
  verification_status: string;
  locality: string;
}

export interface AdminOwnerRecord {
  user_id: string;
  full_name: string;
  mobile_number: string;
  created_at: string;
  businesses_count: number;
  total_jobs_posted: number;
  businesses: AdminOwnerBusinessSummary[];
}

export const fallbackAdminOwners: AdminOwnerRecord[] = [
  {
    user_id: 'usr-own-1',
    full_name: 'सुनील कुमार सिंह (Sunil Singh)',
    mobile_number: '+91 98765 44332',
    created_at: '2026-11-15T08:00:00Z',
    businesses_count: 1,
    total_jobs_posted: 4,
    businesses: [
      {
        id: 'b-ghazipur-1',
        name: 'राजवाड़ा बैंक्वेट लॉन (Rajwada Banquet Lawn)',
        business_type: 'marriage_hall',
        verification_status: 'verified',
        locality: 'Lanka',
      },
    ],
  },
  {
    user_id: 'usr-own-2',
    full_name: 'मोहम्मद असलम अंसारी (Aslam Ansari)',
    mobile_number: '+91 98765 22119',
    created_at: '2026-11-16T10:00:00Z',
    businesses_count: 1,
    total_jobs_posted: 2,
    businesses: [
      {
        id: 'b-ghazipur-2',
        name: 'शाही दावत कैटरर्स (Shahi Dawat Caterers)',
        business_type: 'catering_agency',
        verification_status: 'under_review',
        locality: 'Mahuabagh',
      },
    ],
  },
  {
    user_id: 'usr-own-3',
    full_name: 'अमित श्रीवास्तव (Amit Srivastava)',
    mobile_number: '+91 98765 33445',
    created_at: '2026-11-14T09:00:00Z',
    businesses_count: 1,
    total_jobs_posted: 8,
    businesses: [
      {
        id: 'b-ghazipur-3',
        name: 'रॉयल हेरिटेज मैरिज लॉन (Royal Heritage)',
        business_type: 'marriage_hall',
        verification_status: 'verified',
        locality: 'City Station',
      },
    ],
  },
];

export async function fetchAdminOwners(filters?: { search?: string }): Promise<AdminOwnerRecord[]> {
  if (!isSupabaseConfigured) {
    let result = [...fallbackAdminOwners];
    if (filters?.search) {
      const q = filters.search.toLowerCase();
      result = result.filter(
        (o) =>
          o.full_name.toLowerCase().includes(q) ||
          o.mobile_number.includes(q) ||
          o.businesses.some((b) => b.name.toLowerCase().includes(q))
      );
    }
    return result;
  }

  try {
    const { data: ownersData, error } = await supabase
      .from('user_roles')
      .select('user_id, profiles!user_id(full_name, mobile_number, created_at)')
      .eq('role', 'owner');

    if (error) throw error;

    if (ownersData && ownersData.length > 0) {
      const results: AdminOwnerRecord[] = [];

      for (const item of ownersData) {
        const uId = item.user_id;
        const profile = (item as unknown as { profiles: { full_name: string; mobile_number: string; created_at: string } }).profiles;

        const { data: bizData } = await supabase
          .from('businesses')
          .select('id, name, business_type, verification_status, locality')
          .eq('created_by', uId);

        const { count: jobsCount } = await supabase
          .from('jobs')
          .select('id', { count: 'exact', head: true })
          .eq('created_by', uId);

        results.push({
          user_id: uId,
          full_name: profile?.full_name || 'व्यवसाय स्वामी',
          mobile_number: profile?.mobile_number || '-',
          created_at: profile?.created_at || new Date().toISOString(),
          businesses_count: (bizData || []).length,
          total_jobs_posted: jobsCount || 0,
          businesses: (bizData || []) as AdminOwnerBusinessSummary[],
        });
      }

      if (filters?.search) {
        const q = filters.search.toLowerCase();
        return results.filter(
          (o) =>
            o.full_name.toLowerCase().includes(q) ||
            o.mobile_number.includes(q) ||
            o.businesses.some((b) => b.name.toLowerCase().includes(q))
        );
      }

      return results;
    }
  } catch (err) {
    console.error('[OwnerService] Error fetching owners:', err);
  }

  return fallbackAdminOwners;
}

export async function fetchAdminOwnerDetail(userId: string): Promise<AdminOwnerRecord | null> {
  const owners = await fetchAdminOwners();
  return owners.find((o) => o.user_id === userId) || null;
}
