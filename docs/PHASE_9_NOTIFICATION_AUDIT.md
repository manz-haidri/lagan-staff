# LaganStaff — Phase 9 Notification System Audit
## Comprehensive Architecture, Event Triggers & Dependency Assessment

**Date:** 2026-11-18  
**Project:** LaganStaff (Hyperlocal Temporary Workforce Marketplace — Ghazipur, UP, India)  
**Auditor:** Senior Flutter Developer, Firebase Cloud Messaging Engineer & Supabase Backend Architect  
**Status:** **AUDIT COMPLETE — ARCHITECTURE SPECIFIED**  

---

### 1. Executive Summary

This audit assesses the existing LaganStaff codebase across Phase 0 through Phase 8 to determine the exact requirements, database triggers, event sources, dependency blockers, and infrastructure required to deliver a **production-grade notification system** for the mobile application (`apps/mobile`), backed by Supabase PostgreSQL and Firebase Cloud Messaging (FCM HTTP v1).

---

### 2. Existing Functionality Audit (Phases 0–8)

| Domain | Implemented Components | Audit Finding |
| :--- | :--- | :--- |
| **Authentication & Profiles** | Phone + 4-digit PIN Auth under the hood via Supabase Email Auth. `profiles`, `user_roles`, `worker_profiles`, `businesses`. | Role-based identity established. Workers and Owners have unique `profiles.id` and `user_id`. |
| **Jobs & Discovery** | `jobs`, `categories`, `skills`, `job_skills`. Lifecycle states: `draft`, `pending_admin_approval`, `published`, `filled`, `in_progress`, `completed`, `cancelled`, `rejected`. | Jobs transition to `published` upon approval or subsequent posting. Event source exists for **New Job Notifications**. |
| **Job Cancellation** | `owner_cancel_job()` and `admin_cancel_job()` RPCs. | Job transitions to `cancelled` with reason. Event source exists for **Job Cancellation Notifications**. |
| **Bookings & Attendance** | `bookings`, `attendance_records`, `booking_cancellation_records`. RPCs for attendance roster, check-in window, and completion. | The database structures for `bookings` exist (created in Phase 7). Confirmed bookings have `shift_date`, `start_time`, `end_time`. |
| **Admin Control Center** | Complete Next.js dashboard (`apps/admin`) with queues for verifications, job approvals, complaints, and directory inspection. | Admin triggers status transitions via database RPCs (e.g., `admin_review_first_job`, `admin_cancel_job`). |
| **Notification Code in Mobile** | None. | Flutter app currently has zero Firebase or FCM code. |
| **Firebase Configuration** | None. | `google-services.json` and FlutterFire plugins were not previously installed or configured. |
| **Supabase Edge Functions** | None. | No Edge Functions currently exist in `supabase/functions/`. |

---

### 3. Critical Dependency Audit: Applications & Booking Engine

In accordance with **Section 4 of the Phase 9 Specification**, we audit the event sources required for each notification category:

| Notification Category | Event Source Status | Dependency Status | Action in Phase 9 |
| :--- | :---: | :---: | :--- |
| **A. New Job Notification** | ✅ **AVAILABLE** | Job transitions to `published` in `jobs` table (via Owner subsequent post or Admin approval). Matching workers identified via `worker_skills` and locality. | **Fully Implemented**: Database trigger + Outbox enqueue + FCM dispatch. |
| **B. Application Received** | ⚠️ **BLOCKED** | **Missing Prerequisite:** The `job_applications` table does not exist in the active schema. Workers cannot currently submit formal applications from the mobile UI. | **Infrastructure Prepared & Blocked**: Schema and outbox types support `application_received`, but no fake records will be emitted until the Application module is built in Phase 10. |
| **C. Application Approved / Rejected** | ⚠️ **BLOCKED** | **Missing Prerequisite:** Because `job_applications` does not exist, status transitions (`pending` $\rightarrow$ `accepted` / `rejected`) cannot occur in business logic. | **Infrastructure Prepared & Blocked**: Payload schemas ready; documented as blocked without fake event generation. |
| **D. Booking Confirmation** | 🔄 **PARTIALLY BLOCKED** | `public.bookings` exists in the schema. However, because application acceptance is not yet live in mobile, bookings are not generated from normal client flow. | **Fully Implemented**: Database trigger on `bookings (status = 'confirmed')` is implemented. Whenever a booking row is created/confirmed, the outbox immediately enqueues worker & owner alerts. |
| **E. Job Cancellation** | ✅ **AVAILABLE** | Job transitions to `cancelled` via `owner_cancel_job()` or `admin_cancel_job()`. | **Fully Implemented**: Database trigger detects `jobs.status = 'cancelled'`, queries affected bookings or owner, and enqueues outbox records. |
| **F. Shift Reminders** | ✅ **AVAILABLE** | `bookings` has `shift_date`, `jobs.start_time` in Asia/Kolkata timezone. | **Fully Implemented**: Periodic cron function/RPC `schedule_shift_reminders()` checks bookings at $T-24\text{h}$ and $T-2\text{h}$, enqueuing idempotent reminder events. |

---

### 4. Existing Database Event Mechanisms

- Supabase PostgreSQL supports:
  1. **Transactional Triggers:** Execute PL/pgSQL functions on `AFTER INSERT OR UPDATE` of `jobs` and `bookings`.
  2. **Transactional Outbox Table:** In-app `notifications` and `notification_outbox` entries are written within the exact same database transaction that modified the business record.
  3. **Zero Risk of Phantom Notifications:** If the business update fails or rolls back, zero notifications are queued.
  4. **Database Webhook or pg_net / Edge Function Dispatcher:** Near-real-time HTTP invocation to Supabase Edge Functions with reliable asynchronous retry recovery.

---

### 5. Firebase Setup Status & Configuration Plan

- **Android Package / Application ID:** `com.laganstaff.lagan_staff` (configured in `apps/mobile/android/app/build.gradle.kts`).
- **Dependencies Installed in Mobile:**
  - `firebase_core: ^5.2.0`
  - `firebase_messaging: ^17.1.0`
  - `flutter_local_notifications: ^23.0.3`
- **FCM API Version:** **FCM HTTP v1 API** (`https://fcm.googleapis.com/v1/projects/{projectId}/messages:send`).
- **Secret Management:** Google Service Account JSON credentials stored exclusively in Supabase Edge Function Secrets (`FCM_SERVICE_ACCOUNT`). Never embedded in Flutter source code, Git commits, or SQL migrations.

---

### 6. Required Database Migrations (`20261118000008_phase9_notification_engine.sql`)

1. **`device_tokens`:** Stores FCM registration tokens mapped to `user_id`, `installation_id`, `platform`, `app_version`, `is_active`, and `last_seen_at`.
2. **`notifications`:** In-app notification center table storing title, body, payload data, read states, and entity links.
3. **`notification_preferences`:** Per-user controls for `new_job_alerts`, `application_updates`, `booking_updates`, and `shift_reminders`.
4. **`notification_outbox`:** Transactional queue with idempotency keys (`event_key`), retry attempts, and exponential backoff scheduling.
5. **`notification_delivery_attempts`:** Audit log of FCM responses, error codes, and delivery statuses.
6. **Outbox Enqueue Functions & Triggers:**
   - Trigger on `jobs` transition to `published` (matching active workers with skills/locality).
   - Trigger on `jobs` transition to `cancelled` (notifying affected booking participants).
   - Trigger on `bookings` transition to `confirmed` (notifying worker and business owner).
   - Stored procedure `schedule_shift_reminders()` (evaluating $T-24\text{h}$ and $T-2\text{h}$ shifts in `Asia/Kolkata`).
   - Stored procedure `claim_pending_outbox_batch()` for atomic queue processing.

---

### 7. Required Supabase Edge Functions

1. **`dispatch-notifications` (or `process-notification-outbox`):**
   - Claims pending batches from `notification_outbox`.
   - Generates Google OAuth2 JWT / Bearer Token for FCM HTTP v1 API.
   - Queries active device tokens for recipient user.
   - Dispatches FCM payloads with high priority and notification channels (`job_alerts`, `booking_updates`, `shift_reminders`).
   - Marks outbox status (`sent` or `retry_scheduled` or `failed`) and deactivates invalid device tokens (`UNREGISTERED` / `INVALID_ARGUMENT`).
2. **`schedule-shift-reminders`:**
   - Invoked every 15–30 minutes via pg_cron or scheduled webhook.
   - Calls PostgreSQL `schedule_shift_reminders()` RPC.

---

### 8. Architectural Conclusions

LaganStaff Phase 9 establishes an **enterprise-grade transactional notification engine**. The Flutter client will never directly invoke push endpoints or manufacture events. Notifications are deterministic results of committed PostgreSQL business operations, providing complete transparency and resilience for the Ghazipur marketplace.
