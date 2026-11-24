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
