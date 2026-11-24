DO $patch$
DECLARE
  fn regprocedure := 'public.complete_worker_onboarding(text,text,text,numeric,numeric,text,uuid[],text)'::regprocedure;
  src text := pg_get_functiondef(fn);
  needle text := 'WHEN public.worker_profiles.status = ''suspended'' THEN ''suspended''';
  corrected text := 'WHEN public.worker_profiles.status = ''suspended'' THEN public.worker_profiles.status';
BEGIN
  IF strpos(src, corrected) > 0 THEN RETURN; END IF;
  IF strpos(src, needle) = 0 THEN RAISE EXCEPTION 'Unexpected onboarding definition'; END IF;
  EXECUTE replace(src, needle, corrected);
END;
$patch$;
SELECT pg_typeof(CASE WHEN status = 'suspended' THEN status ELSE 'active' END)::text AS resolved_type
FROM (VALUES ('active'::public.worker_status)) AS sample(status);
