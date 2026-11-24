import { supabase, isSupabaseConfigured } from './supabase';

export interface AdminCategoryRecord {
  id: string;
  name: string;
  slug: string;
  description?: string | null;
  is_active: boolean;
  display_order: number;
  created_at: string;
  skills_count: number;
}

export const fallbackAdminCategories: AdminCategoryRecord[] = [
  {
    id: 'cat-waiters',
    name: 'वेटर (Waiters)',
    slug: 'waiters',
    description: 'शादी, पार्टी व पारिवारिक आयोजनों में भोजन व पेय परोसने वाले कुशल कार्यकर्ता।',
    is_active: true,
    display_order: 1,
    created_at: '2026-11-15T00:00:00Z',
    skills_count: 5,
  },
  {
    id: 'cat-cleaners',
    name: 'सफाई कर्मी (Cleaners)',
    slug: 'cleaners',
    description: 'आयोजन स्थल, बर्तन व परिसर की स्वच्छता हेतु उत्तरदायी सहायक।',
    is_active: true,
    display_order: 2,
    created_at: '2026-11-15T00:00:00Z',
    skills_count: 4,
  },
  {
    id: 'cat-halwai',
    name: 'हलवाई हेल्पर (Halwai Helpers)',
    slug: 'halwai_helpers',
    description: 'मिठाई व मुख्य पकवान निर्माण में मुख्य कारीगर के सहायक रसोइये।',
    is_active: true,
    display_order: 3,
    created_at: '2026-11-15T00:00:00Z',
    skills_count: 6,
  },
  {
    id: 'cat-loaders',
    name: 'लोडर / सामान ढुलाई (Loaders)',
    slug: 'loaders',
    description: 'टेंट सामग्री, कुर्सी-मेज, राशन व भारी उपकरण लोडिंग एवं अनलोडिंग।',
    is_active: true,
    display_order: 4,
    created_at: '2026-11-15T00:00:00Z',
    skills_count: 3,
  },
  {
    id: 'cat-event',
    name: 'इवेंट हेल्पर (Event Helpers)',
    slug: 'event_helpers',
    description: 'सामान्य आयोजन सहायता, स्टेज सजावट व स्वागत व्यवस्था।',
    is_active: true,
    display_order: 5,
    created_at: '2026-11-15T00:00:00Z',
    skills_count: 4,
  },
  {
    id: 'cat-other',
    name: 'अन्य कार्य (Other Workers)',
    slug: 'other',
    description: 'विविध अस्थायी कार्य जो विशिष्ट श्रेणी में नहीं आते।',
    is_active: true,
    display_order: 6,
    created_at: '2026-11-15T00:00:00Z',
    skills_count: 2,
  },
];

export async function fetchAdminCategories(): Promise<AdminCategoryRecord[]> {
  if (!isSupabaseConfigured) {
    return fallbackAdminCategories;
  }

  try {
    const { data, error } = await supabase
      .from('categories')
      .select('*, skills(count)')
      .order('display_order', { ascending: true });

    if (error) throw error;
    if (data && data.length > 0) {
      return data.map((item) => ({
        id: item.id,
        name: item.name,
        slug: item.slug,
        description: item.description,
        is_active: item.is_active,
        display_order: item.display_order || 0,
        created_at: item.created_at,
        skills_count: item.skills?.[0]?.count || 0,
      }));
    }
  } catch (err) {
    console.error('[CategoryService] Fetch error:', err);
  }

  return fallbackAdminCategories;
}

export async function upsertCategory(params: {
  id?: string;
  name: string;
  slug: string;
  description?: string;
  isActive?: boolean;
  displayOrder?: number;
}): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    if (params.id) {
      const found = fallbackAdminCategories.find((c) => c.id === params.id);
      if (found) {
        found.name = params.name;
        found.slug = params.slug;
        found.description = params.description;
        if (params.isActive !== undefined) found.is_active = params.isActive;
        if (params.displayOrder !== undefined) found.display_order = params.displayOrder;
      }
    } else {
      fallbackAdminCategories.push({
        id: `cat-${Date.now()}`,
        name: params.name,
        slug: params.slug,
        description: params.description,
        is_active: params.isActive ?? true,
        display_order: params.displayOrder ?? fallbackAdminCategories.length + 1,
        created_at: new Date().toISOString(),
        skills_count: 0,
      });
    }
    return { success: true };
  }

  try {
    const { data, error } = await supabase.rpc('admin_upsert_category', {
      p_id: params.id || null,
      p_name: params.name,
      p_slug: params.slug,
      p_description: params.description || null,
      p_is_active: params.isActive ?? true,
      p_display_order: params.displayOrder ?? 0,
    });
    if (error) throw error;
    if (data?.success) return { success: true };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, error: msg };
  }

  return { success: true };
}

export async function toggleCategoryStatus(
  categoryId: string,
  isActive: boolean
): Promise<{ success: boolean; error?: string }> {
  if (!isSupabaseConfigured) {
    const found = fallbackAdminCategories.find((c) => c.id === categoryId);
    if (found) {
      found.is_active = isActive;
      return { success: true };
    }
  }

  try {
    const { data, error } = await supabase.rpc('admin_toggle_category_status', {
      p_category_id: categoryId,
      p_is_active: isActive,
    });
    if (error) throw error;
    if (data?.success) return { success: true };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, error: msg };
  }

  return { success: true };
}
