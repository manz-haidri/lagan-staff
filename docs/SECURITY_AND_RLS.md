# LaganStaff — Security Architecture & Row Level Security (RLS)

**Document Version:** 1.0.0  
**Status:** Approved for Phase 0 Planning  
**Target Infrastructure:** Supabase PostgreSQL + Storage Security Engine  

---

## 1. Security Philosophy & Threat Model

LaganStaff operates under a **Zero-Trust Client Model**:
1. **Never Trust the Mobile Client:** The Flutter application runs on untrusted user devices. Client-side checks, validations, and role selections are treated strictly as UX conveniences.
2. **Database as the Ultimate Security Boundary:** All authorization rules, data tenancy boundaries, and privacy protections are enforced directly in PostgreSQL via **Row Level Security (RLS)** and atomic **Stored Functions (RPCs)**.
3. **Zero Secrets in Mobile Binaries:** The Flutter binary contains only the public `SUPABASE_ANON_KEY`. The privileged `SUPABASE_SERVICE_ROLE_KEY` is completely absent from mobile code and only resides on protected Vercel server environments for the Admin Dashboard.
4. **Selfie Privacy by Design:** Worker selfies are sensitive personal data. They are stored in an encrypted, non-public bucket with zero public URL access.

---

## 2. Row Level Security (RLS) Architecture by Table

Every table in the public schema has RLS enabled: `ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;`. By default, all operations are denied unless an explicit policy evaluates to `TRUE`.

### 2.1 Table: `profiles`
- **SELECT:**
  - Owner can view their own profile: `auth.uid() = id`.
  - Business owners can view basic public profile info (name, avatar) of workers who applied to their jobs.
  - Admins can view all profiles.
- **INSERT:**
  - Only authenticated user for their own UID: `auth.uid() = id`.
- **UPDATE:**
  - User can update their own profile: `auth.uid() = id`.
- **DELETE:** Denied for all users (soft deletion managed via status flag).

### 2.2 Table: `user_roles`
- **SELECT:**
  - Authenticated user can read their own role: `auth.uid() = user_id`.
  - Admins can read all roles.
- **INSERT:**
  - Allowed only during initial registration RPC (`initialize_user_role`) for `'worker'` or `'owner'`.
  - Direct INSERT of role `'admin'` is strictly blocked via CHECK constraint and RPC validation.
- **UPDATE / DELETE:** Denied for all standard users. Modifiable only by super-admins.

### 2.3 Table: `worker_profiles`
- **SELECT:**
  - Worker can view own profile: `auth.uid() = user_id`.
  - Admins can view all worker profiles.
  - Business owners can view non-sensitive worker profile info (experience, locality, skills) for applicants to their active jobs. **Selfie storage path is excluded from public views.**
- **INSERT / UPDATE:**
  - Worker can create/update only their own record: `auth.uid() = user_id`.
- **DELETE:** Denied.

### 2.4 Table: `businesses`
- **SELECT:**
  - Authenticated workers and owners can view active businesses: `status = 'active'`.
  - Admins can view all businesses.
- **INSERT:**
  - Authenticated owner can create a business record: `auth.uid() = created_by`.
- **UPDATE:**
  - Business members with `'owner'` role can update business details:
    `EXISTS (SELECT 1 FROM business_members WHERE business_id = id AND user_id = auth.uid())`.
  - `is_first_job_approved` is protected by a column-level trigger and cannot be updated directly by owners.
- **DELETE:** Denied.

### 2.5 Table: `jobs`
- **SELECT:**
  - Workers can view jobs with status `'published'`: `status = 'published'`.
  - Business owners can view all jobs belonging to their own businesses.
  - Admins can view all jobs across all statuses.
- **INSERT:**
  - Business members can create jobs for their own business.
  - Initial status is governed by stored procedure: automatically sets `'pending_admin_approval'` if `is_first_job_approved = FALSE`, or `'published'` if `TRUE`.
- **UPDATE:**
  - Owners can update their own jobs only when in `'draft'` or `'rejected'` status.
  - Admins can update status (approve, reject, cancel).
- **DELETE:** Denied.

### 2.6 Table: `job_applications`
- **SELECT:**
  - Worker can view their own applications:
    `worker_profile_id = (SELECT id FROM worker_profiles WHERE user_id = auth.uid())`.
  - Business owner can view applications submitted to jobs belonging to their business:
    `EXISTS (SELECT 1 FROM jobs j JOIN business_members bm ON bm.business_id = j.business_id WHERE j.id = job_applications.job_id AND bm.user_id = auth.uid())`.
  - Admins can view all applications.
- **INSERT:**
  - Worker can insert application only for active worker profiles and published jobs.
- **UPDATE:**
  - Worker can withdraw (`status = 'withdrawn'`) before acceptance.
  - Business owner can accept or reject (`status IN ('accepted', 'rejected')`) via transactional RPC.
- **DELETE:** Denied.

### 2.7 Table: `bookings`
- **SELECT:**
  - Worker can view own bookings: `worker_profile_id = (SELECT id FROM worker_profiles WHERE user_id = auth.uid())`.
  - Business owners can view bookings for their business:
    `EXISTS (SELECT 1 FROM business_members WHERE business_id = bookings.business_id AND user_id = auth.uid())`.
  - Admins can view all bookings.
- **INSERT / UPDATE:**
  - Executed exclusively via atomic database functions (`confirm_booking`, `cancel_booking`). Direct client INSERT is disabled.
- **DELETE:** Denied.

### 2.8 Table: `admin_audit_logs`
- **SELECT:**
  - Only authenticated Admins can view audit logs.
- **INSERT:**
  - Only Admins or database triggers/RPCs can append log entries.
- **UPDATE / DELETE:**
  - STRICTLY FORBIDDEN FOR ALL ROLES (Append-Only Ledger).

---

## 3. Storage Security & Bucket Policies

### 3.1 Bucket: `worker-selfies` (PRIVATE)
- **Public URL Access:** Disabled (`public = false`).
- **Path Pattern:** `{worker_user_id}/{filename}.jpg`
- **Storage RLS Policies:**
  - **Upload (INSERT):**
    ```sql
    (bucket_id = 'worker-selfies') AND
    (auth.uid()::text = (storage.foldername(name))[1])
    ```
    *Enforces that a worker can only upload files into their own designated folder.*
  - **Read (SELECT):**
    ```sql
    (bucket_id = 'worker-selfies') AND
    (
      (auth.uid()::text = (storage.foldername(name))[1]) OR
      (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'))
    )
    ```
    *Only the owning worker and internal administrators can generate signed download URLs.*
  - **Delete (DELETE):** Blocked for mobile clients to preserve onboarding audit records.

---

## 4. Key Management & Environment Hygiene

| Credential | Scope | Where Located | Security Handling |
| :--- | :--- | :--- | :--- |
| `SUPABASE_URL` | Public | Flutter App & Next.js Admin | Safe to bundle in client apps. |
| `SUPABASE_ANON_KEY` | Public | Flutter App & Next.js Admin | Safe to bundle; protected by RLS on all database tables. |
| `SUPABASE_SERVICE_ROLE_KEY` | **Confidential** | Next.js Admin (Vercel Server Environment Variables Only) | **NEVER** expose to Flutter or browser clients. Used exclusively in server-side actions with explicit session verification. |
| SMS Provider API Keys | **Confidential** | Supabase Vault / Edge Functions | Encrypted in Supabase backend environment. |

---

## 5. Privilege Escalation Prevention Architecture

To prevent malicious users from crafting requests that grant themselves elevated privileges (such as the `admin` role or setting `is_first_job_approved = TRUE`):

1. **Role Table Immutability:** `user_roles` has no client-facing `UPDATE` policy.
2. **Explicit Admin Verification Helper Function:**
   ```sql
   CREATE OR REPLACE FUNCTION is_admin()
   RETURNS BOOLEAN AS $$
   BEGIN
     RETURN EXISTS (
       SELECT 1 FROM user_roles 
       WHERE user_id = auth.uid() AND role = 'admin'
     );
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```
3. **Database Constraints on Self-Approval:** The `is_first_job_approved` column on the `businesses` table cannot be altered by standard `UPDATE` queries; a trigger rejects modifications unless the caller executes within the security context of `is_admin() = TRUE`.
