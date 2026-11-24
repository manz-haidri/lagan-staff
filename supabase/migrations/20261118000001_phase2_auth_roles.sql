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
