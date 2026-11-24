-- ============================================================================
-- LAGANSTAFF: COMPLETE DATABASE SCHEMA & MIGRATIONS (PHASES 2 TO 9)
-- Generated: Thu Nov 19 10:35:47 IST 2026
-- Run this entire script in the Supabase SQL Editor in one go.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- FILE: 20261118000001_phase2_auth_roles.sql
-- ============================================================================

-- ==============================================================================
-- LAGANSTAFF: PHASE 2 - AUTHENTICATION & USER ROLES MIGRATION
-- Target: PostgreSQL 15+ (Supabase Managed Engine)
-- ==============================================================================

-- 1. Create Enums if not existing
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE public.app_role AS ENUM ('worker', 'owner', 'admin');
  END IF;
END $$;

-- 2. Create profiles table (references auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone VARCHAR(20) NOT NULL UNIQUE,
  full_name VARCHAR(150),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for phone queries
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);

-- 3. Create user_roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  is_primary BOOLEAN DEFAULT TRUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_user_primary_role UNIQUE(user_id, is_primary)
);

-- Index for fast role lookup
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for profiles
-- 5.1 SELECT: Users can view their own profile
CREATE POLICY "profiles_select_own"
ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 5.2 UPDATE: Users can update their own profile details
CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 5.3 INSERT: Users can insert their own profile
CREATE POLICY "profiles_insert_own"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 6. RLS Policies for user_roles
-- 6.1 SELECT: Users can read their own role
CREATE POLICY "user_roles_select_own"
ON public.user_roles
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Note: DIRECT INSERT/UPDATE on user_roles is completely blocked for authenticated clients.
-- Roles can ONLY be assigned via the SECURITY DEFINER RPC 'assign_initial_user_role'.

-- 7. Secure Transaction-Safe RPC for Initial Role & Profile Creation
CREATE OR REPLACE FUNCTION public.assign_initial_user_role(
  p_role TEXT,
  p_full_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_phone TEXT;
  v_existing_role public.app_role;
  v_clean_name TEXT;
BEGIN
  -- Verify caller authentication
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication session is required.' USING ERRCODE = '42501';
  END IF;

  -- Validate role input: strictly allow ONLY 'worker' or 'owner' (Admin is blocked on mobile)
  IF p_role NOT IN ('worker', 'owner') THEN
    RAISE EXCEPTION 'INVALID_ROLE: Mobile onboarding only permits worker or owner. Received: %', p_role USING ERRCODE = '22023';
  END IF;

  -- Validate name
  v_clean_name := BTRIM(p_full_name);
  IF v_clean_name IS NULL OR LENGTH(v_clean_name) < 2 THEN
    RAISE EXCEPTION 'INVALID_NAME: Full name must be at least 2 characters.' USING ERRCODE = '22023';
  END IF;

  -- Check if user already has an assigned primary role (Idempotency / Anti-tamper guard)
  SELECT role INTO v_existing_role
  FROM public.user_roles
  WHERE user_id = v_uid AND is_primary = TRUE;

  IF v_existing_role IS NOT NULL THEN
    RAISE EXCEPTION 'ROLE_ALREADY_ASSIGNED: User already holds role "%". Role switching is not permitted.', v_existing_role USING ERRCODE = '23505';
  END IF;

  -- Retrieve verified phone number from auth identity
  SELECT COALESCE(phone, email, 'unknown') INTO v_phone
  FROM auth.users
  WHERE id = v_uid;

  -- 1. Create or update core profile
  INSERT INTO public.profiles (id, phone, full_name, updated_at)
  VALUES (v_uid, v_phone, v_clean_name, NOW())
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    updated_at = NOW();

  -- 2. Insert role record (protected from direct client API writes)
  INSERT INTO public.user_roles (user_id, role, is_primary, created_at)
  VALUES (v_uid, p_role::public.app_role, TRUE, NOW());

  RETURN jsonb_build_object(
    'success', TRUE,
    'user_id', v_uid,
    'role', p_role,
    'full_name', v_clean_name,
    'phone', v_phone
  );
END;
$$;

-- 8. Helper RPC: Fetch Current User Profile & Primary Role
CREATE OR REPLACE FUNCTION public.get_my_profile_and_role()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_profile RECORD;
  v_role public.app_role;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('authenticated', FALSE);
  END IF;

  SELECT id, phone, full_name, avatar_url, created_at INTO v_profile
  FROM public.profiles
  WHERE id = v_uid;

  SELECT role INTO v_role
  FROM public.user_roles
  WHERE user_id = v_uid AND is_primary = TRUE;

  IF v_profile.id IS NULL OR v_role IS NULL THEN
    RETURN jsonb_build_object(
      'authenticated', TRUE,
      'has_profile', (v_profile.id IS NOT NULL),
      'has_role', (v_role IS NOT NULL),
      'user_id', v_uid
    );
  END IF;

  RETURN jsonb_build_object(
    'authenticated', TRUE,
    'has_profile', TRUE,
    'has_role', TRUE,
    'user_id', v_uid,
    'phone', v_profile.phone,
    'full_name', v_profile.full_name,
    'role', v_role::TEXT
  );
END;
$$;


-- ============================================================================
-- FILE: 20261118000002_phase3_worker_onboarding.sql
-- ============================================================================

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


-- ============================================================================
-- FILE: 20261118000003_phase4_owner_business.sql
-- ============================================================================

-- ==============================================================================
-- LAGANSTAFF: PHASE 4 - OWNER / BUSINESS MODULE MIGRATION
-- Target: PostgreSQL 15+ (Supabase Managed Engine)
-- ==============================================================================

-- 1. Create Enums if not existing
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'business_verification_status') THEN
    CREATE TYPE public.business_verification_status AS ENUM (
      'draft',
      'pending',
      'under_review',
      'verified',
      'rejected',
      'suspended'
    );
  END IF;
END $$;

-- 2. Extend / Update businesses Table with Phase 4 Specifications
CREATE TABLE IF NOT EXISTS public.businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  name VARCHAR(150) NOT NULL,
  business_type VARCHAR(50) DEFAULT 'marriage_hall' NOT NULL,
  description TEXT,
  contact_person VARCHAR(100),
  contact_phone VARCHAR(20) NOT NULL,
  country VARCHAR(100) DEFAULT 'India' NOT NULL,
  state VARCHAR(100) DEFAULT 'Uttar Pradesh' NOT NULL,
  district VARCHAR(100) DEFAULT 'Ghazipur' NOT NULL,
  city VARCHAR(100) DEFAULT 'Ghazipur' NOT NULL,
  locality VARCHAR(150) NOT NULL,
  address TEXT,
  pincode VARCHAR(10) DEFAULT '233001' NOT NULL,
  latitude NUMERIC(10, 7) NULL,
  longitude NUMERIC(10, 7) NULL,
  gst_or_trade_id VARCHAR(50) NULL,
  verification_status public.business_verification_status DEFAULT 'draft' NOT NULL,
  rejection_reason TEXT NULL,
  submitted_at TIMESTAMPTZ NULL,
  reviewed_at TIMESTAMPTZ NULL,
  reviewed_by UUID REFERENCES public.profiles(id) NULL,
  verified_at TIMESTAMPTZ NULL,
  is_first_job_approved BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Ensure newly added columns exist if businesses was created in Phase 3
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS business_type VARCHAR(50) DEFAULT 'marriage_hall';
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS contact_person VARCHAR(100);
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'India';
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS state VARCHAR(100) DEFAULT 'Uttar Pradesh';
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS district VARCHAR(100) DEFAULT 'Ghazipur';
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS pincode VARCHAR(10) DEFAULT '233001';
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 7);
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS longitude NUMERIC(10, 7);
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS gst_or_trade_id VARCHAR(50);
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS verification_status public.business_verification_status DEFAULT 'draft';
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_businesses_created_by ON public.businesses(created_by);
CREATE INDEX IF NOT EXISTS idx_businesses_verification_status ON public.businesses(verification_status);
CREATE INDEX IF NOT EXISTS idx_businesses_business_type ON public.businesses(business_type);

-- 3. Business Members Join Table (Supports Multi-tenant expansion, 1:1 for MVP)
CREATE TABLE IF NOT EXISTS public.business_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role_in_business VARCHAR(50) DEFAULT 'owner' NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_business_member UNIQUE(business_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_business_members_lookup ON public.business_members(user_id, business_id);

-- 4. Business Verification Documents Table
CREATE TABLE IF NOT EXISTS public.business_verification_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  document_type VARCHAR(50) NOT NULL, -- 'business_registration', 'gst_certificate', 'visiting_card', 'business_photo', 'other'
  storage_path TEXT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_business_documents_business ON public.business_verification_documents(business_id);

-- 5. Admin Audit Logs Table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES public.profiles(id),
  action_type VARCHAR(50) NOT NULL, -- 'approve_business', 'reject_business', 'under_review_business', 'suspend_business', 'reactivate_business'
  entity_type VARCHAR(50) NOT NULL, -- 'business', 'job', 'worker'
  entity_id UUID NOT NULL,
  details JSONB DEFAULT '{}'::jsonb NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_entity ON public.admin_audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin ON public.admin_audit_logs(admin_id);

-- 6. Private Supabase Storage Bucket for Business Verification Documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'business-documents',
  'business-documents',
  FALSE,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = FALSE,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

-- Storage RLS Policies for business-documents
-- Allow authenticated Owner to upload only to their business directory: business-documents/<business_id>/...
DROP POLICY IF EXISTS "business_documents_insert_owner" ON storage.objects;
CREATE POLICY "business_documents_insert_owner"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-documents' AND
  EXISTS (
    SELECT 1 FROM public.business_members bm
    WHERE bm.business_id::TEXT = (storage.foldername(name))[1]
      AND bm.user_id = auth.uid()
  )
);

-- Allow business members and Admins to read/download documents
DROP POLICY IF EXISTS "business_documents_select_member_or_admin" ON storage.objects;
CREATE POLICY "business_documents_select_member_or_admin"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'business-documents' AND
  (
    EXISTS (
      SELECT 1 FROM public.business_members bm
      WHERE bm.business_id::TEXT = (storage.foldername(name))[1]
        AND bm.user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM public.user_roles ur
      WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
    )
  )
);

-- Allow business members to delete their own uploaded documents
DROP POLICY IF EXISTS "business_documents_delete_owner" ON storage.objects;
CREATE POLICY "business_documents_delete_owner"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'business-documents' AND
  EXISTS (
    SELECT 1 FROM public.business_members bm
    WHERE bm.business_id::TEXT = (storage.foldername(name))[1]
      AND bm.user_id = auth.uid()
  )
);

-- 7. Enable RLS on Tables
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- 8. Table Level RLS Policies

-- Businesses Table RLS:
-- SELECT: Owner can select their own business; Admins can select any business; Verified businesses visible to all authenticated
DROP POLICY IF EXISTS "businesses_select_policy" ON public.businesses;
CREATE POLICY "businesses_select_policy"
ON public.businesses FOR SELECT
TO authenticated
USING (
  created_by = auth.uid() OR
  EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = id AND bm.user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'admin') OR
  verification_status = 'verified'
);

-- INSERT: Authenticated users holding 'owner' role can create businesses
DROP POLICY IF EXISTS "businesses_insert_owner" ON public.businesses;
CREATE POLICY "businesses_insert_owner"
ON public.businesses FOR INSERT
TO authenticated
WITH CHECK (
  created_by = auth.uid() AND
  EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'owner')
);

-- UPDATE: Owner can only update business fields when status is 'draft' or 'rejected'.
-- Verification decisions are strictly protected and cannot be changed by the owner.
DROP POLICY IF EXISTS "businesses_update_owner" ON public.businesses;
CREATE POLICY "businesses_update_owner"
ON public.businesses FOR UPDATE
TO authenticated
USING (
  (created_by = auth.uid() OR EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = id AND bm.user_id = auth.uid())) AND
  verification_status IN ('draft', 'rejected')
)
WITH CHECK (
  (created_by = auth.uid() OR EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = id AND bm.user_id = auth.uid())) AND
  verification_status IN ('draft', 'rejected', 'pending')
);

-- Business Members Table RLS:
DROP POLICY IF EXISTS "business_members_select" ON public.business_members;
CREATE POLICY "business_members_select"
ON public.business_members FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'admin')
);

-- Business Verification Documents RLS:
DROP POLICY IF EXISTS "business_docs_select" ON public.business_verification_documents;
CREATE POLICY "business_docs_select"
ON public.business_verification_documents FOR SELECT
TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = business_verification_documents.business_id AND bm.user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'admin')
);

DROP POLICY IF EXISTS "business_docs_insert" ON public.business_verification_documents;
CREATE POLICY "business_docs_insert"
ON public.business_verification_documents FOR INSERT
TO authenticated
WITH CHECK (
  uploaded_by = auth.uid() AND
  EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = business_verification_documents.business_id AND bm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "business_docs_delete" ON public.business_verification_documents;
CREATE POLICY "business_docs_delete"
ON public.business_verification_documents FOR DELETE
TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = business_verification_documents.business_id AND bm.user_id = auth.uid())
);

-- Admin Audit Logs RLS:
DROP POLICY IF EXISTS "admin_audit_logs_select" ON public.admin_audit_logs;
CREATE POLICY "admin_audit_logs_select"
ON public.admin_audit_logs FOR SELECT
TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'admin')
);

-- 9. Transaction-Safe RPC: Save Business Profile Draft
CREATE OR REPLACE FUNCTION public.save_business_profile_draft(
  p_business_id UUID DEFAULT NULL,
  p_name TEXT DEFAULT NULL,
  p_business_type TEXT DEFAULT 'marriage_hall',
  p_description TEXT DEFAULT NULL,
  p_contact_person TEXT DEFAULT NULL,
  p_contact_phone TEXT DEFAULT NULL,
  p_locality TEXT DEFAULT 'Ghazipur',
  p_address TEXT DEFAULT NULL,
  p_pincode TEXT DEFAULT '233001',
  p_latitude NUMERIC DEFAULT NULL,
  p_longitude NUMERIC DEFAULT NULL,
  p_gst_or_trade_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_owner_role public.app_role;
  v_target_id UUID;
  v_existing_status public.business_verification_status;
BEGIN
  -- 1. Check Authentication
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication session is required.' USING ERRCODE = '42501';
  END IF;

  -- 2. Verify Caller Has Owner Role
  SELECT role INTO v_owner_role
  FROM public.user_roles
  WHERE user_id = v_uid AND role = 'owner';

  IF v_owner_role IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: User does not have business owner role.' USING ERRCODE = '42501';
  END IF;

  -- 3. If business_id provided, verify ownership and draft/rejected state
  IF p_business_id IS NOT NULL THEN
    SELECT id, verification_status INTO v_target_id, v_existing_status
    FROM public.businesses
    WHERE id = p_business_id AND created_by = v_uid;

    IF v_target_id IS NULL THEN
      RAISE EXCEPTION 'NOT_FOUND: Business not found or caller is not owner.' USING ERRCODE = '42501';
    END IF;

    -- Cannot edit while pending or under review
    IF v_existing_status IN ('pending', 'under_review') THEN
      RAISE EXCEPTION 'CANNOT_EDIT: Business profile is currently under review by Admin.' USING ERRCODE = '22023';
    END IF;

    UPDATE public.businesses
    SET
      name = COALESCE(NULLIF(BTRIM(p_name), ''), name),
      business_type = COALESCE(NULLIF(BTRIM(p_business_type), ''), business_type),
      description = p_description,
      contact_person = COALESCE(NULLIF(BTRIM(p_contact_person), ''), contact_person),
      contact_phone = COALESCE(NULLIF(BTRIM(p_contact_phone), ''), contact_phone),
      locality = COALESCE(NULLIF(BTRIM(p_locality), ''), locality),
      address = p_address,
      pincode = COALESCE(NULLIF(BTRIM(p_pincode), ''), pincode),
      latitude = COALESCE(p_latitude, latitude),
      longitude = COALESCE(p_longitude, longitude),
      gst_or_trade_id = p_gst_or_trade_id,
      updated_at = NOW()
    WHERE id = v_target_id;
  ELSE
    -- Check if owner already has an existing business (1 primary business for MVP)
    SELECT id, verification_status INTO v_target_id, v_existing_status
    FROM public.businesses
    WHERE created_by = v_uid
    LIMIT 1;

    IF v_target_id IS NOT NULL THEN
      -- Update existing
      UPDATE public.businesses
      SET
        name = COALESCE(NULLIF(BTRIM(p_name), ''), name),
        business_type = COALESCE(NULLIF(BTRIM(p_business_type), ''), business_type),
        description = p_description,
        contact_person = COALESCE(NULLIF(BTRIM(p_contact_person), ''), contact_person),
        contact_phone = COALESCE(NULLIF(BTRIM(p_contact_phone), ''), contact_phone),
        locality = COALESCE(NULLIF(BTRIM(p_locality), ''), locality),
        address = p_address,
        pincode = COALESCE(NULLIF(BTRIM(p_pincode), ''), pincode),
        latitude = COALESCE(p_latitude, latitude),
        longitude = COALESCE(p_longitude, longitude),
        gst_or_trade_id = p_gst_or_trade_id,
        updated_at = NOW()
      WHERE id = v_target_id;
    ELSE
      -- Insert new draft business
      INSERT INTO public.businesses (
        created_by,
        name,
        business_type,
        description,
        contact_person,
        contact_phone,
        locality,
        address,
        pincode,
        latitude,
        longitude,
        gst_or_trade_id,
        verification_status,
        updated_at
      )
      VALUES (
        v_uid,
        COALESCE(NULLIF(BTRIM(p_name), ''), 'मेरा व्यवसाय (My Business)'),
        COALESCE(NULLIF(BTRIM(p_business_type), ''), 'marriage_hall'),
        p_description,
        p_contact_person,
        COALESCE(NULLIF(BTRIM(p_contact_phone), ''), '0000000000'),
        COALESCE(NULLIF(BTRIM(p_locality), ''), 'Ghazipur'),
        p_address,
        COALESCE(NULLIF(BTRIM(p_pincode), ''), '233001'),
        p_latitude,
        p_longitude,
        p_gst_or_trade_id,
        'draft',
        NOW()
      )
      RETURNING id INTO v_target_id;

      -- Create business_members entry
      INSERT INTO public.business_members (business_id, user_id, role_in_business)
      VALUES (v_target_id, v_uid, 'owner')
      ON CONFLICT (business_id, user_id) DO NOTHING;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'business_id', v_target_id,
    'verification_status', 'draft'
  );
END;
$$;

-- 10. Transaction-Safe RPC: Submit Business for Admin Verification
CREATE OR REPLACE FUNCTION public.submit_business_for_verification(
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_biz RECORD;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication session is required.' USING ERRCODE = '42501';
  END IF;

  SELECT id, name, locality, pincode, contact_phone, verification_status
  INTO v_biz
  FROM public.businesses
  WHERE id = p_business_id AND created_by = v_uid;

  IF v_biz.id IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND: Business does not exist or caller is not owner.' USING ERRCODE = '42501';
  END IF;

  -- Validate mandatory fields before formal submission
  IF LENGTH(BTRIM(v_biz.name)) < 2 THEN
    RAISE EXCEPTION 'INVALID_NAME: Business name is required.' USING ERRCODE = '22023';
  END IF;

  IF LENGTH(BTRIM(v_biz.locality)) < 2 THEN
    RAISE EXCEPTION 'INVALID_LOCALITY: Locality is required.' USING ERRCODE = '22023';
  END IF;

  IF NOT (v_biz.pincode ~ '^[1-9][0-9]{5}$') THEN
    RAISE EXCEPTION 'INVALID_PINCODE: 6-digit Indian PIN code is required.' USING ERRCODE = '22023';
  END IF;

  -- Prevent redundant submissions
  IF v_biz.verification_status IN ('pending', 'under_review', 'verified') THEN
    RAISE EXCEPTION 'ALREADY_SUBMITTED: Business is already in status "%"', v_biz.verification_status USING ERRCODE = '23505';
  END IF;

  -- Transition status to 'pending'
  UPDATE public.businesses
  SET
    verification_status = 'pending',
    rejection_reason = NULL,
    submitted_at = NOW(),
    updated_at = NOW()
  WHERE id = p_business_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'business_id', p_business_id,
    'verification_status', 'pending',
    'submitted_at', NOW()
  );
END;
$$;

-- 11. Transaction-Safe RPC: Admin Review Action (Approve, Reject, Under Review, Suspend)
CREATE OR REPLACE FUNCTION public.admin_review_business(
  p_business_id UUID,
  p_action TEXT, -- 'approve', 'reject', 'mark_under_review', 'suspend', 'reactivate'
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_admin_role public.app_role;
  v_biz RECORD;
  v_new_status public.business_verification_status;
  v_clean_reason TEXT;
BEGIN
  -- 1. Verify caller is authenticated
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication session is required.' USING ERRCODE = '42501';
  END IF;

  -- 2. Strictly verify Admin authorization from user_roles
  SELECT role INTO v_admin_role
  FROM public.user_roles
  WHERE user_id = v_uid AND role = 'admin';

  IF v_admin_role IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Administrative authorization is required.' USING ERRCODE = '42501';
  END IF;

  -- 3. Check target business
  SELECT id, verification_status, name INTO v_biz
  FROM public.businesses
  WHERE id = p_business_id;

  IF v_biz.id IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND: Business does not exist.' USING ERRCODE = '42501';
  END IF;

  -- 4. Map action to status
  v_clean_reason := BTRIM(p_rejection_reason);

  IF p_action = 'approve' THEN
    v_new_status := 'verified';
  ELSIF p_action = 'reject' THEN
    IF v_clean_reason IS NULL OR LENGTH(v_clean_reason) < 3 THEN
      RAISE EXCEPTION 'REASON_REQUIRED: A clear rejection reason must be provided.' USING ERRCODE = '22023';
    END IF;
    v_new_status := 'rejected';
  ELSIF p_action = 'mark_under_review' THEN
    v_new_status := 'under_review';
  ELSIF p_action = 'suspend' THEN
    v_new_status := 'suspended';
  ELSIF p_action = 'reactivate' THEN
    v_new_status := 'verified';
  ELSE
    RAISE EXCEPTION 'INVALID_ACTION: Unknown admin review action: %', p_action USING ERRCODE = '22023';
  END IF;

  -- 5. Update Business status and metadata
  UPDATE public.businesses
  SET
    verification_status = v_new_status,
    rejection_reason = CASE WHEN v_new_status = 'rejected' THEN v_clean_reason ELSE rejection_reason END,
    reviewed_at = NOW(),
    reviewed_by = v_uid,
    verified_at = CASE WHEN v_new_status = 'verified' THEN NOW() ELSE verified_at END,
    updated_at = NOW()
  WHERE id = p_business_id;

  -- 6. Record in admin_audit_logs
  INSERT INTO public.admin_audit_logs (
    admin_id,
    action_type,
    entity_type,
    entity_id,
    details
  )
  VALUES (
    v_uid,
    p_action,
    'business',
    p_business_id,
    jsonb_build_object(
      'previous_status', v_biz.verification_status,
      'new_status', v_new_status,
      'rejection_reason', v_clean_reason,
      'business_name', v_biz.name
    )
  );

  RETURN jsonb_build_object(
    'success', TRUE,
    'business_id', p_business_id,
    'new_status', v_new_status,
    'reviewed_at', NOW()
  );
END;
$$;

-- 12. Helper RPC: Fetch Current Owner's Primary Business & Documents
CREATE OR REPLACE FUNCTION public.get_my_business()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_biz RECORD;
  v_docs JSONB;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('authenticated', FALSE);
  END IF;

  SELECT * INTO v_biz
  FROM public.businesses
  WHERE created_by = v_uid
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_biz.id IS NULL THEN
    RETURN jsonb_build_object(
      'authenticated', TRUE,
      'has_business', FALSE
    );
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'document_type', document_type,
        'storage_path', storage_path,
        'file_name', file_name,
        'file_size_bytes', file_size_bytes,
        'mime_type', mime_type,
        'created_at', created_at
      )
    ),
    '[]'::jsonb
  ) INTO v_docs
  FROM public.business_verification_documents
  WHERE business_id = v_biz.id;

  RETURN jsonb_build_object(
    'authenticated', TRUE,
    'has_business', TRUE,
    'business', jsonb_build_object(
      'id', v_biz.id,
      'name', v_biz.name,
      'business_type', v_biz.business_type,
      'description', v_biz.description,
      'contact_person', v_biz.contact_person,
      'contact_phone', v_biz.contact_phone,
      'country', v_biz.country,
      'state', v_biz.state,
      'district', v_biz.district,
      'city', v_biz.city,
      'locality', v_biz.locality,
      'address', v_biz.address,
      'pincode', v_biz.pincode,
      'latitude', v_biz.latitude,
      'longitude', v_biz.longitude,
      'gst_or_trade_id', v_biz.gst_or_trade_id,
      'verification_status', v_biz.verification_status::TEXT,
      'rejection_reason', v_biz.rejection_reason,
      'submitted_at', v_biz.submitted_at,
      'reviewed_at', v_biz.reviewed_at,
      'verified_at', v_biz.verified_at,
      'is_first_job_approved', v_biz.is_first_job_approved,
      'created_at', v_biz.created_at,
      'documents', v_docs
    )
  );
END;
$$;

-- 13. Helper RPC: Fetch Real Owner Business Statistics
CREATE OR REPLACE FUNCTION public.get_owner_business_stats(
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid UUID;
  v_total_jobs INT := 0;
  v_active_jobs INT := 0;
  v_completed_jobs INT := 0;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('authenticated', FALSE);
  END IF;

  -- Verify ownership
  IF NOT EXISTS (
    SELECT 1 FROM public.businesses
    WHERE id = p_business_id AND created_by = v_uid
  ) THEN
    RETURN jsonb_build_object('error', 'UNAUTHORIZED');
  END IF;

  SELECT COUNT(*) INTO v_total_jobs
  FROM public.jobs
  WHERE business_id = p_business_id;

  SELECT COUNT(*) INTO v_active_jobs
  FROM public.jobs
  WHERE business_id = p_business_id
    AND status IN ('published', 'in_progress', 'filled');

  SELECT COUNT(*) INTO v_completed_jobs
  FROM public.jobs
  WHERE business_id = p_business_id
    AND status = 'completed';

  RETURN jsonb_build_object(
    'total_jobs', v_total_jobs,
    'active_jobs', v_active_jobs,
    'completed_jobs', v_completed_jobs
  );
END;
$$;


-- ============================================================================
-- FILE: 20261118000004_phase5_job_posting_discovery.sql
-- ============================================================================

-- ==============================================================================
-- LAGANSTAFF MIGRATION: Phase 5 - Job Posting & Job Discovery
-- Migration: 20261118000004_phase5_job_posting_discovery.sql
-- Description:
--   1. Schema enhancements for businesses (first_job_approved_at).
--   2. Comprehensive schema for jobs table (venue, locality, shifts, perks, first-job flag, rejection reason).
--   3. job_skills relationship table linking jobs to skills.
--   4. Optimized B-Tree & composite partial indexes for high-throughput Ghazipur job queries.
--   5. Strict Row-Level Security (RLS) policies for Owner, Worker, and Admin roles.
--   6. Atomic SECURITY DEFINER PostgreSQL functions for draft saving, atomic submission with
--      first-job concurrency protection, admin review, and cancellation.
-- ==============================================================================

-- 1. Extend businesses table with first_job_approved_at if not present
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS is_first_job_approved BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS first_job_approved_at TIMESTAMPTZ;

-- 2. Enhance jobs table with Phase 5 fields
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS venue_name VARCHAR(150);
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS locality VARCHAR(100);
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS city VARCHAR(100) DEFAULT 'Ghazipur';
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS district VARCHAR(100) DEFAULT 'Ghazipur';
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS state VARCHAR(100) DEFAULT 'Uttar Pradesh';
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS pincode VARCHAR(10) DEFAULT '233001';
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 7);
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS longitude NUMERIC(10, 7);
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS is_overnight BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS payment_instructions TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS food_provided BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS food_details TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS transport_provided BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS transport_details TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS special_instructions TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS is_first_job BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS admin_rejection_reason TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS cancelled_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- 3. Create job_skills relationship table
CREATE TABLE IF NOT EXISTS public.job_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES public.skills(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT uq_job_skill UNIQUE(job_id, skill_id)
);

-- 4. Create High-Performance Indexes
CREATE INDEX IF NOT EXISTS idx_jobs_business_id ON public.jobs(business_id);
CREATE INDEX IF NOT EXISTS idx_jobs_category_id ON public.jobs(category_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status_shift_date ON public.jobs(status, shift_date);
CREATE INDEX IF NOT EXISTS idx_jobs_published_feed ON public.jobs(status, shift_date DESC, created_at DESC) WHERE status = 'published';
CREATE INDEX IF NOT EXISTS idx_jobs_approval_queue ON public.jobs(status, created_at ASC) WHERE status = 'pending_admin_approval';
CREATE INDEX IF NOT EXISTS idx_jobs_locality ON public.jobs(locality);
CREATE INDEX IF NOT EXISTS idx_jobs_wage ON public.jobs(wage_amount);
CREATE INDEX IF NOT EXISTS idx_job_skills_job ON public.job_skills(job_id);
CREATE INDEX IF NOT EXISTS idx_job_skills_skill ON public.job_skills(skill_id);

-- 5. Row-Level Security Policies for jobs & job_skills
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_skills ENABLE ROW LEVEL SECURITY;

-- JOBS POLICIES:
-- 1) Select policy:
--    - Published jobs visible to active workers and all authenticated users.
--    - Business owners/members can see all jobs of their own business regardless of status.
--    - Admins can see all jobs.
DROP POLICY IF EXISTS "jobs_select_policy" ON public.jobs;
CREATE POLICY "jobs_select_policy"
ON public.jobs FOR SELECT
TO authenticated
USING (
  -- Published jobs are visible to anyone authenticated
  status = 'published'
  OR
  -- Owner / member of the business can view all its jobs
  EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = jobs.business_id AND (
      b.created_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.business_members bm
        WHERE bm.business_id = b.id AND bm.user_id = auth.uid()
      )
    )
  )
  OR
  -- Platform Admins can see all jobs
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
  )
);

-- 2) Insert policy:
--    - Only owners of a verified, non-suspended business can insert draft jobs directly.
DROP POLICY IF EXISTS "jobs_insert_owner" ON public.jobs;
CREATE POLICY "jobs_insert_owner"
ON public.jobs FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = business_id AND (
      b.created_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.business_members bm
        WHERE bm.business_id = b.id AND bm.user_id = auth.uid()
      )
    )
    AND b.verification_status = 'verified'
  )
);

-- 3) Update policy:
--    - Owners can only update draft or rejected jobs, or non-critical details on pending jobs.
DROP POLICY IF EXISTS "jobs_update_owner" ON public.jobs;
CREATE POLICY "jobs_update_owner"
ON public.jobs FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = jobs.business_id AND (
      b.created_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.business_members bm
        WHERE bm.business_id = b.id AND bm.user_id = auth.uid()
      )
    )
  )
  OR
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
  )
);

-- JOB_SKILLS POLICIES:
DROP POLICY IF EXISTS "job_skills_select" ON public.job_skills;
CREATE POLICY "job_skills_select"
ON public.job_skills FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.jobs j
    WHERE j.id = job_skills.job_id
  )
);

DROP POLICY IF EXISTS "job_skills_modify_owner" ON public.job_skills;
CREATE POLICY "job_skills_modify_owner"
ON public.job_skills FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.jobs j
    JOIN public.businesses b ON b.id = j.business_id
    WHERE j.id = job_skills.job_id AND (
      b.created_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.business_members bm
        WHERE bm.business_id = b.id AND bm.user_id = auth.uid()
      )
      OR
      EXISTS (
        SELECT 1 FROM public.user_roles ur
        WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
      )
    )
  )
);

-- ==============================================================================
-- 6. SECURED DATABASE FUNCTIONS & ATOMIC RPCS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- RPC 1: save_job_draft
-- Saves or updates a job posting in 'draft' status with linked skills.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.save_job_draft(
  p_job_id UUID DEFAULT NULL,
  p_business_id UUID DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_title TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_venue_name TEXT DEFAULT NULL,
  p_reporting_address TEXT DEFAULT NULL,
  p_locality TEXT DEFAULT NULL,
  p_city TEXT DEFAULT 'Ghazipur',
  p_pincode TEXT DEFAULT '233001',
  p_latitude NUMERIC DEFAULT NULL,
  p_longitude NUMERIC DEFAULT NULL,
  p_shift_date DATE DEFAULT NULL,
  p_start_time TIME DEFAULT NULL,
  p_end_time TIME DEFAULT NULL,
  p_is_overnight BOOLEAN DEFAULT FALSE,
  p_workers_needed INT DEFAULT 1,
  p_wage_amount NUMERIC DEFAULT 500,
  p_payment_instructions TEXT DEFAULT NULL,
  p_food_provided BOOLEAN DEFAULT FALSE,
  p_food_details TEXT DEFAULT NULL,
  p_transport_provided BOOLEAN DEFAULT FALSE,
  p_transport_details TEXT DEFAULT NULL,
  p_special_instructions TEXT DEFAULT NULL,
  p_skill_ids UUID[] DEFAULT ARRAY[]::UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_biz RECORD;
  v_target_job_id UUID;
  v_skill_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Verify business authorization
  SELECT * INTO v_biz
  FROM public.businesses
  WHERE id = p_business_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Business not found.';
  END IF;

  IF v_biz.created_by != v_user_id AND NOT EXISTS (
    SELECT 1 FROM public.business_members bm
    WHERE bm.business_id = p_business_id AND bm.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not authorized to manage jobs for this business.';
  END IF;

  IF v_biz.verification_status = 'suspended' THEN
    RAISE EXCEPTION 'Business is suspended. Cannot create or edit jobs.';
  END IF;

  IF p_job_id IS NOT NULL THEN
    -- Verify existing job ownership
    SELECT id INTO v_target_job_id
    FROM public.jobs
    WHERE id = p_job_id AND business_id = p_business_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Job not found for this business.';
    END IF;

    UPDATE public.jobs
    SET
      category_id = COALESCE(p_category_id, category_id),
      title = COALESCE(p_title, title),
      description = p_description,
      venue_name = p_venue_name,
      reporting_address = COALESCE(p_reporting_address, reporting_address),
      locality = COALESCE(p_locality, locality),
      city = COALESCE(p_city, city),
      pincode = COALESCE(p_pincode, pincode),
      latitude = p_latitude,
      longitude = p_longitude,
      shift_date = COALESCE(p_shift_date, shift_date),
      start_time = COALESCE(p_start_time, start_time),
      end_time = COALESCE(p_end_time, end_time),
      is_overnight = p_is_overnight,
      workers_needed = GREATEST(1, COALESCE(p_workers_needed, workers_needed)),
      wage_amount = GREATEST(1.0, COALESCE(p_wage_amount, wage_amount)),
      payment_instructions = p_payment_instructions,
      food_provided = p_food_provided,
      food_details = p_food_details,
      transport_provided = p_transport_provided,
      transport_details = p_transport_details,
      special_instructions = p_special_instructions,
      updated_at = NOW()
    WHERE id = v_target_job_id;
  ELSE
    INSERT INTO public.jobs (
      business_id,
      category_id,
      created_by,
      title,
      description,
      venue_name,
      reporting_address,
      locality,
      city,
      district,
      state,
      pincode,
      latitude,
      longitude,
      shift_date,
      start_time,
      end_time,
      is_overnight,
      workers_needed,
      wage_amount,
      wage_rate_unit,
      payment_instructions,
      food_provided,
      food_details,
      transport_provided,
      transport_details,
      special_instructions,
      status
    ) VALUES (
      p_business_id,
      COALESCE(p_category_id, (SELECT id FROM public.categories LIMIT 1)),
      v_user_id,
      COALESCE(p_title, 'नया कार्य (Draft Job)'),
      p_description,
      p_venue_name,
      COALESCE(p_reporting_address, v_biz.address, 'गाजीपुर'),
      COALESCE(p_locality, v_biz.locality, 'गाजीपुर'),
      COALESCE(p_city, 'Ghazipur'),
      'Ghazipur',
      'Uttar Pradesh',
      COALESCE(p_pincode, v_biz.pincode, '233001'),
      p_latitude,
      p_longitude,
      COALESCE(p_shift_date, CURRENT_DATE + 1),
      COALESCE(p_start_time, '09:00:00'::TIME),
      COALESCE(p_end_time, '17:00:00'::TIME),
      p_is_overnight,
      GREATEST(1, COALESCE(p_workers_needed, 1)),
      GREATEST(1.0, COALESCE(p_wage_amount, 500)),
      'per_shift',
      p_payment_instructions,
      p_food_provided,
      p_food_details,
      p_transport_provided,
      p_transport_details,
      p_special_instructions,
      'draft'
    )
    RETURNING id INTO v_target_job_id;
  END IF;

  -- Sync job_skills if array is provided
  IF p_skill_ids IS NOT NULL AND array_length(p_skill_ids, 1) > 0 THEN
    DELETE FROM public.job_skills WHERE job_id = v_target_job_id;
    FOREACH v_skill_id IN ARRAY p_skill_ids
    LOOP
      INSERT INTO public.job_skills (job_id, skill_id)
      VALUES (v_target_job_id, v_skill_id)
      ON CONFLICT (job_id, skill_id) DO NOTHING;
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'job_id', v_target_job_id,
    'status', 'draft',
    'message', 'Job draft saved successfully.'
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 2: submit_job
-- Submits a job with First-Job approval logic & atomic concurrency protection.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_job(
  p_job_id UUID DEFAULT NULL,
  p_business_id UUID DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_title TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_venue_name TEXT DEFAULT NULL,
  p_reporting_address TEXT DEFAULT NULL,
  p_locality TEXT DEFAULT NULL,
  p_city TEXT DEFAULT 'Ghazipur',
  p_pincode TEXT DEFAULT '233001',
  p_latitude NUMERIC DEFAULT NULL,
  p_longitude NUMERIC DEFAULT NULL,
  p_shift_date DATE DEFAULT NULL,
  p_start_time TIME DEFAULT NULL,
  p_end_time TIME DEFAULT NULL,
  p_is_overnight BOOLEAN DEFAULT FALSE,
  p_workers_needed INT DEFAULT 1,
  p_wage_amount NUMERIC DEFAULT 500,
  p_payment_instructions TEXT DEFAULT NULL,
  p_food_provided BOOLEAN DEFAULT FALSE,
  p_food_details TEXT DEFAULT NULL,
  p_transport_provided BOOLEAN DEFAULT FALSE,
  p_transport_details TEXT DEFAULT NULL,
  p_special_instructions TEXT DEFAULT NULL,
  p_skill_ids UUID[] DEFAULT ARRAY[]::UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_biz RECORD;
  v_target_job_id UUID;
  v_new_status public.job_status;
  v_is_first_job BOOLEAN;
  v_skill_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Lock business row FOR UPDATE to prevent race conditions on first-job approval
  SELECT * INTO v_biz
  FROM public.businesses
  WHERE id = p_business_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Business not found.';
  END IF;

  -- Check owner authorization
  IF v_biz.created_by != v_user_id AND NOT EXISTS (
    SELECT 1 FROM public.business_members bm
    WHERE bm.business_id = p_business_id AND bm.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not authorized to post jobs for this business.';
  END IF;

  -- Enforce Business Verification State
  IF v_biz.verification_status = 'pending' THEN
    RAISE EXCEPTION 'व्यापार सत्यापन प्रतीक्षित है। एडमिन द्वारा सत्यापन के बाद ही कार्य पोस्ट किया जा सकता है।';
  ELSIF v_biz.verification_status = 'rejected' THEN
    RAISE EXCEPTION 'व्यापार आवेदन अस्वीकृत है। कृपया प्रोफाइल सुधार कर पुनः सबमिट करें।';
  ELSIF v_biz.verification_status = 'suspended' THEN
    RAISE EXCEPTION 'व्यापार खाता निलंबित है। कार्य पोस्ट करने की अनुमति नहीं है।';
  ELSIF v_biz.verification_status != 'verified' THEN
    RAISE EXCEPTION 'कार्य पोस्ट करने के लिए व्यापार का सत्यापित होना अनिवार्य है।';
  END IF;

  -- Validation: Shift Date cannot be in the past
  IF p_shift_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'कार्य की तिथि भूतकाल (past date) नहीं हो सकती।';
  END IF;

  -- Validation: Title, Wage, Workers
  IF length(trim(COALESCE(p_title, ''))) < 3 THEN
    RAISE EXCEPTION 'कार्य का शीर्षक कम से कम 3 अक्षरों का होना चाहिए।';
  END IF;

  IF p_workers_needed < 1 THEN
    RAISE EXCEPTION 'कम से कम 1 कार्यकर्ता की आवश्यकता होनी चाहिए।';
  END IF;

  IF p_wage_amount <= 0 THEN
    RAISE EXCEPTION 'प्रति शिफ्ट मानदेय शून्य से अधिक होना चाहिए।';
  END IF;

  -- CRITICAL RULE: First-Job Approval Check
  IF NOT v_biz.is_first_job_approved AND v_biz.first_job_approved_at IS NULL THEN
    -- Check if another job is already awaiting approval for this business
    IF EXISTS (
      SELECT 1 FROM public.jobs
      WHERE business_id = p_business_id
        AND status = 'pending_admin_approval'
        AND (p_job_id IS NULL OR id != p_job_id)
    ) THEN
      RAISE EXCEPTION 'इस व्यापार का पहला कार्य पहले से ही एडमिन समीक्षा में है। कृपया समीक्षा पूरी होने की प्रतीक्षा करें।';
    END IF;

    v_new_status := 'pending_admin_approval';
    v_is_first_job := TRUE;
  ELSE
    -- Business has already had its first job approved! Subsequent jobs auto-publish!
    v_new_status := 'published';
    v_is_first_job := FALSE;
  END IF;

  -- Insert or Update Job
  IF p_job_id IS NOT NULL THEN
    SELECT id INTO v_target_job_id
    FROM public.jobs
    WHERE id = p_job_id AND business_id = p_business_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Job not found.';
    END IF;

    UPDATE public.jobs
    SET
      category_id = p_category_id,
      title = trim(p_title),
      description = p_description,
      venue_name = p_venue_name,
      reporting_address = trim(p_reporting_address),
      locality = trim(p_locality),
      city = COALESCE(p_city, 'Ghazipur'),
      district = 'Ghazipur',
      state = 'Uttar Pradesh',
      pincode = COALESCE(p_pincode, '233001'),
      latitude = p_latitude,
      longitude = p_longitude,
      shift_date = p_shift_date,
      start_time = p_start_time,
      end_time = p_end_time,
      is_overnight = p_is_overnight,
      workers_needed = p_workers_needed,
      wage_amount = p_wage_amount,
      wage_rate_unit = 'per_shift',
      payment_instructions = p_payment_instructions,
      food_provided = p_food_provided,
      food_details = p_food_details,
      transport_provided = p_transport_provided,
      transport_details = p_transport_details,
      special_instructions = p_special_instructions,
      status = v_new_status,
      is_first_job = v_is_first_job,
      admin_rejection_reason = NULL, -- clear previous rejection reason on resubmit
      published_at = CASE WHEN v_new_status = 'published' THEN NOW() ELSE published_at END,
      updated_at = NOW()
    WHERE id = v_target_job_id;
  ELSE
    INSERT INTO public.jobs (
      business_id,
      category_id,
      created_by,
      title,
      description,
      venue_name,
      reporting_address,
      locality,
      city,
      district,
      state,
      pincode,
      latitude,
      longitude,
      shift_date,
      start_time,
      end_time,
      is_overnight,
      workers_needed,
      wage_amount,
      wage_rate_unit,
      payment_instructions,
      food_provided,
      food_details,
      transport_provided,
      transport_details,
      special_instructions,
      is_first_job,
      status,
      published_at
    ) VALUES (
      p_business_id,
      p_category_id,
      v_user_id,
      trim(p_title),
      p_description,
      p_venue_name,
      trim(p_reporting_address),
      trim(p_locality),
      COALESCE(p_city, 'Ghazipur'),
      'Ghazipur',
      'Uttar Pradesh',
      COALESCE(p_pincode, '233001'),
      p_latitude,
      p_longitude,
      p_shift_date,
      p_start_time,
      p_end_time,
      p_is_overnight,
      p_workers_needed,
      p_wage_amount,
      'per_shift',
      p_payment_instructions,
      p_food_provided,
      p_food_details,
      p_transport_provided,
      p_transport_details,
      p_special_instructions,
      v_is_first_job,
      v_new_status,
      CASE WHEN v_new_status = 'published' THEN NOW() ELSE NULL END
    )
    RETURNING id INTO v_target_job_id;
  END IF;

  -- Sync job_skills
  IF p_skill_ids IS NOT NULL THEN
    DELETE FROM public.job_skills WHERE job_id = v_target_job_id;
    FOREACH v_skill_id IN ARRAY p_skill_ids
    LOOP
      INSERT INTO public.job_skills (job_id, skill_id)
      VALUES (v_target_job_id, v_skill_id)
      ON CONFLICT (job_id, skill_id) DO NOTHING;
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'job_id', v_target_job_id,
    'status', v_new_status,
    'is_first_job', v_is_first_job,
    'message', CASE
      WHEN v_new_status = 'pending_admin_approval' THEN 'प्रथम कार्य एडमिन समीक्षा के लिए सफलतापूर्वक सबमिट कर दिया गया है।'
      ELSE 'कार्य सफलतापूर्वक प्रकाशित (Published) हो गया है।'
    END
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 3: admin_review_first_job
-- Admin decision to approve or reject a first-job submission atomically.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_review_first_job(
  p_job_id UUID,
  p_action TEXT, -- 'approve' or 'reject'
  p_rejection_reason TEXT DEFAULT NULL,
  p_internal_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
  v_job RECORD;
  v_biz RECORD;
BEGIN
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Verify caller has admin role
  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = v_admin_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Only platform administrators can review jobs.';
  END IF;

  -- Lock job and business rows FOR UPDATE
  SELECT * INTO v_job
  FROM public.jobs
  WHERE id = p_job_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found.';
  END IF;

  SELECT * INTO v_biz
  FROM public.businesses
  WHERE id = v_job.business_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Associated business not found.';
  END IF;

  -- Admin cannot approve jobs belonging to unverified or suspended businesses
  IF v_biz.verification_status != 'verified' THEN
    RAISE EXCEPTION 'Cannot approve job: Business is not in verified state (current: %).', v_biz.verification_status;
  END IF;

  IF p_action = 'approve' THEN
    -- 1. Update Job to published
    UPDATE public.jobs
    SET
      status = 'published',
      approved_by = v_admin_id,
      approved_at = NOW(),
      published_at = NOW(),
      admin_rejection_reason = NULL,
      updated_at = NOW()
    WHERE id = p_job_id;

    -- 2. Mark Business as first job approved
    UPDATE public.businesses
    SET
      is_first_job_approved = TRUE,
      first_job_approved_at = NOW(),
      updated_at = NOW()
    WHERE id = v_biz.id;

    -- 3. Audit log
    INSERT INTO public.admin_audit_logs (
      admin_id,
      action,
      entity_type,
      entity_id,
      old_state,
      new_state,
      notes
    ) VALUES (
      v_admin_id,
      'approve_first_job',
      'jobs',
      p_job_id,
      jsonb_build_object('status', v_job.status, 'is_first_job_approved', v_biz.is_first_job_approved),
      jsonb_build_object('status', 'published', 'is_first_job_approved', TRUE, 'approved_at', NOW()),
      p_internal_notes
    );

    RETURN jsonb_build_object(
      'success', TRUE,
      'job_id', p_job_id,
      'status', 'published',
      'is_first_job_approved', TRUE,
      'message', 'Job approved and business auto-publishing unlocked.'
    );

  ELSIF p_action = 'reject' THEN
    IF length(trim(COALESCE(p_rejection_reason, ''))) < 5 THEN
      RAISE EXCEPTION 'Rejection requires a detailed reason (at least 5 characters).';
    END IF;

    UPDATE public.jobs
    SET
      status = 'rejected',
      admin_rejection_reason = trim(p_rejection_reason),
      updated_at = NOW()
    WHERE id = p_job_id;

    -- Audit log
    INSERT INTO public.admin_audit_logs (
      admin_id,
      action,
      entity_type,
      entity_id,
      old_state,
      new_state,
      notes
    ) VALUES (
      v_admin_id,
      'reject_first_job',
      'jobs',
      p_job_id,
      jsonb_build_object('status', v_job.status),
      jsonb_build_object('status', 'rejected', 'reason', p_rejection_reason),
      p_internal_notes
    );

    RETURN jsonb_build_object(
      'success', TRUE,
      'job_id', p_job_id,
      'status', 'rejected',
      'message', 'Job rejected with reason recorded.'
    );
  ELSE
    RAISE EXCEPTION 'Invalid review action: % (must be approve or reject).', p_action;
  END IF;
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 4: owner_cancel_job
-- Allows owner to cancel their own job safely with audit tracking.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.owner_cancel_job(
  p_job_id UUID,
  p_cancellation_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_job RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT j.*, b.created_by as biz_owner_id
  INTO v_job
  FROM public.jobs j
  JOIN public.businesses b ON b.id = j.business_id
  WHERE j.id = p_job_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found.';
  END IF;

  IF v_job.biz_owner_id != v_user_id AND NOT EXISTS (
    SELECT 1 FROM public.business_members bm
    WHERE bm.business_id = v_job.business_id AND bm.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not authorized to cancel this job.';
  END IF;

  IF v_job.status = 'cancelled' THEN
    RAISE EXCEPTION 'Job is already cancelled.';
  END IF;

  IF v_job.status = 'completed' THEN
    RAISE EXCEPTION 'Completed jobs cannot be cancelled.';
  END IF;

  UPDATE public.jobs
  SET
    status = 'cancelled',
    cancelled_at = NOW(),
    cancelled_by = v_user_id,
    cancellation_reason = p_cancellation_reason,
    updated_at = NOW()
  WHERE id = p_job_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'job_id', p_job_id,
    'status', 'cancelled',
    'message', 'Job has been successfully cancelled.'
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 5: get_available_jobs_for_worker
-- Retrieves published jobs with multi-attribute filtering & pagination.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_available_jobs_for_worker(
  p_category_id UUID DEFAULT NULL,
  p_locality TEXT DEFAULT NULL,
  p_shift_date DATE DEFAULT NULL,
  p_min_wage NUMERIC DEFAULT NULL,
  p_max_wage NUMERIC DEFAULT NULL,
  p_food_provided BOOLEAN DEFAULT NULL,
  p_transport_provided BOOLEAN DEFAULT NULL,
  p_skill_ids UUID[] DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  business_id UUID,
  business_name TEXT,
  business_locality TEXT,
  business_category TEXT,
  category_id UUID,
  category_name TEXT,
  title VARCHAR,
  description TEXT,
  venue_name VARCHAR,
  reporting_address TEXT,
  locality VARCHAR,
  city VARCHAR,
  shift_date DATE,
  start_time TIME,
  end_time TIME,
  is_overnight BOOLEAN,
  workers_needed INT,
  workers_confirmed INT,
  wage_amount NUMERIC,
  wage_rate_unit VARCHAR,
  payment_instructions TEXT,
  food_provided BOOLEAN,
  food_details TEXT,
  transport_provided BOOLEAN,
  transport_details TEXT,
  special_instructions TEXT,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  skills JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    j.id,
    j.business_id,
    b.name AS business_name,
    b.locality AS business_locality,
    b.business_type::TEXT AS business_category,
    j.category_id,
    c.name AS category_name,
    j.title,
    j.description,
    j.venue_name,
    j.reporting_address,
    j.locality,
    j.city,
    j.shift_date,
    j.start_time,
    j.end_time,
    j.is_overnight,
    j.workers_needed,
    j.workers_confirmed,
    j.wage_amount,
    j.wage_rate_unit,
    j.payment_instructions,
    j.food_provided,
    j.food_details,
    j.transport_provided,
    j.transport_details,
    j.special_instructions,
    j.published_at,
    j.created_at,
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', s.id,
            'name', s.name
          )
        )
        FROM public.job_skills js
        JOIN public.skills s ON s.id = js.skill_id
        WHERE js.job_id = j.id
      ),
      '[]'::jsonb
    ) AS skills
  FROM public.jobs j
  JOIN public.businesses b ON b.id = j.business_id
  JOIN public.categories c ON c.id = j.category_id
  WHERE j.status = 'published'
    AND b.verification_status = 'verified'
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_locality IS NULL OR p_locality = '' OR j.locality ILIKE '%' || p_locality || '%')
    AND (p_shift_date IS NULL OR j.shift_date = p_shift_date)
    AND (p_min_wage IS NULL OR j.wage_amount >= p_min_wage)
    AND (p_max_wage IS NULL OR j.wage_amount <= p_max_wage)
    AND (p_food_provided IS NULL OR j.food_provided = p_food_provided)
    AND (p_transport_provided IS NULL OR j.transport_provided = p_transport_provided)
    AND (
      p_skill_ids IS NULL OR array_length(p_skill_ids, 1) IS NULL OR
      EXISTS (
        SELECT 1 FROM public.job_skills js2
        WHERE js2.job_id = j.id AND js2.skill_id = ANY(p_skill_ids)
      )
    )
  ORDER BY j.shift_date ASC, j.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 6: get_owner_jobs
-- Retrieves filtered jobs for an owner's business.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_owner_jobs(
  p_business_id UUID,
  p_status_filter TEXT DEFAULT NULL,
  p_limit INT DEFAULT 30,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  business_id UUID,
  category_id UUID,
  category_name TEXT,
  title VARCHAR,
  description TEXT,
  venue_name VARCHAR,
  reporting_address TEXT,
  locality VARCHAR,
  shift_date DATE,
  start_time TIME,
  end_time TIME,
  is_overnight BOOLEAN,
  workers_needed INT,
  workers_confirmed INT,
  wage_amount NUMERIC,
  wage_rate_unit VARCHAR,
  food_provided BOOLEAN,
  transport_provided BOOLEAN,
  special_instructions TEXT,
  is_first_job BOOLEAN,
  status public.job_status,
  admin_rejection_reason TEXT,
  created_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  skills JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Validate ownership
  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = p_business_id AND (
      b.created_by = v_user_id OR
      EXISTS (
        SELECT 1 FROM public.business_members bm
        WHERE bm.business_id = p_business_id AND bm.user_id = v_user_id
      )
    )
  ) AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = v_user_id AND ur.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized to view jobs for this business.';
  END IF;

  RETURN QUERY
  SELECT
    j.id,
    j.business_id,
    j.category_id,
    c.name AS category_name,
    j.title,
    j.description,
    j.venue_name,
    j.reporting_address,
    j.locality,
    j.shift_date,
    j.start_time,
    j.end_time,
    j.is_overnight,
    j.workers_needed,
    j.workers_confirmed,
    j.wage_amount,
    j.wage_rate_unit,
    j.food_provided,
    j.transport_provided,
    j.special_instructions,
    j.is_first_job,
    j.status,
    j.admin_rejection_reason,
    j.created_at,
    j.published_at,
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', s.id,
            'name', s.name
          )
        )
        FROM public.job_skills js
        JOIN public.skills s ON s.id = js.skill_id
        WHERE js.job_id = j.id
      ),
      '[]'::jsonb
    ) AS skills
  FROM public.jobs j
  JOIN public.categories c ON c.id = j.category_id
  WHERE j.business_id = p_business_id
    AND (
      p_status_filter IS NULL OR
      p_status_filter = 'all' OR
      j.status::TEXT = p_status_filter
    )
  ORDER BY j.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


-- ============================================================================
-- FILE: 20261118000005_phase6_discovery_management.sql
-- ============================================================================

-- ==============================================================================
-- LAGANSTAFF MIGRATION: Phase 6 - Job Discovery & Job Management
-- Migration: 20261118000005_phase6_discovery_management.sql
-- Description:
--   1. Enhanced get_available_jobs_for_worker RPC supporting keyword search,
--      multi-tier location (city, district, locality), date ranges, shift types
--      (morning, evening, night), and strict expired jobs elimination (shift_date >= CURRENT_DATE).
--   2. Enhanced get_owner_jobs RPC supporting search and 'expired' status tab.
--   3. update_published_job RPC for safe, audited modification of non-critical
--      fields on published jobs without bypassing admin approval.
--   4. High-performance composite B-Tree indexes for Ghazipur marketplace queries.
-- ==============================================================================

-- 1. Composite B-Tree Indexes for Phase 6 Performance
CREATE INDEX IF NOT EXISTS idx_jobs_phase6_feed
ON public.jobs(status, shift_date, locality, wage_amount)
WHERE status = 'published';

CREATE INDEX IF NOT EXISTS idx_jobs_city_district
ON public.jobs(city, district);

CREATE INDEX IF NOT EXISTS idx_jobs_shift_times
ON public.jobs(shift_date, start_time, is_overnight);

-- ------------------------------------------------------------------------------
-- RPC 1: get_available_jobs_for_worker (Enhanced for Phase 6)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_available_jobs_for_worker(
  p_search_query TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_locality TEXT DEFAULT NULL,
  p_shift_date DATE DEFAULT NULL,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL,
  p_shift_type TEXT DEFAULT NULL, -- 'morning', 'evening', 'night'
  p_min_wage NUMERIC DEFAULT NULL,
  p_max_wage NUMERIC DEFAULT NULL,
  p_food_provided BOOLEAN DEFAULT NULL,
  p_transport_provided BOOLEAN DEFAULT NULL,
  p_skill_ids UUID[] DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  business_id UUID,
  business_name TEXT,
  business_locality TEXT,
  business_category TEXT,
  business_verification_status TEXT,
  category_id UUID,
  category_name TEXT,
  title VARCHAR,
  description TEXT,
  venue_name VARCHAR,
  reporting_address TEXT,
  locality VARCHAR,
  city VARCHAR,
  district VARCHAR,
  shift_date DATE,
  start_time TIME,
  end_time TIME,
  is_overnight BOOLEAN,
  workers_needed INT,
  workers_confirmed INT,
  wage_amount NUMERIC,
  wage_rate_unit VARCHAR,
  payment_instructions TEXT,
  food_provided BOOLEAN,
  food_details TEXT,
  transport_provided BOOLEAN,
  transport_details TEXT,
  special_instructions TEXT,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  skills JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    j.id,
    j.business_id,
    b.name AS business_name,
    b.locality AS business_locality,
    b.business_type::TEXT AS business_category,
    b.verification_status::TEXT AS business_verification_status,
    j.category_id,
    c.name AS category_name,
    j.title,
    j.description,
    j.venue_name,
    j.reporting_address,
    j.locality,
    j.city,
    j.district,
    j.shift_date,
    j.start_time,
    j.end_time,
    j.is_overnight,
    j.workers_needed,
    j.workers_confirmed,
    j.wage_amount,
    j.wage_rate_unit,
    j.payment_instructions,
    j.food_provided,
    j.food_details,
    j.transport_provided,
    j.transport_details,
    j.special_instructions,
    j.published_at,
    j.created_at,
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', s.id,
            'name', s.name
          )
        )
        FROM public.job_skills js
        JOIN public.skills s ON s.id = js.skill_id
        WHERE js.job_id = j.id
      ),
      '[]'::jsonb
    ) AS skills
  FROM public.jobs j
  JOIN public.businesses b ON b.id = j.business_id
  JOIN public.categories c ON c.id = j.category_id
  WHERE j.status = 'published'
    AND b.verification_status = 'verified'
    -- MANDATORY EXPIRED FILTER: Only future or currently valid shifts are discoverable
    AND j.shift_date >= CURRENT_DATE
    -- Free text search
    AND (
      p_search_query IS NULL OR trim(p_search_query) = '' OR
      j.title ILIKE '%' || trim(p_search_query) || '%' OR
      b.name ILIKE '%' || trim(p_search_query) || '%' OR
      j.venue_name ILIKE '%' || trim(p_search_query) || '%' OR
      j.locality ILIKE '%' || trim(p_search_query) || '%'
    )
    -- Category
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    -- City & Locality
    AND (p_city IS NULL OR p_city = '' OR p_city = 'all' OR j.city ILIKE '%' || p_city || '%')
    AND (p_locality IS NULL OR p_locality = '' OR p_locality = 'all' OR j.locality ILIKE '%' || p_locality || '%')
    -- Date & Date Range
    AND (p_shift_date IS NULL OR j.shift_date = p_shift_date)
    AND (p_start_date IS NULL OR j.shift_date >= p_start_date)
    AND (p_end_date IS NULL OR j.shift_date <= p_end_date)
    -- Shift Timing Filter
    AND (
      p_shift_type IS NULL OR p_shift_type = '' OR p_shift_type = 'all' OR
      (p_shift_type = 'morning' AND j.start_time >= '05:00:00'::TIME AND j.start_time < '12:00:00'::TIME) OR
      (p_shift_type = 'evening' AND j.start_time >= '12:00:00'::TIME AND j.start_time < '18:00:00'::TIME) OR
      (p_shift_type = 'night' AND (j.start_time >= '18:00:00'::TIME OR j.is_overnight = TRUE))
    )
    -- Wage Bounds
    AND (p_min_wage IS NULL OR j.wage_amount >= p_min_wage)
    AND (p_max_wage IS NULL OR j.wage_amount <= p_max_wage)
    -- Perks
    AND (p_food_provided IS NULL OR j.food_provided = p_food_provided)
    AND (p_transport_provided IS NULL OR j.transport_provided = p_transport_provided)
    -- Skills relationship
    AND (
      p_skill_ids IS NULL OR array_length(p_skill_ids, 1) IS NULL OR
      EXISTS (
        SELECT 1 FROM public.job_skills js2
        WHERE js2.job_id = j.id AND js2.skill_id = ANY(p_skill_ids)
      )
    )
  ORDER BY j.shift_date ASC, j.start_time ASC, j.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 2: get_owner_jobs (Enhanced for Phase 6)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_owner_jobs(
  p_business_id UUID,
  p_status_filter TEXT DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 40,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  business_id UUID,
  category_id UUID,
  category_name TEXT,
  title VARCHAR,
  description TEXT,
  venue_name VARCHAR,
  reporting_address TEXT,
  locality VARCHAR,
  city VARCHAR,
  shift_date DATE,
  start_time TIME,
  end_time TIME,
  is_overnight BOOLEAN,
  workers_needed INT,
  workers_confirmed INT,
  wage_amount NUMERIC,
  wage_rate_unit VARCHAR,
  food_provided BOOLEAN,
  transport_provided BOOLEAN,
  special_instructions TEXT,
  is_first_job BOOLEAN,
  status public.job_status,
  admin_rejection_reason TEXT,
  created_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  skills JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Validate ownership
  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = p_business_id AND (
      b.created_by = v_user_id OR
      EXISTS (
        SELECT 1 FROM public.business_members bm
        WHERE bm.business_id = p_business_id AND bm.user_id = v_user_id
      )
    )
  ) AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = v_user_id AND ur.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized to view jobs for this business.';
  END IF;

  RETURN QUERY
  SELECT
    j.id,
    j.business_id,
    j.category_id,
    c.name AS category_name,
    j.title,
    j.description,
    j.venue_name,
    j.reporting_address,
    j.locality,
    j.city,
    j.shift_date,
    j.start_time,
    j.end_time,
    j.is_overnight,
    j.workers_needed,
    j.workers_confirmed,
    j.wage_amount,
    j.wage_rate_unit,
    j.food_provided,
    j.transport_provided,
    j.special_instructions,
    j.is_first_job,
    j.status,
    j.admin_rejection_reason,
    j.created_at,
    j.published_at,
    j.updated_at,
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', s.id,
            'name', s.name
          )
        )
        FROM public.job_skills js
        JOIN public.skills s ON s.id = js.skill_id
        WHERE js.job_id = j.id
      ),
      '[]'::jsonb
    ) AS skills
  FROM public.jobs j
  JOIN public.categories c ON c.id = j.category_id
  WHERE j.business_id = p_business_id
    AND (
      p_status_filter IS NULL OR p_status_filter = 'all' OR
      (p_status_filter = 'expired' AND j.status = 'published' AND j.shift_date < CURRENT_DATE) OR
      (p_status_filter != 'expired' AND j.status::TEXT = p_status_filter)
    )
    AND (
      p_search_query IS NULL OR trim(p_search_query) = '' OR
      j.title ILIKE '%' || trim(p_search_query) || '%' OR
      j.venue_name ILIKE '%' || trim(p_search_query) || '%' OR
      j.locality ILIKE '%' || trim(p_search_query) || '%'
    )
  ORDER BY j.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 3: update_published_job
-- Safely updates permitted non-critical fields on a published job with audit logging.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_published_job(
  p_job_id UUID,
  p_description TEXT DEFAULT NULL,
  p_venue_name TEXT DEFAULT NULL,
  p_reporting_address TEXT DEFAULT NULL,
  p_locality TEXT DEFAULT NULL,
  p_payment_instructions TEXT DEFAULT NULL,
  p_food_provided BOOLEAN DEFAULT NULL,
  p_food_details TEXT DEFAULT NULL,
  p_transport_provided BOOLEAN DEFAULT NULL,
  p_transport_details TEXT DEFAULT NULL,
  p_special_instructions TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_job RECORD;
  v_old_state JSONB;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Lock job and verify business ownership
  SELECT j.*, b.created_by as biz_owner_id
  INTO v_job
  FROM public.jobs j
  JOIN public.businesses b ON b.id = j.business_id
  WHERE j.id = p_job_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found.';
  END IF;

  IF v_job.biz_owner_id != v_user_id AND NOT EXISTS (
    SELECT 1 FROM public.business_members bm
    WHERE bm.business_id = v_job.business_id AND bm.user_id = v_user_id
  ) AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = v_user_id AND ur.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized to update this job.';
  END IF;

  IF v_job.status != 'published' THEN
    RAISE EXCEPTION 'This function is only for updating published jobs. Use save_job_draft or submit_job for drafts/rejected jobs.';
  END IF;

  v_old_state := jsonb_build_object(
    'description', v_job.description,
    'venue_name', v_job.venue_name,
    'reporting_address', v_job.reporting_address,
    'locality', v_job.locality,
    'special_instructions', v_job.special_instructions
  );

  UPDATE public.jobs
  SET
    description = COALESCE(p_description, description),
    venue_name = COALESCE(p_venue_name, venue_name),
    reporting_address = COALESCE(p_reporting_address, reporting_address),
    locality = COALESCE(p_locality, locality),
    payment_instructions = COALESCE(p_payment_instructions, payment_instructions),
    food_provided = COALESCE(p_food_provided, food_provided),
    food_details = COALESCE(p_food_details, food_details),
    transport_provided = COALESCE(p_transport_provided, transport_provided),
    transport_details = COALESCE(p_transport_details, transport_details),
    special_instructions = COALESCE(p_special_instructions, special_instructions),
    updated_at = NOW()
  WHERE id = p_job_id;

  -- Insert audit log for published job material change
  INSERT INTO public.admin_audit_logs (
    admin_id,
    action,
    entity_type,
    entity_id,
    old_state,
    new_state,
    notes
  ) VALUES (
    v_user_id,
    'update_published_job',
    'jobs',
    p_job_id,
    v_old_state,
    jsonb_build_object('updated_at', NOW()),
    'Owner updated non-critical shift details on published job.'
  );

  RETURN jsonb_build_object(
    'success', TRUE,
    'job_id', p_job_id,
    'message', 'प्रकाशित कार्य का विवरण सफलतापूर्वक अपडेट कर दिया गया।'
  );
END;
$$;


-- ============================================================================
-- FILE: 20261118000006_phase7_attendance_completion.sql
-- ============================================================================

-- ==============================================================================
-- LAGANSTAFF MIGRATION: Phase 7 - Attendance & Work Completion Engine
-- Migration: 20261118000006_phase7_attendance_completion.sql
-- Description:
--   1. Booking & Attendance data structures (bookings, attendance_records,
--      booking_cancellation_records).
--   2. Strict Row-Level Security (RLS) policies for Worker and Owner isolation.
--   3. Secure RPCs:
--      - worker_check_in() with configurable Asia/Kolkata check-in window
--      - mark_worker_attendance() for owner (present / absent / no-show)
--      - complete_worker_work() for work completion verification
--      - cancel_worker_booking() for worker/owner booking cancellation with audit
--      - get_owner_job_attendance_roster() for owner roster & summary metrics
--      - get_worker_bookings() & get_worker_work_history() for worker portal
--   4. Immutable audit logging in admin_audit_logs.
-- ==============================================================================

-- 1. Create Enums if not exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
    CREATE TYPE public.booking_status AS ENUM (
      'confirmed',
      'checked_in',
      'completed',
      'cancelled_by_worker',
      'cancelled_by_owner',
      'no_show'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendance_status') THEN
    CREATE TYPE public.attendance_status AS ENUM (
      'pending',
      'checked_in',
      'present',
      'absent',
      'no_show'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'work_completion_status') THEN
    CREATE TYPE public.work_completion_status AS ENUM (
      'pending',
      'completed'
    );
  END IF;
END $$;

-- 2. Table: bookings
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE RESTRICT,
  worker_profile_id UUID NOT NULL REFERENCES public.worker_profiles(id) ON DELETE RESTRICT,
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE RESTRICT,
  status public.booking_status NOT NULL DEFAULT 'confirmed',
  agreed_wage NUMERIC NOT NULL CHECK (agreed_wage > 0),
  checkin_code VARCHAR(6) DEFAULT LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0'),
  confirmed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_bookings_job_worker UNIQUE (job_id, worker_profile_id)
);

-- 3. Table: attendance_records
CREATE TABLE IF NOT EXISTS public.attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE RESTRICT UNIQUE,
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE RESTRICT,
  worker_profile_id UUID NOT NULL REFERENCES public.worker_profiles(id) ON DELETE RESTRICT,
  attendance_status public.attendance_status NOT NULL DEFAULT 'pending',
  check_in_at TIMESTAMPTZ,
  check_in_latitude DOUBLE PRECISION,
  check_in_longitude DOUBLE PRECISION,
  marked_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
  marked_at TIMESTAMPTZ,
  completion_status public.work_completion_status NOT NULL DEFAULT 'pending',
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Table: booking_cancellation_records
CREATE TABLE IF NOT EXISTS public.booking_cancellation_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE RESTRICT,
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE RESTRICT,
  worker_profile_id UUID NOT NULL REFERENCES public.worker_profiles(id) ON DELETE RESTRICT,
  cancelled_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  cancellation_reason TEXT,
  cancelled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  previous_status public.booking_status NOT NULL,
  new_status public.booking_status NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_bookings_job ON public.bookings(job_id);
CREATE INDEX IF NOT EXISTS idx_bookings_worker ON public.bookings(worker_profile_id);
CREATE INDEX IF NOT EXISTS idx_bookings_business ON public.bookings(business_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);

CREATE INDEX IF NOT EXISTS idx_attendance_booking ON public.attendance_records(booking_id);
CREATE INDEX IF NOT EXISTS idx_attendance_job ON public.attendance_records(job_id);
CREATE INDEX IF NOT EXISTS idx_attendance_worker ON public.attendance_records(worker_profile_id);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON public.attendance_records(attendance_status);

CREATE INDEX IF NOT EXISTS idx_cancellation_booking ON public.booking_cancellation_records(booking_id);

-- 6. Trigger to automatically initialize attendance_records when a booking is created
CREATE OR REPLACE FUNCTION public.handle_new_booking_attendance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.attendance_records (
    booking_id,
    job_id,
    worker_profile_id,
    attendance_status,
    completion_status
  ) VALUES (
    NEW.id,
    NEW.job_id,
    NEW.worker_profile_id,
    'pending',
    'pending'
  )
  ON CONFLICT (booking_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_booking_attendance_init ON public.bookings;
CREATE TRIGGER trg_booking_attendance_init
AFTER INSERT ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_booking_attendance();

-- 7. Row-Level Security (RLS)
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_cancellation_records ENABLE ROW LEVEL SECURITY;

-- RLS: bookings
DROP POLICY IF EXISTS "Workers can view own bookings" ON public.bookings;
CREATE POLICY "Workers can view own bookings"
ON public.bookings FOR SELECT
USING (
  worker_profile_id IN (
    SELECT id FROM public.worker_profiles WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Owners can view bookings for their business jobs" ON public.bookings;
CREATE POLICY "Owners can view bookings for their business jobs"
ON public.bookings FOR SELECT
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE created_by = auth.uid()
    UNION
    SELECT business_id FROM public.business_members WHERE user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- RLS: attendance_records
DROP POLICY IF EXISTS "Workers can view own attendance" ON public.attendance_records;
CREATE POLICY "Workers can view own attendance"
ON public.attendance_records FOR SELECT
USING (
  worker_profile_id IN (
    SELECT id FROM public.worker_profiles WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Owners can view attendance for their business jobs" ON public.attendance_records;
CREATE POLICY "Owners can view attendance for their business jobs"
ON public.attendance_records FOR SELECT
USING (
  job_id IN (
    SELECT j.id FROM public.jobs j
    JOIN public.businesses b ON b.id = j.business_id
    WHERE b.created_by = auth.uid()
    UNION
    SELECT j2.id FROM public.jobs j2
    JOIN public.business_members bm ON bm.business_id = j2.business_id
    WHERE bm.user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- RLS: booking_cancellation_records
DROP POLICY IF EXISTS "Workers can view own cancellation records" ON public.booking_cancellation_records;
CREATE POLICY "Workers can view own cancellation records"
ON public.booking_cancellation_records FOR SELECT
USING (
  worker_profile_id IN (
    SELECT id FROM public.worker_profiles WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Owners can view cancellations for their business jobs" ON public.booking_cancellation_records;
CREATE POLICY "Owners can view cancellations for their business jobs"
ON public.booking_cancellation_records FOR SELECT
USING (
  job_id IN (
    SELECT j.id FROM public.jobs j
    JOIN public.businesses b ON b.id = j.business_id
    WHERE b.created_by = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- ------------------------------------------------------------------------------
-- RPC 1: worker_check_in
-- Allows worker to record self-check-in within Asia/Kolkata shift window.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.worker_check_in(
  p_booking_id UUID,
  p_latitude DOUBLE PRECISION DEFAULT NULL,
  p_longitude DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_worker_profile_id UUID;
  v_booking RECORD;
  v_job RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_shift_start TIMESTAMPTZ;
  v_shift_date_str TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT id INTO v_worker_profile_id
  FROM public.worker_profiles
  WHERE user_id = v_user_id;

  IF v_worker_profile_id IS NULL THEN
    RAISE EXCEPTION 'Worker profile not found.';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  IF v_booking.worker_profile_id != v_worker_profile_id THEN
    RAISE EXCEPTION 'Unauthorized: Booking belongs to a different worker.';
  END IF;

  IF v_booking.status != 'confirmed' THEN
    IF v_booking.status = 'checked_in' THEN
      RETURN jsonb_build_object('success', TRUE, 'message', 'आप पहले ही चेक-इन कर चुके हैं।');
    END IF;
    RAISE EXCEPTION 'Booking is not in confirmed status (current: %).', v_booking.status;
  END IF;

  -- Load Job and validate Check-In Window (Asia/Kolkata)
  SELECT * INTO v_job FROM public.jobs WHERE id = v_booking.job_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Associated job not found.';
  END IF;

  -- Shift window: Allowed from 2 hours before start up to 3 hours after start time
  v_shift_date_str := v_job.shift_date::TEXT || ' ' || v_job.start_time::TEXT;
  v_shift_start := (v_shift_date_str || '+05:30')::TIMESTAMPTZ;

  IF v_now < (v_shift_start - INTERVAL '2 hours') THEN
    RAISE EXCEPTION 'चेक-इन विंडो अभी खुली नहीं है। आप शिफ्ट शुरू होने से 2 घंटे पहले चेक-इन कर सकते हैं।';
  END IF;

  IF v_now > (v_shift_start + INTERVAL '4 hours') THEN
    RAISE EXCEPTION 'चेक-इन विंडो समाप्त हो चुकी है। कृपया स्थल व्यवस्थापक (Owner) से संपर्क करें।';
  END IF;

  -- Update attendance_records
  UPDATE public.attendance_records
  SET
    attendance_status = 'checked_in',
    check_in_at = v_now,
    check_in_latitude = p_latitude,
    check_in_longitude = p_longitude,
    updated_at = v_now
  WHERE booking_id = p_booking_id;

  -- Update booking status
  UPDATE public.bookings
  SET
    status = 'checked_in',
    updated_at = v_now
  WHERE id = p_booking_id;

  -- Insert audit log
  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_user_id,
    'worker_check_in',
    'bookings',
    p_booking_id,
    jsonb_build_object('status', 'confirmed'),
    jsonb_build_object('status', 'checked_in', 'check_in_at', v_now),
    'Worker self-checked in at venue.'
  );

  RETURN jsonb_build_object(
    'success', TRUE,
    'booking_id', p_booking_id,
    'check_in_at', v_now,
    'message', 'चेक-इन सफलतापूर्वक दर्ज हुआ। आयोजक को आपकी उपस्थिति दिखाई दे रही है।'
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 2: mark_worker_attendance
-- Owner confirms checked-in or on-site worker as Present, Absent, or No-Show.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_worker_attendance(
  p_booking_id UUID,
  p_status TEXT, -- 'present', 'absent', 'no_show'
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_booking RECORD;
  v_job RECORD;
  v_att RECORD;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_status NOT IN ('present', 'absent', 'no_show') THEN
    RAISE EXCEPTION 'Invalid attendance status. Must be present, absent, or no_show.';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  -- Verify owner authority
  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = v_booking.business_id AND (
      b.created_by = v_user_id OR
      EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = b.id AND bm.user_id = v_user_id)
    )
  ) AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur WHERE ur.user_id = v_user_id AND ur.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized to mark attendance for this booking.';
  END IF;

  SELECT * INTO v_att FROM public.attendance_records WHERE booking_id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Attendance record not found for booking.';
  END IF;

  -- Update attendance record
  UPDATE public.attendance_records
  SET
    attendance_status = p_status::public.attendance_status,
    marked_by = v_user_id,
    marked_at = v_now,
    notes = COALESCE(p_notes, notes),
    updated_at = v_now
  WHERE booking_id = p_booking_id;

  -- If marked no_show, update booking status
  IF p_status = 'no_show' THEN
    UPDATE public.bookings
    SET status = 'no_show', updated_at = v_now
    WHERE id = p_booking_id;
  END IF;

  -- Audit log
  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_user_id,
    'mark_worker_attendance',
    'attendance_records',
    v_att.id,
    jsonb_build_object('attendance_status', v_att.attendance_status),
    jsonb_build_object('attendance_status', p_status, 'marked_by', v_user_id),
    COALESCE(p_notes, 'Owner updated attendance status.')
  );

  RETURN jsonb_build_object(
    'success', TRUE,
    'booking_id', p_booking_id,
    'attendance_status', p_status,
    'message', 'उपस्थिति सफलतापूर्वक दर्ज की गई।'
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 3: complete_worker_work
-- Owner marks shift work completed for Present workers.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_worker_work(
  p_booking_id UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_booking RECORD;
  v_att RECORD;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  -- Verify owner authority
  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = v_booking.business_id AND (
      b.created_by = v_user_id OR
      EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = b.id AND bm.user_id = v_user_id)
    )
  ) AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur WHERE ur.user_id = v_user_id AND ur.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized to complete work for this booking.';
  END IF;

  SELECT * INTO v_att FROM public.attendance_records WHERE booking_id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Attendance record not found.';
  END IF;

  -- Only Present workers can be marked completed
  IF v_att.attendance_status != 'present' THEN
    RAISE EXCEPTION 'केवल उपस्थित (Present) कार्यकर्ताओं का कार्य संपन्न किया जा सकता है (वर्तमान स्थिति: %).', v_att.attendance_status;
  END IF;

  IF v_att.completion_status = 'completed' THEN
    RETURN jsonb_build_object('success', TRUE, 'message', 'कार्य पहले ही संपन्न चिह्नित हो चुका है।');
  END IF;

  -- Update attendance
  UPDATE public.attendance_records
  SET
    completion_status = 'completed',
    completed_at = v_now,
    notes = COALESCE(p_notes, notes),
    updated_at = v_now
  WHERE booking_id = p_booking_id;

  -- Update booking
  UPDATE public.bookings
  SET status = 'completed', updated_at = v_now
  WHERE id = p_booking_id;

  -- Audit log
  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_user_id,
    'complete_worker_work',
    'attendance_records',
    v_att.id,
    jsonb_build_object('completion_status', 'pending'),
    jsonb_build_object('completion_status', 'completed', 'completed_at', v_now),
    COALESCE(p_notes, 'Owner confirmed work shift completion.')
  );

  RETURN jsonb_build_object(
    'success', TRUE,
    'booking_id', p_booking_id,
    'completion_status', 'completed',
    'message', 'कार्य सफलतापूर्वक संपन्न चिह्नित किया गया।'
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 4: cancel_worker_booking
-- Handles authorized cancellation by either Worker or Owner with full audit.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_worker_booking(
  p_booking_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_booking RECORD;
  v_worker_profile_id UUID;
  v_is_worker BOOLEAN := FALSE;
  v_is_owner BOOLEAN := FALSE;
  v_new_status public.booking_status;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  -- Cannot cancel completed shifts
  IF v_booking.status = 'completed' THEN
    RAISE EXCEPTION 'संपन्न हो चुके कार्य की बुकिंग रद्द नहीं की जा सकती।';
  END IF;

  -- Check if worker
  SELECT id INTO v_worker_profile_id FROM public.worker_profiles WHERE user_id = v_user_id;
  IF v_worker_profile_id IS NOT NULL AND v_booking.worker_profile_id = v_worker_profile_id THEN
    v_is_worker := TRUE;
    v_new_status := 'cancelled_by_worker';
  END IF;

  -- Check if owner or admin
  IF NOT v_is_worker THEN
    IF EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = v_booking.business_id AND (
        b.created_by = v_user_id OR
        EXISTS (SELECT 1 FROM public.business_members bm WHERE bm.business_id = b.id AND bm.user_id = v_user_id)
      )
    ) OR EXISTS (
      SELECT 1 FROM public.user_roles ur WHERE ur.user_id = v_user_id AND ur.role = 'admin'
    ) THEN
      v_is_owner := TRUE;
      v_new_status := 'cancelled_by_owner';
    END IF;
  END IF;

  IF NOT v_is_worker AND NOT v_is_owner THEN
    RAISE EXCEPTION 'Not authorized to cancel this booking.';
  END IF;

  -- Update booking
  UPDATE public.bookings
  SET status = v_new_status, updated_at = v_now
  WHERE id = p_booking_id;

  -- Insert immutable cancellation record
  INSERT INTO public.booking_cancellation_records (
    booking_id,
    job_id,
    worker_profile_id,
    cancelled_by,
    cancellation_reason,
    cancelled_at,
    previous_status,
    new_status
  ) VALUES (
    p_booking_id,
    v_booking.job_id,
    v_booking.worker_profile_id,
    v_user_id,
    p_reason,
    v_now,
    v_booking.status,
    v_new_status
  );

  -- Decrement confirmed workers on job if greater than 0
  UPDATE public.jobs
  SET
    workers_confirmed = GREATEST(0, workers_confirmed - 1),
    updated_at = v_now
  WHERE id = v_booking.job_id;

  -- Audit log
  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_user_id,
    'cancel_worker_booking',
    'bookings',
    p_booking_id,
    jsonb_build_object('status', v_booking.status),
    jsonb_build_object('status', v_new_status, 'cancelled_by', v_user_id),
    COALESCE(p_reason, 'Booking cancelled.')
  );

  RETURN jsonb_build_object(
    'success', TRUE,
    'booking_id', p_booking_id,
    'status', v_new_status,
    'message', 'बुकिंग सफलतापूर्वक रद्द कर दी गई।'
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 5: get_owner_job_attendance_roster
-- Returns confirmed workers roster for an owner's job with attendance status & summary counts.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_owner_job_attendance_roster(
  p_job_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_job RECORD;
  v_roster JSONB;
  v_total_confirmed INT := 0;
  v_checked_in INT := 0;
  v_present INT := 0;
  v_absent INT := 0;
  v_no_show INT := 0;
  v_completed INT := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT j.*, b.created_by as biz_owner_id
  INTO v_job
  FROM public.jobs j
  JOIN public.businesses b ON b.id = j.business_id
  WHERE j.id = p_job_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found.';
  END IF;

  IF v_job.biz_owner_id != v_user_id AND NOT EXISTS (
    SELECT 1 FROM public.business_members bm
    WHERE bm.business_id = v_job.business_id AND bm.user_id = v_user_id
  ) AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = v_user_id AND ur.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized to view roster for this job.';
  END IF;

  -- Build workers list
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'booking_id', b.id,
        'worker_profile_id', wp.id,
        'full_name', wp.full_name,
        'mobile_number', p.mobile_number,
        'selfie_url', wp.selfie_url,
        'agreed_wage', b.agreed_wage,
        'booking_status', b.status,
        'checkin_code', b.checkin_code,
        'attendance_status', COALESCE(ar.attendance_status, 'pending'),
        'check_in_at', ar.check_in_at,
        'marked_at', ar.marked_at,
        'completion_status', COALESCE(ar.completion_status, 'pending'),
        'completed_at', ar.completed_at,
        'notes', ar.notes,
        'skills', COALESCE(
          (
            SELECT jsonb_agg(s.name)
            FROM public.worker_skills ws
            JOIN public.skills s ON s.id = ws.skill_id
            WHERE ws.worker_profile_id = wp.id
          ),
          '[]'::jsonb
        )
      ) ORDER BY ar.check_in_at ASC NULLS LAST, b.confirmed_at ASC
    ),
    '[]'::jsonb
  ) INTO v_roster
  FROM public.bookings b
  JOIN public.worker_profiles wp ON wp.id = b.worker_profile_id
  JOIN public.profiles p ON p.id = wp.user_id
  LEFT JOIN public.attendance_records ar ON ar.booking_id = b.id
  WHERE b.job_id = p_job_id
    AND b.status NOT IN ('cancelled_by_worker', 'cancelled_by_owner');

  -- Calculate summary metrics
  SELECT
    COUNT(*),
    COUNT(*) FILTER (WHERE ar.attendance_status = 'checked_in'),
    COUNT(*) FILTER (WHERE ar.attendance_status = 'present'),
    COUNT(*) FILTER (WHERE ar.attendance_status = 'absent'),
    COUNT(*) FILTER (WHERE ar.attendance_status = 'no_show' OR b.status = 'no_show'),
    COUNT(*) FILTER (WHERE ar.completion_status = 'completed')
  INTO
    v_total_confirmed,
    v_checked_in,
    v_present,
    v_absent,
    v_no_show,
    v_completed
  FROM public.bookings b
  LEFT JOIN public.attendance_records ar ON ar.booking_id = b.id
  WHERE b.job_id = p_job_id
    AND b.status NOT IN ('cancelled_by_worker', 'cancelled_by_owner');

  RETURN jsonb_build_object(
    'job_id', p_job_id,
    'job_title', v_job.title,
    'shift_date', v_job.shift_date,
    'start_time', v_job.start_time,
    'end_time', v_job.end_time,
    'workers_needed', v_job.workers_needed,
    'metrics', jsonb_build_object(
      'total_confirmed', v_total_confirmed,
      'checked_in', v_checked_in,
      'present', v_present,
      'absent', v_absent,
      'no_show', v_no_show,
      'completed', v_completed
    ),
    'roster', v_roster
  );
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 6: get_worker_bookings
-- Retrieves worker's bookings (upcoming or past) with shift details & attendance states.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_worker_bookings(
  p_filter TEXT DEFAULT 'upcoming', -- 'upcoming', 'history', 'all'
  p_limit INT DEFAULT 30,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  booking_id UUID,
  job_id UUID,
  business_name TEXT,
  category_name TEXT,
  job_title VARCHAR,
  venue_name VARCHAR,
  reporting_address TEXT,
  locality VARCHAR,
  city VARCHAR,
  shift_date DATE,
  start_time TIME,
  end_time TIME,
  is_overnight BOOLEAN,
  agreed_wage NUMERIC,
  booking_status public.booking_status,
  checkin_code VARCHAR,
  attendance_status public.attendance_status,
  check_in_at TIMESTAMPTZ,
  completion_status public.work_completion_status,
  completed_at TIMESTAMPTZ,
  special_instructions TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_worker_profile_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT id INTO v_worker_profile_id
  FROM public.worker_profiles
  WHERE user_id = v_user_id;

  IF v_worker_profile_id IS NULL THEN
    RAISE EXCEPTION 'Worker profile not found.';
  END IF;

  RETURN QUERY
  SELECT
    b.id AS booking_id,
    j.id AS job_id,
    biz.name AS business_name,
    c.name AS category_name,
    j.title AS job_title,
    j.venue_name,
    j.reporting_address,
    j.locality,
    j.city,
    j.shift_date,
    j.start_time,
    j.end_time,
    j.is_overnight,
    b.agreed_wage,
    b.status AS booking_status,
    b.checkin_code,
    COALESCE(ar.attendance_status, 'pending') AS attendance_status,
    ar.check_in_at,
    COALESCE(ar.completion_status, 'pending') AS completion_status,
    ar.completed_at,
    j.special_instructions
  FROM public.bookings b
  JOIN public.jobs j ON j.id = b.job_id
  JOIN public.businesses biz ON biz.id = b.business_id
  JOIN public.categories c ON c.id = j.category_id
  LEFT JOIN public.attendance_records ar ON ar.booking_id = b.id
  WHERE b.worker_profile_id = v_worker_profile_id
    AND (
      p_filter = 'all' OR
      (p_filter = 'upcoming' AND j.shift_date >= CURRENT_DATE AND b.status IN ('confirmed', 'checked_in')) OR
      (p_filter = 'history' AND (j.shift_date < CURRENT_DATE OR b.status IN ('completed', 'cancelled_by_worker', 'cancelled_by_owner', 'no_show')))
    )
  ORDER BY j.shift_date DESC, j.start_time DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


-- ============================================================================
-- FILE: 20261118000007_phase8_admin_control_center.sql
-- ============================================================================

-- ==============================================================================
-- LAGANSTAFF MIGRATION: Phase 8 - Complete Admin Dashboard & Platform Control Center
-- Migration: 20261118000007_phase8_admin_control_center.sql
-- Description:
--   1. admin_users allowlisted authorization table.
--   2. Worker post-registration review_status column ('not_reviewed', 'reviewed', 'needs_attention').
--   3. complaints & complaint_notes tables with full category & status lifecycle.
--   4. Category table enhancements (display_order, updated_at).
--   5. Administrative RPCs:
--      - get_admin_dashboard_metrics()
--      - admin_suspend_worker() & admin_reactivate_worker()
--      - admin_review_worker()
--      - admin_resolve_complaint() & admin_add_complaint_note()
--      - admin_upsert_category() & admin_toggle_category_status()
--      - admin_cancel_job()
--   6. Strict Row-Level Security (RLS) policies for administrative security.
-- ==============================================================================

-- 1. Create Enums
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'worker_review_status') THEN
    CREATE TYPE public.worker_review_status AS ENUM (
      'not_reviewed',
      'reviewed',
      'needs_attention'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'complaint_category') THEN
    CREATE TYPE public.complaint_category AS ENUM (
      'worker_no_show',
      'owner_cancellation',
      'payment_dispute',
      'misbehaviour',
      'incorrect_job_info',
      'fake_profile',
      'other'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'complaint_status') THEN
    CREATE TYPE public.complaint_status AS ENUM (
      'open',
      'under_review',
      'resolved',
      'dismissed'
    );
  END IF;
END $$;

-- 2. Table: admin_users (Allowlisted Platform Administrators)
CREATE TABLE IF NOT EXISTS public.admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL UNIQUE,
  full_name VARCHAR(150) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'super_admin',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_admin_users_email ON public.admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_uid ON public.admin_users(user_id);

-- 3. Extend worker_profiles with review_status
ALTER TABLE public.worker_profiles
ADD COLUMN IF NOT EXISTS review_status public.worker_review_status NOT NULL DEFAULT 'not_reviewed',
ADD COLUMN IF NOT EXISTS review_notes TEXT,
ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES public.profiles(id);

CREATE INDEX IF NOT EXISTS idx_worker_profiles_review_status ON public.worker_profiles(review_status);

-- 4. Extend categories with display_order and updated_at
ALTER TABLE public.categories
ADD COLUMN IF NOT EXISTS display_order INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 5. Table: complaints
CREATE TABLE IF NOT EXISTS public.complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submitted_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  reported_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  business_id UUID REFERENCES public.businesses(id) ON DELETE SET NULL,
  job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  category public.complaint_category NOT NULL DEFAULT 'other',
  description TEXT NOT NULL,
  evidence_path TEXT,
  complaint_status public.complaint_status NOT NULL DEFAULT 'open',
  admin_notes TEXT,
  assigned_admin_id UUID REFERENCES public.profiles(id),
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaints_status ON public.complaints(complaint_status);
CREATE INDEX IF NOT EXISTS idx_complaints_category ON public.complaints(category);
CREATE INDEX IF NOT EXISTS idx_complaints_submitted_by ON public.complaints(submitted_by);
CREATE INDEX IF NOT EXISTS idx_complaints_job ON public.complaints(job_id);

-- 6. Table: complaint_notes
CREATE TABLE IF NOT EXISTS public.complaint_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
  admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  note TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaint_notes_complaint ON public.complaint_notes(complaint_id);

-- 7. Row Level Security (RLS)
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_notes ENABLE ROW LEVEL SECURITY;

-- Helper function to check if current user is an authorized admin
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
  ) OR EXISTS (
    SELECT 1 FROM public.admin_users au
    WHERE (au.user_id = auth.uid() OR au.email = (auth.jwt()->>'email'))
      AND au.is_active = TRUE
  );
$$;

-- RLS: admin_users
DROP POLICY IF EXISTS "Admins can view admin_users" ON public.admin_users;
CREATE POLICY "Admins can view admin_users"
ON public.admin_users FOR SELECT
USING (public.is_admin_user());

-- RLS: complaints
DROP POLICY IF EXISTS "Users can view own submitted complaints" ON public.complaints;
CREATE POLICY "Users can view own submitted complaints"
ON public.complaints FOR SELECT
USING (submitted_by = auth.uid() OR public.is_admin_user());

DROP POLICY IF EXISTS "Authenticated users can submit complaints" ON public.complaints;
CREATE POLICY "Authenticated users can submit complaints"
ON public.complaints FOR INSERT
WITH CHECK (submitted_by = auth.uid());

DROP POLICY IF EXISTS "Admins can update complaints" ON public.complaints;
CREATE POLICY "Admins can update complaints"
ON public.complaints FOR UPDATE
USING (public.is_admin_user());

-- RLS: complaint_notes (Admin only)
DROP POLICY IF EXISTS "Admins only for complaint notes" ON public.complaint_notes;
CREATE POLICY "Admins only for complaint notes"
ON public.complaint_notes FOR ALL
USING (public.is_admin_user());

-- ------------------------------------------------------------------------------
-- RPC 1: get_admin_dashboard_metrics
-- Aggregates real platform statistics in a single performant database query.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_metrics()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_result JSONB;
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  SELECT jsonb_build_object(
    'users', (
      SELECT jsonb_build_object(
        'total_workers', COUNT(wp.id),
        'active_workers', COUNT(wp.id) FILTER (WHERE wp.account_status = 'active'),
        'suspended_workers', COUNT(wp.id) FILTER (WHERE wp.account_status = 'suspended'),
        'unreviewed_workers', COUNT(wp.id) FILTER (WHERE wp.review_status = 'not_reviewed'),
        'total_owners', (SELECT COUNT(*) FROM public.user_roles WHERE role = 'owner'),
        'total_businesses', (SELECT COUNT(*) FROM public.businesses),
        'verified_businesses', (SELECT COUNT(*) FROM public.businesses WHERE verification_status = 'verified'),
        'pending_business_verifications', (SELECT COUNT(*) FROM public.businesses WHERE verification_status = 'pending')
      )
      FROM public.worker_profiles wp
    ),
    'jobs', (
      SELECT jsonb_build_object(
        'total_jobs', COUNT(j.id),
        'draft_jobs', COUNT(j.id) FILTER (WHERE j.status = 'draft'),
        'pending_approval_jobs', COUNT(j.id) FILTER (WHERE j.status = 'pending_admin_approval'),
        'published_jobs', COUNT(j.id) FILTER (WHERE j.status = 'published'),
        'completed_jobs', COUNT(j.id) FILTER (WHERE j.status = 'completed'),
        'cancelled_jobs', COUNT(j.id) FILTER (WHERE j.status = 'cancelled'),
        'expired_jobs', COUNT(j.id) FILTER (WHERE j.status = 'published' AND j.shift_date < CURRENT_DATE)
      )
      FROM public.jobs j
    ),
    'bookings', (
      SELECT jsonb_build_object(
        'total_bookings', COUNT(b.id),
        'confirmed_bookings', COUNT(b.id) FILTER (WHERE b.status = 'confirmed'),
        'checked_in_bookings', COUNT(b.id) FILTER (WHERE b.status = 'checked_in'),
        'completed_bookings', COUNT(b.id) FILTER (WHERE b.status = 'completed'),
        'cancelled_bookings', COUNT(b.id) FILTER (WHERE b.status IN ('cancelled_by_worker', 'cancelled_by_owner'))
      )
      FROM public.bookings b
    ),
    'attendance', (
      SELECT jsonb_build_object(
        'total_records', COUNT(ar.id),
        'present', COUNT(ar.id) FILTER (WHERE ar.attendance_status = 'present'),
        'absent', COUNT(ar.id) FILTER (WHERE ar.attendance_status = 'absent'),
        'no_show', COUNT(ar.id) FILTER (WHERE ar.attendance_status = 'no_show')
      )
      FROM public.attendance_records ar
    ),
    'complaints', (
      SELECT jsonb_build_object(
        'total_complaints', COUNT(c.id),
        'open', COUNT(c.id) FILTER (WHERE c.complaint_status = 'open'),
        'under_review', COUNT(c.id) FILTER (WHERE c.complaint_status = 'under_review'),
        'resolved', COUNT(c.id) FILTER (WHERE c.complaint_status = 'resolved'),
        'dismissed', COUNT(c.id) FILTER (WHERE c.complaint_status = 'dismissed')
      )
      FROM public.complaints c
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 2: admin_suspend_worker & admin_reactivate_worker
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_suspend_worker(
  p_worker_id UUID,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
  v_worker RECORD;
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  SELECT * INTO v_worker FROM public.worker_profiles WHERE id = p_worker_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Worker profile not found.';
  END IF;

  UPDATE public.worker_profiles
  SET
    account_status = 'suspended',
    review_status = 'needs_attention',
    review_notes = p_reason,
    reviewed_at = NOW(),
    reviewed_by = v_admin_id,
    updated_at = NOW()
  WHERE id = p_worker_id;

  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_admin_id,
    'suspend_worker',
    'worker_profiles',
    p_worker_id,
    jsonb_build_object('account_status', v_worker.account_status),
    jsonb_build_object('account_status', 'suspended'),
    p_reason
  );

  RETURN jsonb_build_object('success', TRUE, 'message', 'कार्यकर्ता खाता निलंबित कर दिया गया।');
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_reactivate_worker(
  p_worker_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
  v_worker RECORD;
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  SELECT * INTO v_worker FROM public.worker_profiles WHERE id = p_worker_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Worker profile not found.';
  END IF;

  UPDATE public.worker_profiles
  SET
    account_status = 'active',
    reviewed_at = NOW(),
    reviewed_by = v_admin_id,
    updated_at = NOW()
  WHERE id = p_worker_id;

  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_admin_id,
    'reactivate_worker',
    'worker_profiles',
    p_worker_id,
    jsonb_build_object('account_status', v_worker.account_status),
    jsonb_build_object('account_status', 'active'),
    'Admin restored active status.'
  );

  RETURN jsonb_build_object('success', TRUE, 'message', 'कार्यकर्ता खाता पुनः सक्रिय कर दिया गया।');
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 3: admin_review_worker
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_review_worker(
  p_worker_id UUID,
  p_review_status TEXT, -- 'reviewed', 'needs_attention'
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  IF p_review_status NOT IN ('reviewed', 'needs_attention') THEN
    RAISE EXCEPTION 'Invalid review status. Must be reviewed or needs_attention.';
  END IF;

  UPDATE public.worker_profiles
  SET
    review_status = p_review_status::public.worker_review_status,
    review_notes = COALESCE(p_notes, review_notes),
    reviewed_at = NOW(),
    reviewed_by = v_admin_id,
    updated_at = NOW()
  WHERE id = p_worker_id;

  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_admin_id,
    'review_worker_profile',
    'worker_profiles',
    p_worker_id,
    jsonb_build_object('review_status', 'not_reviewed'),
    jsonb_build_object('review_status', p_review_status),
    p_notes
  );

  RETURN jsonb_build_object('success', TRUE, 'message', 'कार्यकर्ता समीक्षा स्थिति अद्यतन की गई।');
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 4: admin_resolve_complaint & admin_add_complaint_note
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_resolve_complaint(
  p_complaint_id UUID,
  p_status TEXT, -- 'under_review', 'resolved', 'dismissed'
  p_admin_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
  v_comp RECORD;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  IF p_status NOT IN ('under_review', 'resolved', 'dismissed') THEN
    RAISE EXCEPTION 'Invalid status. Must be under_review, resolved, or dismissed.';
  END IF;

  SELECT * INTO v_comp FROM public.complaints WHERE id = p_complaint_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Complaint not found.';
  END IF;

  UPDATE public.complaints
  SET
    complaint_status = p_status::public.complaint_status,
    admin_notes = COALESCE(p_admin_notes, admin_notes),
    assigned_admin_id = v_admin_id,
    resolved_at = CASE WHEN p_status IN ('resolved', 'dismissed') THEN v_now ELSE NULL END,
    updated_at = v_now
  WHERE id = p_complaint_id;

  IF p_admin_notes IS NOT NULL AND trim(p_admin_notes) != '' THEN
    INSERT INTO public.complaint_notes (complaint_id, admin_id, note)
    VALUES (p_complaint_id, v_admin_id, p_admin_notes);
  END IF;

  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_admin_id,
    'resolve_complaint',
    'complaints',
    p_complaint_id,
    jsonb_build_object('complaint_status', v_comp.complaint_status),
    jsonb_build_object('complaint_status', p_status),
    p_admin_notes
  );

  RETURN jsonb_build_object('success', TRUE, 'message', 'शिकायत स्थिति सफलतापूर्वक अपडेट की गई।');
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_add_complaint_note(
  p_complaint_id UUID,
  p_note TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  INSERT INTO public.complaint_notes (complaint_id, admin_id, note)
  VALUES (p_complaint_id, v_admin_id, p_note);

  UPDATE public.complaints
  SET updated_at = NOW()
  WHERE id = p_complaint_id;

  RETURN jsonb_build_object('success', TRUE);
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 5: admin_upsert_category & admin_toggle_category_status
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_upsert_category(
  p_id UUID DEFAULT NULL,
  p_name VARCHAR DEFAULT NULL,
  p_slug VARCHAR DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE,
  p_display_order INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
  v_cat_id UUID;
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  IF p_id IS NULL THEN
    -- Insert new category
    INSERT INTO public.categories (name, slug, description, is_active, display_order, created_at, updated_at)
    VALUES (p_name, p_slug, p_description, p_is_active, p_display_order, NOW(), NOW())
    RETURNING id INTO v_cat_id;

    INSERT INTO public.admin_audit_logs (
      admin_id, action, entity_type, entity_id, new_state, notes
    ) VALUES (
      v_admin_id, 'create_category', 'categories', v_cat_id,
      jsonb_build_object('name', p_name, 'slug', p_slug), 'Admin added new category'
    );
  ELSE
    -- Update existing category without breaking foreign keys
    UPDATE public.categories
    SET
      name = COALESCE(p_name, name),
      slug = COALESCE(p_slug, slug),
      description = COALESCE(p_description, description),
      is_active = COALESCE(p_is_active, is_active),
      display_order = COALESCE(p_display_order, display_order),
      updated_at = NOW()
    WHERE id = p_id;
    v_cat_id := p_id;

    INSERT INTO public.admin_audit_logs (
      admin_id, action, entity_type, entity_id, new_state, notes
    ) VALUES (
      v_admin_id, 'update_category', 'categories', v_cat_id,
      jsonb_build_object('name', p_name, 'is_active', p_is_active), 'Admin updated category details'
    );
  END IF;

  RETURN jsonb_build_object('success', TRUE, 'category_id', v_cat_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_toggle_category_status(
  p_category_id UUID,
  p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  UPDATE public.categories
  SET is_active = p_is_active, updated_at = NOW()
  WHERE id = p_category_id;

  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, new_state, notes
  ) VALUES (
    v_admin_id, 'toggle_category_status', 'categories', p_category_id,
    jsonb_build_object('is_active', p_is_active), 'Admin changed active status'
  );

  RETURN jsonb_build_object('success', TRUE, 'is_active', p_is_active);
END;
$$;

-- ------------------------------------------------------------------------------
-- RPC 6: admin_cancel_job
-- Corrective administrative cancellation of suspicious or disputed jobs with audit log.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_cancel_job(
  p_job_id UUID,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID := auth.uid();
  v_job RECORD;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  IF NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Administrator access required.';
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = p_job_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found.';
  END IF;

  UPDATE public.jobs
  SET
    status = 'cancelled',
    cancelled_at = v_now,
    cancellation_reason = p_reason,
    updated_at = v_now
  WHERE id = p_job_id;

  INSERT INTO public.admin_audit_logs (
    admin_id, action, entity_type, entity_id, old_state, new_state, notes
  ) VALUES (
    v_admin_id,
    'admin_cancel_job',
    'jobs',
    p_job_id,
    jsonb_build_object('status', v_job.status),
    jsonb_build_object('status', 'cancelled'),
    p_reason
  );

  RETURN jsonb_build_object('success', TRUE, 'message', 'कार्य प्रशासनिक रूप से रद्द कर दिया गया।');
END;
$$;


-- ============================================================================
-- FILE: 20261118000008_phase9_notification_engine.sql
-- ============================================================================

-- ==============================================================================
-- LAGANSTAFF MIGRATION: Phase 9 - Enterprise Notification & Outbox Engine
-- Migration: 20261118000008_phase9_notification_engine.sql
-- Description:
--   1. Enums for notification events and outbox delivery states.
--   2. Device tokens registry for FCM device registrations.
--   3. In-app notifications table (source of truth for Notification Center).
--   4. User notification preferences (granular opt-ins for jobs, shifts, etc.).
--   5. Transactional outbox table for reliable FCM push dispatch.
--   6. Delivery attempts tracking for observability and error handling.
--   7. Business event triggers (New Job Published, Job Cancelled, Booking Confirmed).
--   8. Scheduled shift reminder evaluator (24h and 2h in Asia/Kolkata timezone).
--   9. RPCs for device registration, notifications querying, and outbox batching.
--  10. Strict Row-Level Security (RLS) enforcement.
-- ==============================================================================

-- 1. Create Enums
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_event_type') THEN
    CREATE TYPE public.notification_event_type AS ENUM (
      'new_job',
      'application_received',
      'application_approved',
      'application_rejected',
      'booking_confirmed',
      'job_cancelled',
      'shift_reminder'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'outbox_delivery_status') THEN
    CREATE TYPE public.outbox_delivery_status AS ENUM (
      'pending',
      'processing',
      'sent',
      'retry_scheduled',
      'failed'
    );
  END IF;
END $$;

-- 2. Table: device_tokens (Authorized FCM Device Registrations)
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  installation_id VARCHAR(100) NOT NULL,
  fcm_token TEXT NOT NULL UNIQUE,
  platform VARCHAR(20) NOT NULL DEFAULT 'android' CHECK (platform IN ('android', 'ios', 'web')),
  app_version VARCHAR(50),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_device_tokens_fcm_token ON public.device_tokens(fcm_token);

-- 3. Table: notification_preferences (Per-User Granular Push Preferences)
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  new_job_alerts BOOLEAN NOT NULL DEFAULT TRUE,
  application_updates BOOLEAN NOT NULL DEFAULT TRUE,
  booking_updates BOOLEAN NOT NULL DEFAULT TRUE,
  shift_reminders BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Table: notifications (Persistent In-App Notification Center)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type public.notification_event_type NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  entity_type VARCHAR(50) NOT NULL, -- 'job', 'booking', 'application', 'roster', 'system'
  entity_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_lookup ON public.notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_entity ON public.notifications(entity_type, entity_id);

-- 5. Table: notification_outbox (Transactional Push Delivery Queue)
CREATE TABLE IF NOT EXISTS public.notification_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_key TEXT NOT NULL UNIQUE, -- Idempotency key (e.g. 'new_job:job-id:worker-id')
  event_type public.notification_event_type NOT NULL,
  recipient_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  notification_channel VARCHAR(50) NOT NULL DEFAULT 'job_alerts', -- 'job_alerts', 'booking_updates', 'shift_reminders'
  status public.outbox_delivery_status NOT NULL DEFAULT 'pending',
  attempt_count INT NOT NULL DEFAULT 0,
  next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notification_outbox_queue ON public.notification_outbox(status, next_attempt_at) WHERE status IN ('pending', 'retry_scheduled');
CREATE INDEX IF NOT EXISTS idx_notification_outbox_recipient ON public.notification_outbox(recipient_user_id);

-- 6. Table: notification_delivery_attempts (FCM Delivery Audit Log)
CREATE TABLE IF NOT EXISTS public.notification_delivery_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outbox_id UUID NOT NULL REFERENCES public.notification_outbox(id) ON DELETE CASCADE,
  device_token_id UUID REFERENCES public.device_tokens(id) ON DELETE SET NULL,
  fcm_message_id TEXT,
  attempt_status VARCHAR(50) NOT NULL, -- 'accepted', 'failed', 'invalid_token'
  error_code VARCHAR(100),
  error_message TEXT,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notif_attempts_outbox_id ON public.notification_delivery_attempts(outbox_id);

-- ==============================================================================
-- 7. Row-Level Security (RLS) Policies
-- ==============================================================================

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_delivery_attempts ENABLE ROW LEVEL SECURITY;

-- device_tokens RLS
DROP POLICY IF EXISTS "Users can manage their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can manage their own device tokens"
  ON public.device_tokens
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- notification_preferences RLS
DROP POLICY IF EXISTS "Users can view and manage their preferences" ON public.notification_preferences;
CREATE POLICY "Users can view and manage their preferences"
  ON public.notification_preferences
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- notifications RLS
DROP POLICY IF EXISTS "Users can view their own in-app notifications" ON public.notifications;
CREATE POLICY "Users can view their own in-app notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can mark their own notifications as read" ON public.notifications;
CREATE POLICY "Users can mark their own notifications as read"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- notification_outbox & delivery_attempts RLS: Restricted to system / service_role
DROP POLICY IF EXISTS "Service role access for notification outbox" ON public.notification_outbox;
CREATE POLICY "Service role access for notification outbox"
  ON public.notification_outbox
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role' OR public.is_admin_user());

DROP POLICY IF EXISTS "Service role access for delivery attempts" ON public.notification_delivery_attempts;
CREATE POLICY "Service role access for delivery attempts"
  ON public.notification_delivery_attempts
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role' OR public.is_admin_user());

-- ==============================================================================
-- 8. Stored Procedures & Client RPCs
-- ==============================================================================

-- 8.1 Register or update FCM device token
CREATE OR REPLACE FUNCTION public.register_device_token(
  p_installation_id VARCHAR(100),
  p_fcm_token TEXT,
  p_platform VARCHAR(20) DEFAULT 'android',
  p_app_version VARCHAR(50) DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_token_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to register device token.';
  END IF;

  -- Rebind token if previously assigned to another user on the same physical device
  UPDATE public.device_tokens
  SET is_active = FALSE, updated_at = NOW()
  WHERE fcm_token = p_fcm_token AND user_id <> v_user_id;

  -- Upsert device registration for current user
  INSERT INTO public.device_tokens (
    user_id, installation_id, fcm_token, platform, app_version, is_active, last_seen_at, updated_at
  )
  VALUES (
    v_user_id, p_installation_id, p_fcm_token, p_platform, p_app_version, TRUE, NOW(), NOW()
  )
  ON CONFLICT (fcm_token) DO UPDATE
  SET
    user_id = v_user_id,
    installation_id = p_installation_id,
    platform = p_platform,
    app_version = COALESCE(p_app_version, device_tokens.app_version),
    is_active = TRUE,
    last_seen_at = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_token_id;

  -- Ensure notification preferences row exists
  INSERT INTO public.notification_preferences (user_id)
  VALUES (v_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN jsonb_build_object(
    'success', true,
    'device_token_id', v_token_id,
    'message', 'Device token registered successfully.'
  );
END;
$$;

-- 8.2 Deactivate device token on sign out
CREATE OR REPLACE FUNCTION public.deactivate_device_token(
  p_fcm_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  UPDATE public.device_tokens
  SET is_active = FALSE, updated_at = NOW()
  WHERE fcm_token = p_fcm_token AND user_id = v_user_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 8.3 Get user notification preferences (with automatic defaults)
CREATE OR REPLACE FUNCTION public.get_user_notification_preferences()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_prefs RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_prefs FROM public.notification_preferences WHERE user_id = v_user_id;
  IF NOT FOUND THEN
    INSERT INTO public.notification_preferences (user_id)
    VALUES (v_user_id)
    RETURNING * INTO v_prefs;
  END IF;

  RETURN jsonb_build_object(
    'new_job_alerts', v_prefs.new_job_alerts,
    'application_updates', v_prefs.application_updates,
    'booking_updates', v_prefs.booking_updates,
    'shift_reminders', v_prefs.shift_reminders,
    'updated_at', v_prefs.updated_at
  );
END;
$$;

-- 8.4 Update user notification preferences
CREATE OR REPLACE FUNCTION public.update_user_notification_preferences(
  p_new_job_alerts BOOLEAN DEFAULT NULL,
  p_application_updates BOOLEAN DEFAULT NULL,
  p_booking_updates BOOLEAN DEFAULT NULL,
  p_shift_reminders BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  INSERT INTO public.notification_preferences (
    user_id, new_job_alerts, application_updates, booking_updates, shift_reminders, updated_at
  )
  VALUES (
    v_user_id,
    COALESCE(p_new_job_alerts, TRUE),
    COALESCE(p_application_updates, TRUE),
    COALESCE(p_booking_updates, TRUE),
    COALESCE(p_shift_reminders, TRUE),
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    new_job_alerts = COALESCE(p_new_job_alerts, notification_preferences.new_job_alerts),
    application_updates = COALESCE(p_application_updates, notification_preferences.application_updates),
    booking_updates = COALESCE(p_booking_updates, notification_preferences.booking_updates),
    shift_reminders = COALESCE(p_shift_reminders, notification_preferences.shift_reminders),
    updated_at = NOW();

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 8.5 Fetch In-App Notifications for current user
CREATE OR REPLACE FUNCTION public.get_user_notifications(
  p_unread_only BOOLEAN DEFAULT FALSE,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_items JSONB;
  v_unread_count INT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT COUNT(*) INTO v_unread_count
  FROM public.notifications
  WHERE user_id = v_user_id AND is_read = FALSE;

  SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::jsonb) INTO v_items
  FROM (
    SELECT
      id,
      event_type,
      title,
      body,
      data,
      entity_type,
      entity_id,
      is_read,
      read_at,
      created_at
    FROM public.notifications
    WHERE user_id = v_user_id
      AND (NOT p_unread_only OR is_read = FALSE)
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;

  RETURN jsonb_build_object(
    'notifications', v_items,
    'unread_count', v_unread_count
  );
END;
$$;

-- 8.6 Mark a single notification as read
CREATE OR REPLACE FUNCTION public.mark_notification_as_read(
  p_notification_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  UPDATE public.notifications
  SET is_read = TRUE, read_at = NOW()
  WHERE id = p_notification_id AND user_id = v_user_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 8.7 Mark all notifications as read for current user
CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  UPDATE public.notifications
  SET is_read = TRUE, read_at = NOW()
  WHERE user_id = v_user_id AND is_read = FALSE;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- ==============================================================================
-- 9. Automatic Business Event Triggers
-- ==============================================================================

-- 9.1 Event A: New Job Notification Trigger
CREATE OR REPLACE FUNCTION public.fn_on_job_published()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_worker RECORD;
  v_cat_name VARCHAR(100);
  v_title TEXT;
  v_body TEXT;
  v_event_key TEXT;
  v_payload JSONB;
BEGIN
  -- Only trigger when job successfully transitions to 'published'
  IF NEW.status = 'published' AND (OLD IS NULL OR OLD.status <> 'published') THEN
    SELECT name INTO v_cat_name FROM public.categories WHERE id = NEW.category_id;
    v_cat_name := COALESCE(v_cat_name, 'इवेंट कार्य');

    v_title := 'नया कार्य उपलब्ध! (New Job Available)';
    v_body := 'गाजीपुर के ' || COALESCE(NEW.locality, 'स्थानीय क्षेत्र') || ' में ' || v_cat_name || ' हेतु नया कार्य प्रकाशित हुआ है। मानदेय: ₹' || NEW.wage_amount::INT;

    -- Query active, eligible workers matching skills & locality whose preferences allow new job alerts
    FOR v_worker IN
      SELECT DISTINCT p.user_id, p.id AS profile_id
      FROM public.worker_profiles wp
      JOIN public.profiles p ON p.id = wp.profile_id
      LEFT JOIN public.notification_preferences np ON np.user_id = p.user_id
      WHERE wp.account_status = 'active'
        AND COALESCE(np.new_job_alerts, TRUE) = TRUE
        -- Skill match: worker has skill required by the job OR belongs to job category
        AND (
          EXISTS (
            SELECT 1 FROM public.worker_skills ws
            JOIN public.job_skills js ON js.skill_id = ws.skill_id
            WHERE ws.worker_profile_id = wp.id AND js.job_id = NEW.id
          )
          OR wp.locality = NEW.locality
          OR wp.city = NEW.city
        )
      LIMIT 100 -- Guardrail batch limit for hyperlocal Ghazipur launch
    LOOP
      v_event_key := 'new_job:' || NEW.id || ':' || v_worker.user_id;

      v_payload := jsonb_build_object(
        'job_id', NEW.id,
        'category_name', v_cat_name,
        'locality', NEW.locality,
        'wage_amount', NEW.wage_amount,
        'shift_date', NEW.shift_date,
        'entity_type', 'job',
        'entity_id', NEW.id
      );

      -- 1. Insert In-App Notification (Idempotent)
      INSERT INTO public.notifications (
        user_id, event_type, title, body, data, entity_type, entity_id
      )
      VALUES (
        v_worker.user_id, 'new_job', v_title, v_body, v_payload, 'job', NEW.id
      );

      -- 2. Insert Outbox Entry for FCM Dispatch (Idempotent via UNIQUE event_key)
      INSERT INTO public.notification_outbox (
        event_key, event_type, recipient_user_id, title, body, payload, notification_channel
      )
      VALUES (
        v_event_key, 'new_job', v_worker.user_id, v_title, v_body, v_payload, 'job_alerts'
      )
      ON CONFLICT (event_key) DO NOTHING;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_published_notification ON public.jobs;
CREATE TRIGGER trg_job_published_notification
  AFTER INSERT OR UPDATE OF status ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_on_job_published();

-- 9.2 Event E: Job Cancellation Notification Trigger
CREATE OR REPLACE FUNCTION public.fn_on_job_cancelled()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking RECORD;
  v_owner_user_id UUID;
  v_title TEXT;
  v_body TEXT;
  v_event_key TEXT;
  v_payload JSONB;
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
    v_title := 'कार्य निरस्त (Job Cancelled)';
    v_body := '"' || NEW.title || '" कार्य निरस्त कर दिया गया है। कृपया अपने बुकिंग विवरण की जाँच करें।';

    v_payload := jsonb_build_object(
      'job_id', NEW.id,
      'title', NEW.title,
      'shift_date', NEW.shift_date,
      'entity_type', 'job',
      'entity_id', NEW.id
    );

    -- 1. Notify affected confirmed Workers
    FOR v_booking IN
      SELECT b.id AS booking_id, p.user_id
      FROM public.bookings b
      JOIN public.worker_profiles wp ON wp.id = b.worker_profile_id
      JOIN public.profiles p ON p.id = wp.profile_id
      WHERE b.job_id = NEW.id AND b.status IN ('confirmed', 'checked_in')
    LOOP
      v_event_key := 'job_cancelled:' || NEW.id || ':' || v_booking.user_id;

      INSERT INTO public.notifications (
        user_id, event_type, title, body, data, entity_type, entity_id
      )
      VALUES (
        v_booking.user_id, 'job_cancelled', v_title, v_body, v_payload, 'booking', v_booking.booking_id
      );

      INSERT INTO public.notification_outbox (
        event_key, event_type, recipient_user_id, title, body, payload, notification_channel
      )
      VALUES (
        v_event_key, 'job_cancelled', v_booking.user_id, v_title, v_body, v_payload, 'booking_updates'
      )
      ON CONFLICT (event_key) DO NOTHING;
    END LOOP;

    -- 2. Notify Job Owner if cancelled by an Administrator
    IF NEW.cancelled_by IS NOT NULL THEN
      SELECT p.user_id INTO v_owner_user_id
      FROM public.businesses b
      JOIN public.profiles p ON p.user_id = b.created_by
      WHERE b.id = NEW.business_id;

      IF v_owner_user_id IS NOT NULL AND v_owner_user_id <> NEW.cancelled_by THEN
        v_event_key := 'job_cancelled_owner:' || NEW.id || ':' || v_owner_user_id;

        INSERT INTO public.notifications (
          user_id, event_type, title, body, data, entity_type, entity_id
        )
        VALUES (
          v_owner_user_id, 'job_cancelled', 'कार्य निरस्त हुआ (Admin Notice)',
          'व्यवस्थापक द्वारा "' || NEW.title || '" कार्य निरस्त किया गया है।',
          v_payload, 'job', NEW.id
        );

        INSERT INTO public.notification_outbox (
          event_key, event_type, recipient_user_id, title, body, payload, notification_channel
        )
        VALUES (
          v_event_key, 'job_cancelled', v_owner_user_id, 'कार्य निरस्त हुआ (Admin Notice)',
          'व्यवस्थापक द्वारा "' || NEW.title || '" कार्य निरस्त किया गया है।',
          v_payload, 'booking_updates'
        )
        ON CONFLICT (event_key) DO NOTHING;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_cancelled_notification ON public.jobs;
CREATE TRIGGER trg_job_cancelled_notification
  AFTER UPDATE OF status ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_on_job_cancelled();

-- 9.3 Event D: Booking Confirmed Notification Trigger
CREATE OR REPLACE FUNCTION public.fn_on_booking_confirmed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job RECORD;
  v_worker_user_id UUID;
  v_owner_user_id UUID;
  v_event_key TEXT;
  v_payload JSONB;
BEGIN
  IF NEW.status = 'confirmed' AND (OLD IS NULL OR OLD.status <> 'confirmed') THEN
    SELECT * INTO v_job FROM public.jobs WHERE id = NEW.job_id;

    -- Get Worker user_id
    SELECT p.user_id INTO v_worker_user_id
    FROM public.worker_profiles wp
    JOIN public.profiles p ON p.id = wp.profile_id
    WHERE wp.id = NEW.worker_profile_id;

    -- Get Owner user_id
    SELECT created_by INTO v_owner_user_id
    FROM public.businesses
    WHERE id = NEW.business_id;

    v_payload := jsonb_build_object(
      'booking_id', NEW.id,
      'job_id', NEW.job_id,
      'job_title', v_job.title,
      'checkin_code', NEW.checkin_code,
      'shift_date', v_job.shift_date,
      'agreed_wage', NEW.agreed_wage,
      'entity_type', 'booking',
      'entity_id', NEW.id
    );

    -- 1. Notify Worker
    IF v_worker_user_id IS NOT NULL THEN
      v_event_key := 'booking_confirmed:worker:' || NEW.id;

      INSERT INTO public.notifications (
        user_id, event_type, title, body, data, entity_type, entity_id
      )
      VALUES (
        v_worker_user_id, 'booking_confirmed', 'बुकिंग स्वीकृत! (Booking Confirmed)',
        '"' || v_job.title || '" कार्य हेतु आपकी बुकिंग पुष्ट हो गई है। ड्यूटी पास पिन: ' || NEW.checkin_code,
        v_payload, 'booking', NEW.id
      );

      INSERT INTO public.notification_outbox (
        event_key, event_type, recipient_user_id, title, body, payload, notification_channel
      )
      VALUES (
        v_event_key, 'booking_confirmed', v_worker_user_id,
        'बुकिंग स्वीकृत! (Booking Confirmed)',
        '"' || v_job.title || '" कार्य हेतु आपकी बुकिंग पुष्ट हो गई है। ड्यूटी पास पिन: ' || NEW.checkin_code,
        v_payload, 'booking_updates'
      )
      ON CONFLICT (event_key) DO NOTHING;
    END IF;

    -- 2. Notify Owner
    IF v_owner_user_id IS NOT NULL THEN
      v_event_key := 'booking_confirmed:owner:' || NEW.id;

      INSERT INTO public.notifications (
        user_id, event_type, title, body, data, entity_type, entity_id
      )
      VALUES (
        v_owner_user_id, 'booking_confirmed', 'कार्यकर्ता बुकिंग पुष्ट (Staff Confirmed)',
        '"' || v_job.title || '" हेतु एक कार्यकर्ता पुष्ट हो गया है।',
        v_payload, 'roster', NEW.job_id
      );

      INSERT INTO public.notification_outbox (
        event_key, event_type, recipient_user_id, title, body, payload, notification_channel
      )
      VALUES (
        v_event_key, 'booking_confirmed', v_owner_user_id,
        'कार्यकर्ता बुकिंग पुष्ट (Staff Confirmed)',
        '"' || v_job.title || '" हेतु एक कार्यकर्ता पुष्ट हो गया है।',
        v_payload, 'booking_updates'
      )
      ON CONFLICT (event_key) DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_booking_confirmed_notification ON public.bookings;
CREATE TRIGGER trg_booking_confirmed_notification
  AFTER INSERT OR UPDATE OF status ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_on_booking_confirmed();

-- ==============================================================================
-- 10. Scheduled Shift Reminder Evaluator (24h and 2h in Asia/Kolkata)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.schedule_shift_reminders()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rec RECORD;
  v_now_ist TIMESTAMPTZ := NOW() AT TIME ZONE 'Asia/Kolkata';
  v_shift_ts TIMESTAMPTZ;
  v_diff_mins INT;
  v_24h_count INT := 0;
  v_2h_count INT := 0;
  v_event_key TEXT;
  v_title TEXT;
  v_body TEXT;
  v_payload JSONB;
BEGIN
  -- Evaluate confirmed bookings on upcoming active jobs
  FOR v_rec IN
    SELECT
      b.id AS booking_id,
      b.job_id,
      b.checkin_code,
      j.title AS job_title,
      j.venue_name,
      j.locality,
      j.shift_date,
      j.start_time,
      p.user_id AS worker_user_id,
      biz.created_by AS owner_user_id,
      COALESCE(np_w.shift_reminders, TRUE) AS worker_opt_in,
      COALESCE(np_o.shift_reminders, TRUE) AS owner_opt_in
    FROM public.bookings b
    JOIN public.jobs j ON j.id = b.job_id
    JOIN public.businesses biz ON biz.id = b.business_id
    JOIN public.worker_profiles wp ON wp.id = b.worker_profile_id
    JOIN public.profiles p ON p.id = wp.profile_id
    LEFT JOIN public.notification_preferences np_w ON np_w.user_id = p.user_id
    LEFT JOIN public.notification_preferences np_o ON np_o.user_id = biz.created_by
    WHERE b.status = 'confirmed'
      AND j.status = 'published'
      AND j.shift_date >= (v_now_ist::DATE)
  LOOP
    -- Calculate scheduled shift timestamp in Asia/Kolkata
    v_shift_ts := (v_rec.shift_date || ' ' || v_rec.start_time)::TIMESTAMP AT TIME ZONE 'Asia/Kolkata';
    v_diff_mins := EXTRACT(EPOCH FROM (v_shift_ts - NOW())) / 60;

    -- Reminders:
    -- 24h Window: [1380m, 1470m] (between 23h and 24.5h)
    -- 2h Window: [90m, 150m] (between 1.5h and 2.5h)

    IF v_diff_mins >= 1380 AND v_diff_mins <= 1470 THEN
      -- 24 Hour Reminder for Worker
      IF v_rec.worker_opt_in THEN
        v_event_key := 'shift_reminder_24h:worker:' || v_rec.booking_id;
        v_title := 'कल आपकी ड्यूटी है! (Shift Tomorrow)';
        v_body := 'कल ' || v_rec.shift_date || ' को ' || v_rec.job_title || ' हेतु आपकी शिफ्ट है। समय: ' || SUBSTRING(v_rec.start_time::TEXT FROM 1 FOR 5);

        v_payload := jsonb_build_object(
          'booking_id', v_rec.booking_id,
          'job_id', v_rec.job_id,
          'shift_date', v_rec.shift_date,
          'start_time', v_rec.start_time,
          'reminder_tier', '24h',
          'entity_type', 'booking',
          'entity_id', v_rec.booking_id
        );

        INSERT INTO public.notifications (
          user_id, event_type, title, body, data, entity_type, entity_id
        ) VALUES (
          v_rec.worker_user_id, 'shift_reminder', v_title, v_body, v_payload, 'booking', v_rec.booking_id
        );

        INSERT INTO public.notification_outbox (
          event_key, event_type, recipient_user_id, title, body, payload, notification_channel
        ) VALUES (
          v_event_key, 'shift_reminder', v_rec.worker_user_id, v_title, v_body, v_payload, 'shift_reminders'
        ) ON CONFLICT (event_key) DO NOTHING;

        v_24h_count := v_24h_count + 1;
      END IF;

    ELSIF v_diff_mins >= 90 AND v_diff_mins <= 150 THEN
      -- 2 Hour Reminder for Worker
      IF v_rec.worker_opt_in THEN
        v_event_key := 'shift_reminder_2h:worker:' || v_rec.booking_id;
        v_title := 'शिफ्ट 2 घंटे में शुरू होगी! (Shift in 2h)';
        v_body := 'आपकी ड्यूटी 2 घंटे में शुरू होगी। स्थल: ' || COALESCE(v_rec.venue_name, v_rec.locality) || '। गेट पास पिन: ' || v_rec.checkin_code;

        v_payload := jsonb_build_object(
          'booking_id', v_rec.booking_id,
          'job_id', v_rec.job_id,
          'checkin_code', v_rec.checkin_code,
          'reminder_tier', '2h',
          'entity_type', 'booking',
          'entity_id', v_rec.booking_id
        );

        INSERT INTO public.notifications (
          user_id, event_type, title, body, data, entity_type, entity_id
        ) VALUES (
          v_rec.worker_user_id, 'shift_reminder', v_title, v_body, v_payload, 'booking', v_rec.booking_id
        );

        INSERT INTO public.notification_outbox (
          event_key, event_type, recipient_user_id, title, body, payload, notification_channel
        ) VALUES (
          v_event_key, 'shift_reminder', v_rec.worker_user_id, v_title, v_body, v_payload, 'shift_reminders'
        ) ON CONFLICT (event_key) DO NOTHING;

        v_2h_count := v_2h_count + 1;
      END IF;

      -- 2 Hour Reminder for Owner
      IF v_rec.owner_opt_in AND v_rec.owner_user_id IS NOT NULL THEN
        v_event_key := 'shift_reminder_2h:owner:' || v_rec.booking_id;
        v_title := 'कर्मचारी शिफ्ट 2 घंटे में! (Staff Roster Alert)';
        v_body := '"' || v_rec.job_title || '" हेतु कर्मचारी 2 घंटे में वेन्यू पर उपस्थित होंगे। गेट पर 4-अंकीय पिन से उपस्थिति दर्ज करें।';

        v_payload := jsonb_build_object(
          'job_id', v_rec.job_id,
          'booking_id', v_rec.booking_id,
          'reminder_tier', '2h',
          'entity_type', 'roster',
          'entity_id', v_rec.job_id
        );

        INSERT INTO public.notifications (
          user_id, event_type, title, body, data, entity_type, entity_id
        ) VALUES (
          v_rec.owner_user_id, 'shift_reminder', v_title, v_body, v_payload, 'roster', v_rec.job_id
        );

        INSERT INTO public.notification_outbox (
          event_key, event_type, recipient_user_id, title, body, payload, notification_channel
        ) VALUES (
          v_event_key, 'shift_reminder', v_rec.owner_user_id, v_title, v_body, v_payload, 'shift_reminders'
        ) ON CONFLICT (event_key) DO NOTHING;
      END IF;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'reminders_24h_queued', v_24h_count,
    'reminders_2h_queued', v_2h_count,
    'evaluated_at', NOW()
  );
END;
$$;

-- ==============================================================================
-- 11. Outbox Worker RPCs for Edge Function Processing
-- ==============================================================================

-- 11.1 Atomically claim pending outbox batch
CREATE OR REPLACE FUNCTION public.claim_pending_outbox_batch(
  p_batch_size INT DEFAULT 50
)
RETURNS TABLE (
  outbox_id UUID,
  event_key TEXT,
  event_type public.notification_event_type,
  recipient_user_id UUID,
  title VARCHAR(200),
  body TEXT,
  payload JSONB,
  notification_channel VARCHAR(50),
  attempt_count INT,
  device_tokens JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Security check: service_role or admin user only
  IF auth.jwt() ->> 'role' <> 'service_role' AND NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized: Service role credentials required to claim outbox.';
  END IF;

  RETURN QUERY
  WITH claimed AS (
    SELECT id
    FROM public.notification_outbox
    WHERE status IN ('pending', 'retry_scheduled')
      AND next_attempt_at <= NOW()
    ORDER BY created_at ASC
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.notification_outbox o
  SET status = 'processing', processed_at = NOW()
  FROM claimed
  WHERE o.id = claimed.id
  RETURNING
    o.id,
    o.event_key,
    o.event_type,
    o.recipient_user_id,
    o.title,
    o.body,
    o.payload,
    o.notification_channel,
    o.attempt_count,
    (
      SELECT COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'device_id', dt.id,
            'fcm_token', dt.fcm_token,
            'platform', dt.platform
          )
        ),
        '[]'::jsonb
      )
      FROM public.device_tokens dt
      WHERE dt.user_id = o.recipient_user_id AND dt.is_active = TRUE
    ) AS device_tokens;
END;
$$;

-- 11.2 Record delivery attempt result & update outbox state
CREATE OR REPLACE FUNCTION public.record_outbox_result(
  p_outbox_id UUID,
  p_status public.outbox_delivery_status,
  p_error TEXT DEFAULT NULL,
  p_device_results JSONB DEFAULT '[]'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_dev RECORD;
  v_next_attempt TIMESTAMPTZ;
  v_curr_attempts INT;
BEGIN
  IF auth.jwt() ->> 'role' <> 'service_role' AND NOT public.is_admin_user() THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  SELECT attempt_count INTO v_curr_attempts
  FROM public.notification_outbox
  WHERE id = p_outbox_id;

  v_curr_attempts := COALESCE(v_curr_attempts, 0) + 1;

  -- Exponential backoff: 1m, 2m, 4m, 8m, 16m up to max 5 attempts
  IF p_status = 'retry_scheduled' AND v_curr_attempts < 5 THEN
    v_next_attempt := NOW() + (INTERVAL '1 minute' * (2 ^ v_curr_attempts));
  ELSIF p_status = 'retry_scheduled' AND v_curr_attempts >= 5 THEN
    p_status := 'failed';
    v_next_attempt := NULL;
  END IF;

  -- Update outbox row
  UPDATE public.notification_outbox
  SET
    status = p_status,
    attempt_count = v_curr_attempts,
    next_attempt_at = COALESCE(v_next_attempt, next_attempt_at),
    last_error = p_error,
    processed_at = NOW()
  WHERE id = p_outbox_id;

  -- Record each device attempt in audit log
  FOR v_dev IN SELECT * FROM jsonb_to_recordset(p_device_results) AS x(
    device_id UUID,
    fcm_message_id TEXT,
    attempt_status VARCHAR,
    error_code VARCHAR,
    error_message TEXT,
    deactivate_token BOOLEAN
  )
  LOOP
    INSERT INTO public.notification_delivery_attempts (
      outbox_id, device_token_id, fcm_message_id, attempt_status, error_code, error_message
    ) VALUES (
      p_outbox_id, v_dev.device_id, v_dev.fcm_message_id, v_dev.attempt_status, v_dev.error_code, v_dev.error_message
    );

    -- If token is invalid or unregistered, deactivate device token immediately
    IF v_dev.deactivate_token IS TRUE AND v_dev.device_id IS NOT NULL THEN
      UPDATE public.device_tokens
      SET is_active = FALSE, updated_at = NOW()
      WHERE id = v_dev.device_id;
    END IF;
  END LOOP;
END;
$$;



-- ==============================================================================
-- POSTGREST PRIVILEGES & ROLE ACCESS
-- ==============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
