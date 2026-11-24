# LaganStaff — Role-Permission Matrix

**Document Version:** 1.0.0  
**Status:** Approved for Phase 0 Planning  
**Scope:** Comprehensive RBAC (Role-Based Access Control) Policy Map  

---

## 1. Overview of System Roles

1. **Anonymous (`anon`):** Unauthenticated visitor. Can request SMS OTP, verify OTP, and view system health.
2. **Worker (`worker`):** Authenticated gig worker seeking shifts in Ghazipur.
3. **Owner (`owner`):** Authenticated business representative (marriage hall, catering, tent house) posting shifts.
4. **Admin (`admin`):** Authorized internal operations staff with governance and moderation authority.

---

## 2. Resource Permission Matrix

| Resource / Entity | Action | Anonymous | Worker | Owner | Admin | Enforcement Mechanism |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Authentication** | Request Mobile OTP | ✅ | ✅ | ✅ | ❌ | Supabase Auth API Rate-Limited |
| | Verify Mobile OTP | ✅ | ✅ | ✅ | ❌ | Supabase Auth OTP Verification |
| **User Role Assignment** | Select Initial Role (Worker/Owner) | ❌ | ✅ (Once) | ✅ (Once) | ❌ | RPC `initialize_user_role` |
| | Grant Admin Role | ❌ | ❌ | ❌ | ✅ (CLI/Seed) | Database Service Role Only |
| **Profiles** | Read Own Profile | ❌ | ✅ | ✅ | ✅ | Postgres RLS (`auth.uid() = id`) |
| | Read Other Worker Profile | ❌ | ❌ | ✅ (Applicants only)| ✅ | Scoped Postgres RLS View |
| | Update Own Profile | ❌ | ✅ | ✅ | ✅ | Postgres RLS (`auth.uid() = id`) |
| **Worker Profiles** | Create / Update Own Profile | ❌ | ✅ | ❌ | ✅ | Postgres RLS |
| | View Own Private Details | ❌ | ✅ | ❌ | ✅ | Postgres RLS |
| **Selfie Uploads** | Upload to `worker-selfies` | ❌ | ✅ (Own folder) | ❌ | ❌ | Storage RLS Folder Check |
| | Read Raw Selfie File | ❌ | ✅ (Own file) | ❌ | ✅ | Storage RLS / Short-lived Signed URL |
| **Businesses** | Create Business Profile | ❌ | ❌ | ✅ | ✅ | Postgres RLS |
| | Update Own Business Profile | ❌ | ❌ | ✅ (Own) | ✅ | Postgres RLS (`business_members`) |
| | Modify `is_first_job_approved`| ❌ | ❌ | ❌ | ✅ | Column Trigger + Admin RPC |
| **Job Postings** | View Published Jobs | ❌ | ✅ | ✅ | ✅ | Postgres RLS (`status = 'published'`) |
| | View Pending/Rejected Jobs | ❌ | ❌ | ✅ (Own only) | ✅ (All) | Postgres RLS |
| | Create New Job | ❌ | ❌ | ✅ | ✅ | Postgres RLS + Transaction RPC |
| | Update Draft / Rejected Job | ❌ | ❌ | ✅ (Own only) | ✅ | Postgres RLS |
| | Approve First Job | ❌ | ❌ | ❌ | ✅ | RPC `approve_first_job` |
| | Reject First Job | ❌ | ❌ | ❌ | ✅ | RPC `reject_first_job` |
| **Job Applications** | Submit Application | ❌ | ✅ (Active only)| ❌ | ❌ | Postgres RLS + Unique Constraint |
| | View Own Applications | ❌ | ✅ | ❌ | ✅ | Postgres RLS |
| | View Applicants for Job | ❌ | ❌ | ✅ (Own jobs) | ✅ | Postgres RLS |
| | Accept / Reject Applicant | ❌ | ❌ | ✅ (Own jobs) | ✅ | Atomic Capacity RPC `accept_applicant` |
| | Withdraw Application | ❌ | ✅ (Own applied)| ❌ | ❌ | Postgres RLS |
| **Bookings** | Create Confirmed Booking | ❌ | ❌ | ❌ | ❌ | System Only via `accept_applicant` RPC |
| | View Own Bookings | ❌ | ✅ (Own) | ✅ (Own business)| ✅ (All) | Postgres RLS |
| | Cancel Booking | ❌ | ❌ | ✅ (With reason)| ✅ | RPC `cancel_booking` |
| **Attendance Records** | Mark Check-In / Check-Out | ❌ | ❌ | ✅ (Own shift) | ✅ | Postgres RLS (`marked_by = auth.uid()`) |
| | View Shift Attendance | ❌ | ✅ (Own) | ✅ (Own shift) | ✅ (All) | Postgres RLS |
| **Categories & Skills** | Read Categories / Skills | ✅ | ✅ | ✅ | ✅ | Public Read RLS Policy |
| | Create / Edit / Delete Skills | ❌ | ❌ | ❌ | ✅ | Admin-Only RLS Policy |
| **Admin Audit Logs** | Append Audit Log | ❌ | ❌ | ❌ | ✅ (System/Admin)| Security Definer Trigger / RPC |
| | View Audit Trail | ❌ | ❌ | ❌ | ✅ | Admin-Only RLS Policy |
| | Update or Delete Audit Logs | ❌ | ❌ | ❌ | ❌ | **IMPOSSIBLE (Append-Only RLS)** |

---

## 3. UI Navigation & Route Guards

| Application | Route Path | Permitted Roles | Unauthorized Action Response |
| :--- | :--- | :--- | :--- |
| **Flutter Mobile** | `/login` | Anonymous | Redirect to `/role-selection` or Dashboard if authenticated |
| | `/onboarding/worker` | Authenticated Worker | Redirect to `/worker/dashboard` if already active |
| | `/onboarding/owner` | Authenticated Owner | Redirect to `/owner/dashboard` if already setup |
| | `/worker/**` | Authenticated Worker (Active) | Redirect to `/onboarding/worker` if profile incomplete |
| | `/owner/**` | Authenticated Owner | Redirect to `/onboarding/owner` if business incomplete |
| **Admin Web** | `/login` | Public Admin URL | Redirect to `/dashboard` if authenticated admin session |
| | `/dashboard/**` | Authenticated Admin Only | Reject with HTTP 403 Forbidden & redirect to `/login` |
| | `/job-approvals/**` | Authenticated Admin Only | Reject with HTTP 403 Forbidden |
| | `/audit-logs/**` | Authenticated Admin Only | Reject with HTTP 403 Forbidden |
