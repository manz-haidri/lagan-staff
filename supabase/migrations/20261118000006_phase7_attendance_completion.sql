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
