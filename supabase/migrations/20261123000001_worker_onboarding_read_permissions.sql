BEGIN;
-- Storage checks these columns when evaluating the worker selfie policy.
GRANT SELECT (user_id, role) ON public.user_roles TO authenticated;
-- Onboarding needs the active catalog IDs for the final profile submission.
GRANT SELECT (id, name, slug, description, is_active) ON public.categories TO authenticated;
GRANT SELECT (id, category_id, name, is_active) ON public.skills TO authenticated;
COMMIT;
