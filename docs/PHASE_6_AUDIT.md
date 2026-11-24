# LaganStaff — Phase 6 Architecture & Gap Audit
## Comprehensive Audit of Job Discovery & Job Management

**Date:** November 18, 2026  
**Auditor:** Senior Marketplace Architecture & Database Performance Engineer  
**Status:** Audit Completed — Implementation Plan Ready  

---

## 1. Executive Summary

Phase 5 established the initial foundation for job creation, first-job administrative approval, and a baseline worker discovery feed. Phase 6 focuses on transforming this foundation into an optimized, marketplace-grade **Job Discovery Engine for Workers** and **Job Operations Suite for Owners**.

This audit inspects the current repository state across the Flutter application (`apps/mobile`), the Next.js admin dashboard (`apps/admin`), and the Supabase PostgreSQL backend (`supabase/`), identifying gaps against Phase 6 requirements and establishing the exact remediation path.

---

## 2. Component-by-Component Audit

### 2.1 Worker Job Discovery

| Requirement | Current State (Phase 5) | Phase 6 Requirement | Audit Finding / Gap |
|---|---|---|---|
| **Role & Status Gate** | Active workers can browse | Active + onboarded workers only | Working. Need to ensure inactive workers are redirected. |
| **Real Database Data** | Uses `get_available_jobs_for_worker` RPC | Real Supabase queries only | Working. |
| **Expired Jobs Guard** | Fallback had date check, but main RPC lacked `shift_date >= CURRENT_DATE` | Expired jobs must be hidden from worker discovery | **Missing in RPC.** Jobs with past dates could still appear if status was 'published'. |
| **Free Text Search** | No keyword/text search in worker discovery | Search by title, business name, venue, locality | **Missing.** Need text search query input in UI and RPC. |
| **Location Filters** | Locality only (chips in bottom sheet) | City, District, Locality, PIN code (Ghazipur, Saidpur, Zamania, Mohammadabad) | **Incomplete.** Need multi-tier location filters (City, Locality, PIN) without fake GPS distance calculations. |
| **Shift Timing Filters** | Only single specific date | Specific date, date range, and shift types (Morning, Evening, Night/Overnight) | **Missing.** Need shift-type categorization (Morning: 05:00-12:00, Evening: 12:00-18:00, Night: >=18:00 or overnight). |
| **Wage Range Filtering** | Minimum wage slider | Min wage, Max wage, per-shift basis with INR ₹ | Working partially. Needs dual-bound range slider and presets. |
| **Job Availability Display** | Showed simulated "X spots remaining" | Show clean availability status ("खुली शिफ्ट / Open", "उपलब्ध / Available", "समाप्त / Expired") | **Needs Adjustment.** Do not invent remaining vacancies or display false confirmed worker counts before Phase 7. |
| **Apply Action Guard** | Had a snackbar placeholder | Must remain informational only (Applications belong to Phase 7) | Preserved. Clearly communicate that bookings open in Phase 7. |

---

### 2.2 Owner Job Management ("My Jobs")

| Requirement | Current State (Phase 5) | Phase 6 Requirement | Audit Finding / Gap |
|---|---|---|---|
| **Status Tabs** | All, Pending, Published, Draft, Rejected, Cancelled | Add **Expired** tab | **Incomplete.** Needs an Expired filter tab for past shifts. |
| **Owner Search & Date Filter** | Only status tab filtering | Search by title/venue, and filter by date | **Missing.** Need search bar and date picker filter for Owner Jobs. |
| **Published Job Editing** | Replaced all fields or opened draft | Authorized non-critical edits (instructions, perks, venue details) with audit tracking | **Incomplete.** Needs explicit policy permitting non-critical edits on published jobs with `updated_at` update and audit logging. |
| **Job Cancellation** | Functional via `owner_cancel_job` | Confirmation dialog, reason capture, cancels safely, hides from workers | Working. Minor UI improvements needed for cancellation flow. |

---

### 2.3 Database & Indexing

| Object | Current State | Phase 6 Requirement | Audit Finding / Gap |
|---|---|---|---|
| **`jobs` Table** | Has all Phase 5 columns | Support text search, city, district, shift categorization | Schema is solid; needs full-text or ILIKE composite indexes. |
| **Indexes** | Basic B-trees on status, shift_date, locality, wage | High-throughput composite indexes for `(status, shift_date, city, locality)` and `(status, wage_amount)` | **Improvement Required.** Add composite index for active Ghazipur feed queries. |
| **`get_available_jobs_for_worker` RPC** | Basic filters (locality, single date, min/max wage) | Support keyword search, date range, shift type (morning/evening/night), city, and hide expired jobs (`shift_date >= CURRENT_DATE`) | **Must Update RPC.** |
| **`update_published_job` RPC** | Allowed editing draft/rejected jobs | Controlled update of non-critical fields for published jobs with audit logging | **New RPC Required.** |

---

## 3. Required Database Changes

1. **Migration `20261118000005_phase6_discovery_management.sql`:**
   - Enhance `get_available_jobs_for_worker` RPC:
     - Add `p_search_query TEXT DEFAULT NULL` (searches `title`, `business_name`, `venue_name`, `locality`).
     - Add `p_city TEXT DEFAULT NULL`.
     - Add `p_start_date DATE DEFAULT NULL` and `p_end_date DATE DEFAULT NULL` for date range filtering.
     - Add `p_shift_type TEXT DEFAULT NULL` (`'morning'`, `'evening'`, `'night'`).
     - Strictly enforce `j.shift_date >= CURRENT_DATE` to hide expired shifts.
   - Enhance `get_owner_jobs` RPC:
     - Add support for `'expired'` status tab (`shift_date < CURRENT_DATE AND status = 'published'`).
     - Add `p_search_query TEXT DEFAULT NULL`.
   - Create `update_published_job` RPC (`SECURITY DEFINER`):
     - Validates ownership.
     - Allows updating permitted fields: `description`, `venue_name`, `reporting_address`, `special_instructions`, `food_provided`, `food_details`, `transport_provided`, `transport_details`, `payment_instructions`.
     - Prohibits altering wage, shift date/time, or status directly.
     - Logs audit trail entry to `admin_audit_logs`.
   - Add Composite Indexes:
     - `idx_jobs_worker_feed_p6` ON `jobs(status, shift_date, locality, wage_amount) WHERE status = 'published'`.
     - `idx_jobs_city_district` ON `jobs(city, district)`.

---

## 4. Required Mobile UI Improvements

1. **Worker Job Discovery (`worker_job_discovery_screen.dart`):**
   - Add Search Bar at top of feed for instant text search across job title, venue, and locality.
   - Multi-tier Location Filter: Ghazipur hubs (City Center, Saidpur, Zamania, Mohammadabad, Lanka, etc.).
   - Date & Shift Filter: Quick chips for "आज (Today)", "कल (Tomorrow)", "इस हफ्ते (This Week)" plus custom date range picker; Shift Type selector ("सुबह / Morning", "शाम / Evening", "रात / Night").
   - Dual-bound Wage Slider (Min - Max ₹).
   - Display honest Job Availability: "खुली शिफ्ट (Open for Shift)" and "${job.workersNeeded} कार्यकर्ता आवश्यकता" instead of simulated bookings.
2. **Worker Job Details (`worker_job_detail_screen.dart`):**
   - Add prominent Job Availability Badge: "सक्रिय व उपलब्ध (Active & Open)" or "समाप्त (Expired)".
   - Clarify that Shift Bookings and Direct Application open in Phase 7.
3. **Owner My Jobs (`owner_jobs_list_screen.dart`):**
   - Add Search input bar to search owner's own jobs.
   - Add "समाप्त (Expired)" status tab to view past completed/expired dates.
4. **Owner Job Details & Editing (`owner_job_detail_screen.dart`):**
   - Support updating published jobs with a clean dedicated edit sheet for non-critical fields.
   - Confirmation dialog for cancellation with reason capture.

---

## 5. Scope Boundary Verification

- **STRICTLY EXCLUDED:** Worker job applications, applicant list review by owner, applicant acceptance/rejection, booking confirmations, check-in PIN codes, attendance verification, payments, ratings, notifications.
- All Phase 0–5 implementations (Authentication, Worker Onboarding, Owner Verification, First-Job Approval Queue) must remain intact.
