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
