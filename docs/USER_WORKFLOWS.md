# LaganStaff — User Workflows & State Machine Architecture

**Document Version:** 1.0.0  
**Status:** Approved for Phase 0 Planning  
**Scope:** Complete User Journeys, State Machines, and Capacity Logic  

---

## 1. Worker Workflow Journey

```mermaid
sequenceDiagram
    autonumber
    actor W as Worker
    participant APP as Flutter App
    participant AUTH as Supabase Auth
    participant DB as Postgres DB
    participant STO as Supabase Storage (Private)

    W->>APP: Launch App & Enter 10-Digit Mobile Number + 4-Digit PIN
    APP->>AUTH: Authenticate with synthetic email (phone@laganstaff.in) & padded PIN
    AUTH-->>APP: Issue Auth Session (JWT)
    
    APP->>APP: Role Selection Screen -> Selects "Worker"
    W->>APP: Enter Full Name, Locality (Ghazipur), Gender, DOB
    W->>APP: Select Worker Skills (Waiters, Cleaners, etc.)
    W->>APP: Grant Location Permission -> Capture Lat/Long
    
    W->>APP: Take Live Selfie with Camera
    APP->>APP: Client-Side Compression (< 100KB)
    APP->>STO: Upload to worker-selfies/{worker_id}/selfie.jpg
    STO-->>APP: Return Storage File Path
    
    APP->>DB: Invoke complete_worker_onboarding() RPC
    Note over DB: Validates all required fields & selfie path.<br/>Sets worker status = 'active'.<br/>Automatic Activation (No Admin approval).
    DB-->>APP: Success: Status = ACTIVE
    
    APP->>W: Display Job Discovery Feed
    W->>APP: Browse Jobs (Filtered by Ghazipur locality & skills)
    W->>APP: Tap "Apply Now" on Target Job
    APP->>DB: Invoke submit_job_application(job_id)
    DB-->>APP: Application Status: APPLIED
    
    Note over DB,W: When Owner accepts application:
    DB-->>APP: Notification / Status update -> ACCEPTED
    APP->>W: View Booking Confirmation Screen (Duty Pass with 4-Digit Check-In PIN)
    Note over W,APP: At Venue Gate: Worker shows 4-digit code to Owner.<br/>Owner enters code into app -> Attendance marked 'checked_in'.
```

---

## 2. Owner Workflow Journey & First-Job Moderation

```mermaid
sequenceDiagram
    autonumber
    actor O as Business Owner
    participant APP as Flutter App
    actor A as Administrator
    participant WEB as Admin Dashboard (Next.js)
    participant DB as Postgres DB

    O->>APP: Mobile OTP Login -> Selects "Owner"
    O->>APP: Enter Business Profile (Name, Category, Address, Contact)
    APP->>DB: Save Business Profile (is_first_job_approved = FALSE)
    
    O->>APP: Create Job Form (Title, 8 Waiters, Date, Shift Pay, Address)
    O->>APP: Tap "Publish Job"
    
    APP->>DB: Submit Job Creation RPC
    Note over DB: Checks business.is_first_job_approved == FALSE.<br/>Sets job status = 'pending_admin_approval'.<br/>Sets is_first_job = TRUE.
    DB-->>APP: Job Created: Awaiting Admin Approval
    
    Note over DB,WEB: Job appears in Admin Review Queue
    A->>WEB: Open First-Job Approvals Queue
    A->>WEB: Inspect Job Details, Wage Rate, Venue Legitimacy
    
    alt Admin Approves First Job
        A->>WEB: Click "Approve Job"
        WEB->>DB: Invoke approve_first_job(job_id)
        Note over DB: Atomic Transaction:<br/>1. businesses.is_first_job_approved = TRUE<br/>2. jobs.status = 'published'<br/>3. admin_audit_logs appended.
        DB-->>APP: Status Updated: PUBLISHED
        APP-->>O: Alert: Job is Live! Workers can now apply.
        Note over O,DB: All future jobs by this owner auto-publish immediately.
    else Admin Rejects First Job
        A->>WEB: Enter Rejection Reason -> Click "Reject Job"
        WEB->>DB: Invoke reject_first_job(job_id, reason)
        Note over DB: jobs.status = 'rejected'.<br/>admin_rejection_reason populated.
        DB-->>APP: Status: REJECTED with Admin Notes
        O->>APP: Edit Job Details & Tap "Resubmit"
        APP->>DB: Re-route to 'pending_admin_approval'
    end
```

---

## 3. Administrator Workflow

1. **Authentication:**
   - Admin accesses `admin.laganstaff.com`.
   - Authenticates using pre-provisioned credentials.
   - Zero public sign-up route exists; brute-force rate-limiting enforced on server.
2. **Operations Dashboard:**
   - Real-time KPI cards: Total Workers Registered, Total Verified Businesses, First-Jobs Pending Review, Active Shifts Today.
3. **First-Job Review Queue:**
   - Displays all jobs in `pending_admin_approval` status ordered by creation timestamp.
   - Inspects: Business category, location in Ghazipur, specified wage rate (flags sub-minimum rates), special conditions.
   - Action: **Approve** (commits business verification) or **Reject** (forces structured feedback).
4. **User & Business Governance:**
   - Search worker directory, inspect verification selfies, review dispute flags.
   - Action: Suspend fraudulent or non-reporting accounts (updates `status = 'suspended'`).
5. **Audit Ledger:**
   - Real-time, read-only feed of `admin_audit_logs` tracking every administrative mutation.

---

## 4. State Machines & Entity Lifecycles

### 4.1 Job Lifecycle State Machine

```mermaid
stateDiagram-v2
    [*] --> DRAFT : Owner creates draft
    DRAFT --> PENDING_ADMIN_APPROVAL : Submit (if is_first_job_approved == FALSE)
    DRAFT --> PUBLISHED : Submit (if is_first_job_approved == TRUE)
    
    PENDING_ADMIN_APPROVAL --> PUBLISHED : Admin Approves
    PENDING_ADMIN_APPROVAL --> REJECTED : Admin Rejects (with reason)
    
    REJECTED --> PENDING_ADMIN_APPROVAL : Owner edits & resubmits
    
    PUBLISHED --> FILLED : All worker slots confirmed
    PUBLISHED --> CANCELLED : Owner cancels prior to shift
    
    FILLED --> IN_PROGRESS : Shift start time reached
    FILLED --> CANCELLED : Unforeseen cancellation
    
    IN_PROGRESS --> COMPLETED : Shift finishes & attendance closed
    
    COMPLETED --> [*]
    CANCELLED --> [*]
```

### 4.2 Application Lifecycle State Machine

```mermaid
stateDiagram-v2
    [*] --> APPLIED : Worker applies
    APPLIED --> ACCEPTED : Owner accepts applicant (within quota)
    APPLIED --> REJECTED : Owner rejects applicant
    APPLIED --> WITHDRAWN : Worker withdraws application before acceptance
    
    ACCEPTED --> [*] : Promoted to Booking
    REJECTED --> [*]
    WITHDRAWN --> [*]
```

### 4.3 Booking Lifecycle State Machine

```mermaid
stateDiagram-v2
    [*] --> CONFIRMED : Created on Application Acceptance
    CONFIRMED --> CHECKED_IN : Worker arrives & owner marks attendance
    CONFIRMED --> NO_SHOW : Worker fails to report for shift
    CONFIRMED --> CANCELLED : Cancelled before shift
    
    CHECKED_IN --> COMPLETED : Shift concluded & marked done
    
    COMPLETED --> [*]
    NO_SHOW --> [*]
    CANCELLED --> [*]
```

---

## 5. Capacity Enforcement & Concurrency Architecture

### 5.1 The Race Condition Challenge
- **Scenario:** A marriage lawn owner in Ghazipur posts a job for **10 Waiters**.
- **Event:** A surge of **100 local workers** view the job simultaneously and tap "Apply".
- **Risk:** Without database-level controls, naive frontend checks or non-atomic queries can cause over-allocation (e.g., 14 workers accepted for 10 slots).

### 5.2 Transaction-Safe Resolution Architecture
Capacity enforcement is implemented at the database level inside a PostgreSQL stored procedure using **Row-Level Locking (`FOR UPDATE`)**:

```
Client Request (Accept Applicant)
               │
               ▼
   [BEGIN POSTGRES TRANSACTION]
               │
               ▼
   SELECT workers_needed, workers_confirmed 
   FROM jobs 
   WHERE id = target_job_id 
   FOR UPDATE;  <--- LOCKS JOB ROW EXCLUSIVELY
               │
      [workers_confirmed < workers_needed ?]
         ├── NO  ──> ROLLBACK TRANSACTION
         │           RAISE EXCEPTION "Job capacity is full."
         │
         └── YES ──> UPDATE jobs 
                     SET workers_confirmed = workers_confirmed + 1,
                         status = CASE WHEN (workers_confirmed + 1) = workers_needed 
                                       THEN 'filled'::job_status 
                                       ELSE status END
                     WHERE id = target_job_id;
                     
                     UPDATE job_applications 
                     SET status = 'accepted' 
                     WHERE id = target_application_id;
                     
                     INSERT INTO bookings (job_id, application_id, worker_profile_id, business_id, agreed_wage, status)
                     VALUES (...);
                     
                     [COMMIT TRANSACTION]  <--- LOCK RELEASED
```

This guarantees that even under extreme concurrency, exactly 10 bookings can be confirmed.
