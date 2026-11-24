# Google Stitch UI Prompts — Next.js Admin Web Dashboard

**Context:** Enterprise web dashboard for internal operations and first-job moderation at LaganStaff.  
**Form Factor:** Responsive desktop web browser (1440 x 900 px minimum).  
**URL Environment:** `admin.<domain>`  
**Design Language:** Tailwind CSS / Modern Admin Portal, Deep Indigo (`#1E3A8A`), Clean Slate Grays (`#0F172A`, `#F8FAFC`), Data Density, Keyboard Navigable.  
**Language:** English (Professional Operations Portal).  

---

### Screen ADM-01: Admin Secure Login
```
Prompt:
Clean desktop web login interface for LaganStaff Administrators.
Center: Minimalist elevated white card with subtle drop shadow on a slate-100 (#F1F5F9) background.
Top: LaganStaff Shield Logo in deep indigo (#1E3A8A) with tag "Internal Operations Portal".
Warning Notice: "Authorized Personnel Only. All access attempts are monitored and IP logged."
Fields:
- Admin Email or Operator ID input.
- Secure Master Password / 2FA Authenticator Code input.
Button: Full-width button (#1E3A8A) "Authenticate & Access Console".
Footer: "LaganStaff Core Engine • Ghazipur Cluster • v1.0.0".
```

### Screen ADM-02: Executive Operations Dashboard
```
Prompt:
Executive command center dashboard for internal operations staff.
Top Navigation: Brand logo, cluster indicator ("Cluster: Ghazipur UP"), active admin profile avatar, and "Sign Out".
Left Sidebar: Navigation links with modern Lucide icons:
- Dashboard (Active)
- First-Job Queue (Badge: 3)
- Workers Directory
- Owners & Businesses
- Master Jobs
- Bookings & Attendance
- Taxonomy Settings
- Audit Logs
Main Content Area:
Top KPI Metric Cards (4 columns):
1. "Pending First-Jobs": "3" (Amber highlight, link to queue).
2. "Total Active Workers": "342" (+18 today).
3. "Verified Businesses": "48" (Banquet halls, caterers).
4. "Active Shifts Tonight": "14" (112 workers on duty).
Middle Section:
- Left (2/3 width): "Live First-Job Moderation Queue" showing top 3 urgent unreviewed job submissions.
- Right (1/3 width): "Recent Platform Activity" live audit feed (e.g., "Admin John approved Shahi Banquet", "Worker Amit registered").
```

### Screen ADM-03: First-Job Approval Queue
```
Prompt:
High-priority review queue for first-time business job postings.
Header: "First-Job Moderation Queue" with subtext "Businesses require 1-time manual approval before unlocking automatic publishing."
Filter Controls: Search by business name, filter by category (Marriage Hall, Catering, Tent), sort by oldest submission.
Data Table:
- Column 1: Submission Time (e.g., "12 mins ago").
- Column 2: Business Name & Category (e.g., "Ghazipur Grand Lawn • Marriage Hall").
- Column 3: Contact Person & Phone ("Vipin Rai • +91 98765 11223").
- Column 4: Job Title & Capacity ("12 Waiters needed • 24 Nov").
- Column 5: Offered Wage ("₹700 / shift").
- Column 6: Action Button: High-visibility "Review & Decide" button.
Empty State (when queue cleared): Cheerful illustration with text "All caught up! Zero pending approvals in Ghazipur cluster."
```

### Screen ADM-04: Job Details Moderation Review (Side-by-Side Modal)
```
Prompt:
Detailed split-screen review modal for moderating a business's first job.
Left Column (Business Profile):
- Business Name: "Rajwada Banquet Lawn".
- Trade Category: "Marriage Lawn".
- Location: "Near PG College, Lanka, Ghazipur, UP".
- Owner Name: "Sunil Singh (+91 98765 44332)".
- First-Time Poster Badge: "New Business - Verification Required".
Right Column (Job Specifications):
- Title: "10 Experienced Waiters for Wedding Reception".
- Shift Date & Time: "25 Nov 2026, 06:00 PM to 01:00 AM (7 hrs)".
- Pay: "₹650 per worker" (System Tag: "Fair Market Rate in Ghazipur").
- Special Instructions: "Clean black trousers, punctual reporting".
Bottom Decision Bar:
- Red Button: "Reject Job with Reason" (opens mandatory rejection notes dropdown: Sub-minimum wage, Invalid address, Suspected spam, Duplicate).
- Green Button: "Approve Job & Verify Business" (Triggers atomic transaction: publishes job and sets is_first_job_approved = TRUE).
```

### Screen ADM-05: Workers Management Directory
```
Prompt:
Data-dense management table for registered workers.
Header: "Workers Directory (Ghazipur District)" with total count "342".
Search & Filters: Text search by name/phone, filter by locality (Lanka, Mahuabagh, Sadar), filter by status (Active, Suspended).
Table Columns:
- Photo Thumbnail (clickable for high-res selfie inspection).
- Name & Phone Number.
- Primary Skills (Waiters, Cleaners, Halwai).
- Locality & Lat/Long Coordinates.
- Shifts Completed & Reliability Rating.
- Status Badge: "ACTIVE" (green) or "SUSPENDED" (red).
- Actions: Dropdown (View Details, Suspend Account, Reactivate, Audit History).
```

### Screen ADM-06: Owners & Businesses Directory
```
Prompt:
Administrative table for managing business owners and trade entities.
Filters: Search business name, filter by category (Tent Houses, Catering, Lawns), filter by verification state.
Columns:
- Business Trade Name & Locality.
- Owner Name & Registered Mobile.
- Category Tag.
- First-Job Status Badge: "VERIFIED (Auto-Publish Active)" (green) or "PENDING REVIEW" (yellow).
- Total Jobs Posted & Total Shift Spend.
- Actions: "Inspect Profile", "Toggle Verification", "Suspend Business".
```

### Screen ADM-07: Master Jobs Explorer
```
Prompt:
Comprehensive audit log of all jobs posted on the platform.
Filter Toolbar: Status dropdown (Draft, Pending Approval, Published, Filled, In Progress, Completed, Cancelled, Rejected), Date range picker.
Data Grid:
- Job ID (short UUID).
- Business Name.
- Title & Category.
- Shift Date & Timings.
- Quota: Confirmed / Needed (e.g., "10 / 10" with progress bar).
- Total Shift Wage (INR).
- Status Badge with color-coded pill.
- Action: "View Shift Details & Attendance".
```

### Screen ADM-08: Bookings & On-Site Attendance Audit
```
Prompt:
Audit interface tracking physical worker attendance at Ghazipur venues.
Header: "Shift Attendance & Booking Audit".
Filters: Date filter, Venue selector, Status (Confirmed, Checked-In, No-Show, Completed).
Data Grid:
- Booking Reference ID.
- Job Title & Venue Name.
- Worker Name & Phone.
- 4-Digit Check-In Code (e.g., "7429").
- Check-In Timestamp (e.g., "05:42 PM by Rajwada Lawn").
- Status: Emerald badge "CHECKED IN", Yellow "PENDING ARRIVAL", or Red "NO SHOW".
```

### Screen ADM-09: Category & Skills Taxonomy Settings
```
Prompt:
Administrative configuration screen for managing platform taxonomies.
Header: "Worker Categories & Standard Skills".
Layout:
- Left Column: List of Categories (Waiters, Cleaners, Halwai Helpers, Loaders, Event Helpers) with "+ Add Category" button.
- Right Column: Micro-skills linked to the selected category (e.g., "Table Service", "Plate Clearing", "Vessel Scrubbing", "Chafing Dish Setup") with "+ Add Skill" button.
- Toggle: Active / Inactive switch per skill to control visibility in the mobile app.
```

### Screen ADM-10: Immutable Audit Log Ledger
```
Prompt:
Read-only compliance ledger recording every administrative mutation.
Header: "Administrative Audit Trail (Append-Only)".
Search: Filter by Admin operator, Target entity (jobs, businesses, users), Action type (approve_first_job, reject_first_job, suspend_user).
Data Table:
- Timestamp (ISO with local Ghazipur time).
- Admin Name & IP Address.
- Action Type Pill: "APPROVE_FIRST_JOB".
- Target: "Job #4982 (Rajwada Banquet)".
- Diff Viewer: Expandable JSON preview showing { "previous_state": "pending", "new_state": "published" }.
Notice: "Ledger is cryptographically protected against updates and deletions."
```
