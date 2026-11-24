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
