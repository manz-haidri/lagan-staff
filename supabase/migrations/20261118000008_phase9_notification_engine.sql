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
