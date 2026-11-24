# LaganStaff — Project Requirements Document (PRD)

**Document Version:** 1.0.0  
**Status:** Approved for Phase 0 Planning  
**Target Region:** Ghazipur, Uttar Pradesh, India  
**System Classification:** Hyperlocal Temporary Workforce Marketplace  

---

## 1. Executive Summary & Problem Statement

### 1.1 Executive Summary
LaganStaff is an on-demand, hyperlocal workforce marketplace designed to eliminate traditional informal middlemen (*thekedars* or labor brokers) by connecting local businesses with verified temporary workers. The initial launch is focused on Ghazipur, Uttar Pradesh, servicing event hospitality, wedding industries, catering, tent fabrication, and commercial logistics.

### 1.2 The Problem
In Tier-2/Tier-3 Indian economies like Ghazipur:
1. **Business Inefficiency:** Event organizers, marriage lawn owners, and caterers experience chronic unpredictability in procuring temporary staff (waiters, halwai helpers, cleaners, loaders) during peak wedding and festive seasons.
2. **Exploitative Intermediaries:** Local middlemen siphon 30% to 50% of worker compensation while offering zero guarantee of punctuality or attendance to business owners.
3. **Absence of Record & Trust:** Workers lack verifiable work histories, transparent compensation records, and direct market access. Businesses have no standardized recourse for last-minute worker no-shows.

### 1.3 The Solution
A unified, mobile-first ecosystem comprising:
- **LaganStaff Flutter Mobile App:** A single native Android/iOS mobile application providing distinct, role-based workflows for **Workers** and **Business Owners**.
- **LaganStaff Admin Web Dashboard:** A secure, desktop-first Next.js web portal providing verification oversight, first-job moderation, audit tracking, dispute handling, and system governance.
- **Supabase Cloud Infrastructure:** A secure PostgreSQL database with Row Level Security (RLS), atomic transactional Remote Procedure Calls (RPC), and private object storage.

---

## 2. Business Scope & Taxonomy

### 2.1 Target Businesses
The platform targets local enterprise categories with acute, fluctuating labor demands:
1. **Marriage Halls & Lawn Banquets:** Banquet managers needing front-of-house service staff and post-event turnaround teams.
2. **Catering Businesses:** Independent caterers and culinary contractors needing food preparation helpers, live counter attendants, and plate clearing crews.
3. **Tent Houses & Decorators:** Vendors requiring heavy lifters, pipe fabricators, drape riggers, and lighting assistants.
4. **Event Organizers:** Planners orchestrating cultural, political, or social gatherings requiring coordinators and crowd management staff.
5. **Logistics & Small Warehouses:** Local traders needing day-wage manual loaders and unloader crews.

### 2.2 Worker Categories (MVP)
Initial standardized worker categories defined in the platform:
- **Waiters (Serving Staff):** Food and beverage table service, buffet maintenance.
- **Cleaners / Housekeeping:** Post-event dishwashing, floor sanitation, waste disposal.
- **Halwai Helpers (Culinary Assistants):** Vegetable preparation, large vessel handling, raw material movement.
- **Loaders / Labor:** Loading/unloading heavy equipment, tent framing, stage structures.
- **Event Helpers:** General runners, setup assistants, queue guides.
- **Other Temporary Labor:** Flexible category for unlisted immediate requirements.

---

## 3. User Personas & Regional Context

| Attribute | Worker Persona | Business Owner Persona | Admin Persona |
| :--- | :--- | :--- | :--- |
| **Primary User** | Local youth, semi-skilled/unskilled gig workers in Ghazipur district. | Banquet hall managers, caterers, tent house owners. | LaganStaff internal operations & moderation officers. |
| **Hardware** | Budget Android smartphones (2GB–4GB RAM, Android 9+). | Mid-range Android smartphones or desktop PCs. | Desktop/Laptop web browser (Chrome, Edge, Safari). |
| **Connectivity** | Intermittent 4G cellular data; occasional 2G/3G degradation. | Stable 4G/5G or local commercial Wi-Fi. | High-speed broadband. |
| **Language** | Hindi (primary), Bhojpuri (colloquial), simple Hinglish. | Hindi and English (bilingual). | English. |
| **Digital Literacy** | Basic: Accustomed to YouTube, WhatsApp, and OTP inputs. | Moderate: Uses WhatsApp Business, payment apps (PhonePe/GPay). | High: SaaS administration proficient. |

---

## 4. Functional Requirements

### 4.1 Common System & Authentication (Mobile)
- **FR-AUTH-01 (Phone OTP):** Users authenticate exclusively via valid 10-digit Indian mobile numbers (+91) with 6-digit SMS OTP verification via Supabase Auth.
- **FR-AUTH-02 (Session Persistence):** Device sessions must persist securely using device-level encrypted storage across app terminations.
- **FR-AUTH-03 (Role Selection):** On initial authentication, if no profile exists, the user selects their primary operating persona: `Worker` or `Owner`.
- **FR-AUTH-04 (Role Segregation):** A user account cannot concurrently act as both an active Worker and an Owner on the same profile in Phase 0/MVP. Role switching requires explicit architectural decoupling.

### 4.2 Worker Lifecycle
- **FR-WRK-01 (Registration Profile):** Full name, gender, date of birth, emergency contact, residential area in Ghazipur.
- **FR-WRK-02 (Skills Selection):** Multi-select capability across standardized worker categories.
- **FR-WRK-03 (Location Pin):** Capture GPS coordinates (latitude, longitude) and text locality with user permission.
- **FR-WRK-04 (Selfie Verification Upload):** Live camera capture of worker's selfie. Stored in a private, non-public Supabase storage bucket (`worker-selfies`).
- **FR-WRK-05 (Automatic Activation):** Upon successful submission of all mandatory profile attributes and selfie upload, worker account status transitions directly to `ACTIVE`. No manual admin intervention is required.
- **FR-WRK-06 (Job Discovery Feed):** Real-time feed of published jobs, filterable by distance/locality, wage rate, date, and category.
- **FR-WRK-07 (Application Submission):** Worker can submit a single application per published job. Duplicate submissions are strictly prevented at the database level.
- **FR-WRK-08 (Application Tracking):** Status dashboard showing `APPLIED`, `ACCEPTED`, `REJECTED`, or `WITHDRAWN`.
- **FR-WRK-09 (Booking Confirmation View):** Displays venue address, reporting time, owner contact, and required dress code/tools upon application acceptance.

### 4.3 Business Owner Lifecycle
- **FR-OWN-01 (Business Profile Registration):** Legal/trade business name, category (Marriage Hall, Catering, Tent, etc.), physical address, GST/Trade number (optional in MVP), contact person.
- **FR-OWN-02 (Job Creation Engine):** Form to create a job listing specifying:
  - Job Title & Category
  - Number of workers required (Capacity limit: e.g., 8 Waiters)
  - Date, shift start time, shift end time
  - Reporting address & GPS pin
  - Per-day / per-shift wage rate (INR)
  - Special instructions (e.g., formal black dress code, non-smoker)
- **FR-OWN-03 (First-Job Approval Gate):**
  - The business's first job submission is automatically routed to `PENDING_ADMIN_APPROVAL`.
  - While pending, the owner cannot publish subsequent jobs.
- **FR-OWN-04 (Subsequent-Job Auto-Publish):**
  - Once the business's first job is approved by an Admin, the business entity is flagged as `is_first_job_approved = TRUE`.
  - All subsequent valid job postings from this business transition immediately to `PUBLISHED`.
- **FR-OWN-05 (Applicant Review):** Owner can inspect worker name, skills, rating (if any), and application timestamp for applicants to their active jobs.
- **FR-OWN-06 (Applicant Acceptance & Capacity Cap):** Owner can accept applicants up to the exact worker limit requested. Capacity is strictly enforced via database transactions.

### 4.4 Admin Web Dashboard Lifecycle
- **FR-ADM-01 (Secure Portal Access):** Admin portal operates at a separate dedicated domain (`admin.<domain>`). Public sign-up is entirely disabled.
- **FR-ADM-02 (First-Job Approval Queue):** Real-time queue displaying newly submitted first jobs from unverified businesses.
- **FR-ADM-03 (Job Moderation Actions):**
  - **Approve:** Transitions job to `PUBLISHED`, updates business to `is_first_job_approved = TRUE`, notifies owner.
  - **Reject:** Requires a mandatory rejection reason code/note, transitions job to `REJECTED`, allows owner to edit and resubmit.
- **FR-ADM-04 (User Management):** Capability to inspect, activate, suspend, or terminate Worker and Owner accounts.
- **FR-ADM-05 (Audit Trail Logging):** Every administrative write action (job approval, rejection, user suspension) is immutably appended to `admin_audit_logs`.

---

## 5. Non-Functional Requirements (NFR)

### 5.1 Performance & Responsiveness
- **NFR-PERF-01:** Job feed list API response time must remain under 300ms on 4G cellular connections.
- **NFR-PERF-02:** Cold app startup on 3GB RAM Android devices must not exceed 2.5 seconds.
- **NFR-PERF-03:** Image compression on device must reduce selfie payload below 300KB before transmission to Supabase Storage.

### 5.2 Security & Data Privacy
- **NFR-SEC-01 (Zero Service-Role Exposure):** The Flutter mobile application package must only bundle the Supabase `anon` public API key. The `service_role` key must never be bundled or transmitted to mobile devices.
- **NFR-SEC-02 (Storage Privacy):** Worker selfie images must be stored in a private bucket (`worker-selfies`) with zero public access. Access is granted exclusively via short-lived signed URLs (TTL $\le$ 15 minutes) or RLS owner policies.
- **NFR-SEC-03 (Database Hardening):** 100% of public schema tables must enforce Row Level Security (`ENABLE ROW LEVEL SECURITY`). Zero open access without authenticated context.

### 5.3 Reliability & Concurrency
- **NFR-REL-01 (Zero Over-Booking):** Under high concurrency (e.g., 50 workers simultaneously pressing "Apply" or owner approving applicants), database transaction isolation (`SELECT ... FOR UPDATE` via RPC) must strictly prevent booking counts exceeding the requested quota.
- **NFR-REL-02 (Data Durability):** Daily automated PostgreSQL backups with Point-In-Time-Recovery (PITR) enabled on Supabase.

---

## 6. Resolved Decisions (Locked for MVP)

> [!IMPORTANT]
> The following architectural decisions have been finalized and locked for MVP implementation:

1. **Authentication Strategy (Zero SMS Cost & No DLT Dependency):**
   - SMS OTP is **completely skipped** for MVP.
   - Authentication is implemented via **10-Digit Indian Phone Number + 4-Digit Security PIN**.
   - Under the hood, this leverages Supabase Email/Password Auth:
     - Synthetic Email: `{10_digit_phone}@laganstaff.in` (e.g. `9876543210@laganstaff.in`).
     - Secure Padded Password: Salted and padded 4-digit PIN meeting Supabase minimum password security rules (e.g., `Lagan#PIN{pin}*2026`).
   - Clean UX: Users see and interact solely with Phone Number and 4-digit PIN fields. Zero email or password references in mobile UI.
2. **On-Site Attendance Verification (4-Digit Duty Pass Check-in PIN):**
   - Geofencing is **strictly avoided** to prevent false negatives from GPS drift in covered banquet halls/tents.
   - Every confirmed booking automatically generates a cryptographic/random **4-digit check-in code** (`checkin_code`, e.g. `7429`).
   - The worker's mobile app displays this 4-digit code on their **Duty Pass**.
   - Upon arriving at the venue gate, the worker presents the code to the business owner/manager.
   - The owner enters the 4-digit code into the LaganStaff app, which verifies the match and atomically transitions the booking and attendance to `checked_in`.
3. **Identity Verification Scope:**
   - Platform verification relies exclusively on live camera selfie capture.
   - The image is aggressively compressed on-device to $< 100\text{ KB}$ before transmission to private Supabase Storage (`worker-selfies`).
   - No third-party Aadhaar or government ID integration for MVP.

---

## 7. Scope Boundary: MVP vs Future Enhancements

```
┌────────────────────────────────────────────────────────┐
│                      PHASE 0 - MVP                     │
│  - Phone OTP Authentication (Supabase Auth)            │
│  - Single Mobile App (Flutter) with Worker/Owner Roles │
│  - Worker Profile, Skills, Location, Selfie Upload     │
│  - Worker Automatic Activation                         │
│  - Owner Business Profile & First-Job Review Gate      │
│  - Next.js Admin Dashboard for First-Job Moderation    │
│  - Subsequent Jobs Auto-Publish                        │
│  - Atomic Job Capacity Allocation via Supabase RPC     │
│  - Core Booking Confirmation Flow                      │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                   FUTURE ENHANCEMENTS                  │
│  - Firebase Cloud Messaging (FCM) Push Notifications   │
│  - In-App Escrow / UPI Payment Gateway (Razorpay/Cash) │
│  - Realtime GPS Worker Tracking on Duty                │
│  - Biometric / Aadhaar KYC Verification                │
│  - Worker Rating, Review & Reputation System           │
│  - Offline SMS/IVR Fallback for low-literacy workers   │
│  - Geofenced Automated Shift Check-In / Check-Out      │
└────────────────────────────────────────────────────────┘
```
