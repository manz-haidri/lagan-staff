-- ==============================================================================
-- LAGANSTAFF: PHASE 3 - WORKER REGISTRATION & AUTOMATIC APPROVAL MIGRATION
-- Target: PostgreSQL 15+ (Supabase Managed Engine)
-- ==============================================================================

-- 1. Create Enums if not existing
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'worker_status') THEN
    CREATE TYPE public.worker_status AS ENUM ('pending_profile', 'active', 'suspended');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status') THEN
    CREATE TYPE public.job_status AS ENUM (
      'draft',
      'pending_admin_approval',
      'published',
      'filled',
      'in_progress',
      'completed',
      'cancelled',
      'rejected'
    );
  END IF;
END $$;

-- 2. Master Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for category slug
CREATE INDEX IF NOT EXISTS idx_categories_slug ON public.categories(slug);

-- 3. Master Skills Table
CREATE TABLE IF NOT EXISTS public.skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_category_skill_name UNIQUE(category_id, name)
);

-- Index for skills lookup by category
CREATE INDEX IF NOT EXISTS idx_skills_category_id ON public.skills(category_id);

-- 4. Seed Standard Categories and Skills for Ghazipur Hyperlocal Market
INSERT INTO public.categories (name, slug, description)
VALUES 
  ('Waiters', 'waiters', 'Event and catering food and table service staff'),
  ('Cleaners', 'cleaners', 'Event cleaning, utensil washing, and floor sanitation staff'),
  ('Halwai Helpers', 'halwai_helpers', 'Kitchen assistance for traditional cooks and halwais'),
  ('Loaders', 'loaders', 'Heavy material, tent equipment, and utensil loading/unloading staff'),
  ('Event Helpers', 'event_helpers', 'Stage decoration, lighting, and general hall support staff'),
  ('Other', 'other', 'Specialized and custom temporary event workforce')
ON CONFLICT (slug) DO NOTHING;

-- Seed Skills linked to Categories
DO $$
DECLARE
  v_waiter_id UUID;
  v_cleaner_id UUID;
  v_halwai_id UUID;
  v_loader_id UUID;
  v_event_id UUID;
  v_other_id UUID;
BEGIN
  SELECT id INTO v_waiter_id FROM public.categories WHERE slug = 'waiters';
  SELECT id INTO v_cleaner_id FROM public.categories WHERE slug = 'cleaners';
  SELECT id INTO v_halwai_id FROM public.categories WHERE slug = 'halwai_helpers';
  SELECT id INTO v_loader_id FROM public.categories WHERE slug = 'loaders';
  SELECT id INTO v_event_id FROM public.categories WHERE slug = 'event_helpers';
  SELECT id INTO v_other_id FROM public.categories WHERE slug = 'other';

  -- Waiters Skills
  IF v_waiter_id IS NOT NULL THEN
    INSERT INTO public.skills (category_id, name) VALUES
      (v_waiter_id, 'Table Service (टेबल सेवा)'),
      (v_waiter_id, 'Buffet Counter Service (बुफे काउंटर व्यवस्था)'),
      (v_waiter_id, 'Water & Drinks Serving (पानी व पेय सेवा)')
    ON CONFLICT (category_id, name) DO NOTHING;
  END IF;

  -- Cleaners Skills
  IF v_cleaner_id IS NOT NULL THEN
    INSERT INTO public.skills (category_id, name) VALUES
      (v_cleaner_id, 'Hall & Dining Area Cleaning (हॉल सफाई)'),
      (v_cleaner_id, 'Utensil & Dish Washing (बर्तन धुलाई)'),
      (v_cleaner_id, 'Waste Management & Disposal (कचरा निस्तारण)')
    ON CONFLICT (category_id, name) DO NOTHING;
  END IF;

  -- Halwai Helpers Skills
  IF v_halwai_id IS NOT NULL THEN
    INSERT INTO public.skills (category_id, name) VALUES
      (v_halwai_id, 'Vegetable Cutting & Chopping (सब्जी कटाई)'),
      (v_halwai_id, 'Dough & Batter Preparation (आटा गूंथना)'),
      (v_halwai_id, 'Frying & Cooking Assistance (तलने व पकाने में मदद)')
    ON CONFLICT (category_id, name) DO NOTHING;
  END IF;

  -- Loaders Skills
  IF v_loader_id IS NOT NULL THEN
    INSERT INTO public.skills (category_id, name) VALUES
      (v_loader_id, 'Tent Material Loading/Unloading (टेंट सामान लोड/अनलोड)'),
      (v_loader_id, 'Heavy Cooking Vessel Shifting (भारी पतीले उठाना)'),
      (v_loader_id, 'Furniture & Chair Setup (कुर्सी-मेज लगाना)')
    ON CONFLICT (category_id, name) DO NOTHING;
  END IF;

  -- Event Helpers Skills
  IF v_event_id IS NOT NULL THEN
    INSERT INTO public.skills (category_id, name) VALUES
      (v_event_id, 'Flower Decoration Assistance (फूल सजावट)'),
      (v_event_id, 'Stage & Lighting Setup (स्टेज व लाइट सहायता)'),
      (v_event_id, 'Entry Gate Welcome Helper (स्वागत द्वार सहायक)')
    ON CONFLICT (category_id, name) DO NOTHING;
  END IF;

  -- Other Skills
  IF v_other_id IS NOT NULL THEN
    INSERT INTO public.skills (category_id, name) VALUES
      (v_other_id, 'General Helper (सामान्य सहायक)'),
      (v_other_id, 'Custom Event Work (अन्य विशेष कार्य)')
    ON CONFLICT (category_id, name) DO NOTHING;
  END IF;
END $$;

-- 5. Worker Profiles Table
CREATE TABLE IF NOT EXISTS public.worker_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  locality VARCHAR(150) NOT NULL,
  city VARCHAR(100) DEFAULT 'Ghazipur' NOT NULL,
  district VARCHAR(100) DEFAULT 'Ghazipur' NOT NULL,
  pincode VARCHAR(10) NOT NULL,
  latitude NUMERIC(10, 7) NULL,
  longitude NUMERIC(10, 7) NULL,
  selfie_storage_path TEXT NULL,
  status public.worker_status DEFAULT 'pending_profile' NOT NULL,
  is_selfie_verified BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_worker_profiles_user_id ON public.worker_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_worker_profiles_status ON public.worker_profiles(status);

-- 6. Worker Skills Join Table
CREATE TABLE IF NOT EXISTS public.worker_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_profile_id UUID NOT NULL REFERENCES public.worker_profiles(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES public.skills(id) ON DELETE CASCADE,
  custom_skill_name VARCHAR(150) NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_worker_skill UNIQUE(worker_profile_id, skill_id)
);

CREATE INDEX IF NOT EXISTS idx_worker_skills_worker ON public.worker_skills(worker_profile_id);
CREATE INDEX IF NOT EXISTS idx_worker_skills_skill ON public.worker_skills(skill_id);

-- 7. Minimal Businesses Table (needed for job relations)
CREATE TABLE IF NOT EXISTS public.businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name VARCHAR(150) NOT NULL,
  locality VARCHAR(150) NOT NULL,
  city VARCHAR(100) DEFAULT 'Ghazipur' NOT NULL,
  contact_phone VARCHAR(20) NOT NULL,
  is_first_job_approved BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_businesses_created_by ON public.businesses(created_by);

-- 8. Jobs Table (Minimal read-only schema for Phase 3 worker browsing)
CREATE TABLE IF NOT EXISTS public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  reporting_address TEXT NOT NULL,
  shift_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  workers_needed INTEGER NOT NULL CHECK (workers_needed > 0),
  workers_confirmed INTEGER DEFAULT 0 NOT NULL,
  wage_amount NUMERIC(10, 2) NOT NULL CHECK (wage_amount > 0),
  wage_rate_unit VARCHAR(20) DEFAULT 'per_shift' NOT NULL,
  status public.job_status DEFAULT 'draft' NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_shift_date ON public.jobs(shift_date);

-- 9. Private Supabase Storage Bucket for Worker Selfies
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'worker-selfies',
  'worker-selfies',
  FALSE,
  2097152, -- 2MB maximum limit guard (client compresses to <100KB)
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = FALSE,
  file_size_limit = 2097152,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Storage RLS Policies
-- Allow authenticated user to upload only to their own directory: worker-selfies/<uid>/...
DROP POLICY IF EXISTS "worker_selfies_insert_own" ON storage.objects;
CREATE POLICY "worker_selfies_insert_own"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'worker-selfies' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated user to read only their own selfie, or admin to read all selfies
DROP POLICY IF EXISTS "worker_selfies_select_own" ON storage.objects;
CREATE POLICY "worker_selfies_select_own"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'worker-selfies' AND
  (
    (storage.foldername(name))[1] = auth.uid()::text OR
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  )
);

-- Allow authenticated user to update/overwrite their own selfie
DROP POLICY IF EXISTS "worker_selfies_update_own" ON storage.objects;
CREATE POLICY "worker_selfies_update_own"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'worker-selfies' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 10. Enable Row Level Security (RLS) on all tables
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

-- 11. Table RLS Policies
-- Categories: Read-only for authenticated
DROP POLICY IF EXISTS "categories_select_all" ON public.categories;
CREATE POLICY "categories_select_all"
ON public.categories FOR SELECT
TO authenticated
USING (is_active = TRUE);

-- Skills: Read-only for authenticated
DROP POLICY IF EXISTS "skills_select_all" ON public.skills;
CREATE POLICY "skills_select_all"
ON public.skills FOR SELECT
TO authenticated
USING (is_active = TRUE);

-- Worker Profiles: Users can select their own profile; Admins can select any
DROP POLICY IF EXISTS "worker_profiles_select_own" ON public.worker_profiles;
CREATE POLICY "worker_profiles_select_own"
ON public.worker_profiles FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin')
);

-- Worker Skills: Users can select their own skills
DROP POLICY IF EXISTS "worker_skills_select_own" ON public.worker_skills;
CREATE POLICY "worker_skills_select_own"
ON public.worker_skills FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.worker_profiles wp
    WHERE wp.id = worker_skills.worker_profile_id AND wp.user_id = auth.uid()
  ) OR
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin')
);

-- Businesses: Authenticated can view active businesses
DROP POLICY IF EXISTS "businesses_select_all" ON public.businesses;
CREATE POLICY "businesses_select_all"
ON public.businesses FOR SELECT
TO authenticated
USING (TRUE);

-- Jobs: Authenticated workers can view published jobs
DROP POLICY IF EXISTS "jobs_select_published" ON public.jobs;
CREATE POLICY "jobs_select_published"
ON public.jobs FOR SELECT
TO authenticated
USING (
  status = 'published' OR
  created_by = auth.uid() OR
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin')
);

-- 12. Transaction-Safe RPC: Complete Worker Onboarding & Automatic Activation
CREATE OR REPLACE FUNCTION public.complete_worker_onboarding(
  p_full_name TEXT,
  p_locality TEXT,
  p_pincode TEXT,
  p_latitude NUMERIC,
  p_longitude NUMERIC,
  p_selfie_path TEXT,
  p_skill_ids UUID[],
  p_custom_skill TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, storage, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_clean_name TEXT;
  v_clean_locality TEXT;
  v_clean_pincode TEXT;
  v_worker_role public.app_role;
  v_worker_profile_id UUID;
  v_skill_id UUID;
BEGIN
  -- 1. Check Caller Authentication
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication session is required.' USING ERRCODE = '42501';
  END IF;

  -- 2. Verify Caller Has Worker Role
  SELECT role INTO v_worker_role
  FROM public.user_roles
  WHERE user_id = v_uid AND role = 'worker';

  IF v_worker_role IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: User does not have worker role.' USING ERRCODE = '42501';
  END IF;

  -- 3. Validate Mandatory Full Name
  v_clean_name := BTRIM(p_full_name);
  IF v_clean_name IS NULL OR LENGTH(v_clean_name) < 2 THEN
    RAISE EXCEPTION 'INVALID_NAME: Full name must be at least 2 characters.' USING ERRCODE = '22023';
  END IF;

  -- 4. Validate Locality
  v_clean_locality := BTRIM(p_locality);
  IF v_clean_locality IS NULL OR LENGTH(v_clean_locality) < 2 THEN
    RAISE EXCEPTION 'INVALID_LOCALITY: Locality must be at least 2 characters.' USING ERRCODE = '22023';
  END IF;

  -- 5. Validate PIN Code (Indian 6-digit PIN)
  v_clean_pincode := BTRIM(p_pincode);
  IF v_clean_pincode IS NULL OR NOT (v_clean_pincode ~ '^[1-9][0-9]{5}$') THEN
    RAISE EXCEPTION 'INVALID_PINCODE: PIN code must be a valid 6-digit Indian PIN.' USING ERRCODE = '22023';
  END IF;

  -- 6. Validate Selfie Path
  IF p_selfie_path IS NULL OR LENGTH(BTRIM(p_selfie_path)) < 5 THEN
    RAISE EXCEPTION 'MISSING_SELFIE: A valid camera selfie must be uploaded.' USING ERRCODE = '22023';
  END IF;

  -- Security check: selfie path must belong to the user's directory
  IF NOT (p_selfie_path LIKE v_uid::TEXT || '/%') THEN
    RAISE EXCEPTION 'INVALID_STORAGE_PATH: Selfie path must reside in user folder.' USING ERRCODE = '42501';
  END IF;

  -- 7. Validate Skills Array
  IF p_skill_ids IS NULL OR ARRAY_LENGTH(p_skill_ids, 1) = 0 THEN
    RAISE EXCEPTION 'MISSING_SKILLS: Worker must select at least one skill.' USING ERRCODE = '22023';
  END IF;

  -- 8. Update Core Profile Full Name
  UPDATE public.profiles
  SET full_name = v_clean_name,
      updated_at = NOW()
  WHERE id = v_uid;

  -- 9. Upsert Worker Profile with AUTOMATIC APPROVAL (status = 'active')
  INSERT INTO public.worker_profiles (
    user_id,
    locality,
    city,
    district,
    pincode,
    latitude,
    longitude,
    selfie_storage_path,
    is_selfie_verified,
    status,
    updated_at
  )
  VALUES (
    v_uid,
    v_clean_locality,
    'Ghazipur',
    'Ghazipur',
    v_clean_pincode,
    p_latitude,
    p_longitude,
    p_selfie_path,
    TRUE,
    'active', -- Automatic Worker Activation!
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    locality = EXCLUDED.locality,
    city = EXCLUDED.city,
    district = EXCLUDED.district,
    pincode = EXCLUDED.pincode,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    selfie_storage_path = EXCLUDED.selfie_storage_path,
    is_selfie_verified = TRUE,
    status = CASE 
      WHEN public.worker_profiles.status = 'suspended' THEN 'suspended' -- retain suspension if already suspended
      ELSE 'active'
    END,
    updated_at = NOW()
  RETURNING id INTO v_worker_profile_id;

  -- 10. Update Worker Skills (Delete old skills, insert selected skills)
  DELETE FROM public.worker_skills
  WHERE worker_profile_id = v_worker_profile_id;

  FOREACH v_skill_id IN ARRAY p_skill_ids
  LOOP
    INSERT INTO public.worker_skills (
      worker_profile_id,
      skill_id,
      custom_skill_name,
      created_at
    )
    VALUES (
      v_worker_profile_id,
      v_skill_id,
      p_custom_skill,
      NOW()
    )
    ON CONFLICT (worker_profile_id, skill_id) DO NOTHING;
  END LOOP;

  -- 11. Return Confirmed Worker Activation Payload
  RETURN jsonb_build_object(
    'success', TRUE,
    'worker_profile_id', v_worker_profile_id,
    'user_id', v_uid,
    'full_name', v_clean_name,
    'locality', v_clean_locality,
    'city', 'Ghazipur',
    'pincode', v_clean_pincode,
    'selfie_storage_path', p_selfie_path,
    'status', 'active',
    'activated_at', NOW()
  );
END;
$$;

-- 13. Helper RPC: Get Current Worker Onboarding & Profile Status
CREATE OR REPLACE FUNCTION public.get_worker_onboarding_status()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_profile RECORD;
  v_worker_profile RECORD;
  v_skills JSONB;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('authenticated', FALSE);
  END IF;

  -- Get core profile
  SELECT id, phone, full_name, avatar_url INTO v_profile
  FROM public.profiles
  WHERE id = v_uid;

  -- Get worker profile
  SELECT 
    id, locality, city, district, pincode, 
    latitude, longitude, selfie_storage_path, 
    status, is_selfie_verified, created_at, updated_at
  INTO v_worker_profile
  FROM public.worker_profiles
  WHERE user_id = v_uid;

  IF v_worker_profile.id IS NULL THEN
    RETURN jsonb_build_object(
      'authenticated', TRUE,
      'has_worker_profile', FALSE,
      'status', 'pending_profile',
      'full_name', v_profile.full_name,
      'phone', v_profile.phone
    );
  END IF;

  -- Fetch linked skills
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'skill_id', s.id,
        'skill_name', s.name,
        'category_id', c.id,
        'category_name', c.name,
        'custom_skill_name', ws.custom_skill_name
      )
    ),
    '[]'::jsonb
  ) INTO v_skills
  FROM public.worker_skills ws
  JOIN public.skills s ON s.id = ws.skill_id
  JOIN public.categories c ON c.id = s.category_id
  WHERE ws.worker_profile_id = v_worker_profile.id;

  RETURN jsonb_build_object(
    'authenticated', TRUE,
    'has_worker_profile', TRUE,
    'status', v_worker_profile.status::TEXT,
    'is_selfie_verified', v_worker_profile.is_selfie_verified,
    'worker_profile_id', v_worker_profile.id,
    'user_id', v_uid,
    'full_name', v_profile.full_name,
    'phone', v_profile.phone,
    'locality', v_worker_profile.locality,
    'city', v_worker_profile.city,
    'district', v_worker_profile.district,
    'pincode', v_worker_profile.pincode,
    'latitude', v_worker_profile.latitude,
    'longitude', v_worker_profile.longitude,
    'selfie_storage_path', v_worker_profile.selfie_storage_path,
    'skills', v_skills
  );
END;
$$;
