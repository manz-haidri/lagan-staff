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
