# Phase 8 Audit: Existing Admin Dashboard & Platform Control Center

**Project:** LaganStaff  
**Initial Market:** Ghazipur, Uttar Pradesh, India  
**Scope:** Phase 8 — Comprehensive Audit of Existing Admin Capabilities, Structural Gaps, Security Boundaries, and Integration Requirements.

---

## 1. Executive Summary

This audit assesses the current state of the Next.js Admin portal (`apps/admin`), database schemas, RPC functions, and administrative capabilities established across Phases 1 through 7.

While earlier phases introduced functional prototypes for Business Verification (Phase 4) and First-Job Moderation (Phase 5), the administrative dashboard remains fragmented across root-level mockup screens without centralized role authorization, comprehensive worker lifecycle moderation, dedicated category management, complaint triage, or real-time analytics.

---

## 2. Existing Working Functionality

1. **Business Verification Queue & Detail View:**
   - [business-service.ts](file:///Users/samarborairabbas/Documents/Apps/Lagan%20Staff/apps/admin/src/lib/business-service.ts) connects to PostgreSQL `businesses` and `business_verification_documents` tables.
   - Admin can view pending verification submissions, inspect visiting cards/trade licenses, and execute `admin_review_business` RPC (`approve`, `reject`, `mark_under_review`, `suspend`, `reactivate`).
   - Private document signed URL generator (`business-documents` Supabase Storage bucket).
2. **First-Job Approval Queue & Moderation:**
   - [job-service.ts](file:///Users/samarborairabbas/Documents/Apps/Lagan%20Staff/apps/admin/src/lib/job-service.ts) queries `jobs` with `status = 'pending_admin_approval'` and `is_first_job = true`.
   - Admin can approve first jobs via `admin_approve_first_job` RPC, which sets `is_first_job_approved = true` on the business, immediately publishing the job and enabling auto-publish for subsequent posts.
   - Admin can reject first jobs with mandatory rejection reasons via `admin_reject_first_job` RPC.
3. **Core Admin Shell & Navigation:**
   - [AdminShell.tsx](file:///Users/samarborairabbas/Documents/Apps/Lagan%20Staff/apps/admin/src/components/layout/AdminShell.tsx), [Sidebar.tsx](file:///Users/samarborairabbas/Documents/Apps/Lagan%20Staff/apps/admin/src/components/layout/Sidebar.tsx), and [TopNav.tsx](file:///Users/samarborairabbas/Documents/Apps/Lagan%20Staff/apps/admin/src/components/layout/TopNav.tsx) provide a responsive dashboard layout with Ghazipur operational branding.

---

## 3. Missing Functionality

1. **Dedicated `/admin/*` Route Architecture:**
   - All existing pages reside at the root path (`/dashboard`, `/workers`, `/jobs`, etc.) rather than the requested canonical `/admin/*` prefix.
   - Missing sub-routes:
     - `/admin/worker-verification` (Dedicated queue for post-onboarding worker review)
     - `/admin/workers/[id]` (Worker profile inspection, selfie review, and booking history)
     - `/admin/owners/[id]` (Owner profile and associated business portfolio)
     - `/admin/jobs/[id]` (Master job detail inspection and cancellation override)
     - `/admin/bookings/[id]` (Booking lifecycle and attendance inspection)
     - `/admin/categories` (Taxonomy and skills management)
     - `/admin/complaints` and `/admin/complaints/[id]` (Complaint intake and resolution)
     - `/admin/no-shows` (Centralized no-show monitor)
     - `/admin/analytics` (Aggregated platform statistics)
2. **Worker Review & Suspension Workflow:**
   - Post-registration review status (`not_reviewed`, `reviewed`, `needs_attention`) is not tracked.
   - No short-lived signed URL generation for worker selfies in private storage (`worker-selfies`).
   - No administrative suspension/reactivation actions for problematic workers.
3. **Complaint Management System:**
   - No `complaints` table or complaint triage pipeline exists in the database.
   - No user-facing reporting workflow exists in mobile modules.
4. **Category & Taxonomy Management:**
   - No interface exists to add, edit, or deactivate categories without raw SQL access.
5. **Real Database Metrics & Analytics Engine:**
   - `dashboard/page.tsx` currently displays hardcoded mock numbers (e.g., "342 registered workers", "14 active shifts") rather than querying database counts.

---

## 4. Broken or Incomplete Behaviors

1. **Workers Page (`/workers`):** Hardcoded sample array (`mockWorkers`) instead of live data from `worker_profiles` and `profiles`.
2. **Owners Page (`/owners`):** Hardcoded sample array without linked business queries.
3. **Bookings Page (`/bookings`):** Hardcoded sample array referencing static check-in codes instead of querying the `bookings` and `attendance_records` tables created in Phase 7.
4. **Settings Page (`/settings`):** Incomplete placeholder UI without actual platform configurations or admin session management.

---

## 5. Security Gaps & Vulnerabilities

1. **Client-Side Admin Bypass Risk:**
   - Admin authentication currently relies on browser-stored sessions without a server-side guard verifying whether `auth.uid()` has an active `admin` role in `user_roles` or an allowlisted `admin_users` table.
2. **Lack of Server Action Authorization:**
   - In Next.js client components, direct PostgREST calls could be intercepted if RLS policies only check authenticated users rather than specifically `role = 'admin'`.
3. **Missing Audit Logs for Category & User Modifications:**
   - While business and job approvals write to `admin_audit_logs`, there are no audit records for worker suspensions, category deactivations, or complaint closures.

---

## 6. Required Database Changes

1. **Table: `admin_users`**
   - Stores allowlisted administrative identities, assigned roles, super-admin flags, and last login timestamps.
2. **Table: `complaints` & `complaint_notes`**
   - Tracks user-reported disputes (`submitted_by`, `reported_user_id`, `job_id`, `category`, `description`, `evidence_path`, `complaint_status`, `admin_notes`, `resolved_at`).
3. **Worker Profile Extension:**
   - Add `review_status public.worker_review_status DEFAULT 'not_reviewed'` to `worker_profiles`.
4. **Category Table Enhancements:**
   - Add `display_order INT DEFAULT 0` and `updated_at TIMESTAMPTZ DEFAULT NOW()` to `categories`.
5. **Secure Administrative RPCs:**
   - `admin_suspend_worker(p_worker_id, p_reason)`
   - `admin_reactivate_worker(p_worker_id)`
   - `admin_review_worker(p_worker_id, p_review_status, p_notes)`
   - `admin_resolve_complaint(p_complaint_id, p_resolution_status, p_admin_notes)`
   - `admin_upsert_category(p_id, p_name, p_slug, p_description, p_is_active, p_display_order)`
   - `get_admin_dashboard_metrics()` (Aggregated counts for users, jobs, bookings, complaints, and no-shows).
