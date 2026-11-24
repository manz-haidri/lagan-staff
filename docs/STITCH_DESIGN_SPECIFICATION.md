# LaganStaff — Google Stitch UI Design Specification

**Document Version:** 1.0.0  
**Status:** Approved for Phase 1 Design  
**Target Market:** Ghazipur, Uttar Pradesh, India (Tier-3 Hyperlocal Context)  
**Tools Target:** Google Stitch (Prompt-Based UI Generation & Figma/SVG Export)  

---

## 1. Regional Design Philosophy & Accessibility

LaganStaff caters to a dual user base in Ghazipur:
1. **Gig Workers:** Young and middle-aged daily-wage workers operating budget Android devices (2GB–4GB RAM, 720p screens), outdoors or in dimly lit banquet halls, with varied literacy levels.
2. **Business Owners:** Marriage lawn, catering, and tent house managers operating mid-range devices under high operational stress during peak wedding hours.
3. **Administrators:** Desktop web users reviewing moderation queues quickly and accurately.

### Core Design Pillars:
- **Maximum Contrast & Sunlight Readability:** High-contrast color pairings conforming to WCAG 2.1 AA (4.5:1 ratio minimum).
- **Finger-Friendly Touch Targets:** All interactive buttons and cards have a minimum touch target of $48 \times 48\text{ dp}$ (primary action buttons are $52\text{ dp}$ to $56\text{ dp}$ tall).
- **Bilingual & Vernacular Clarity:** Every critical action and label is accompanied by simple Hindi (`देवनागरी`) and clear Hinglish text.
- **Cognitive Simplicity:** Zero nested menus or complex multi-tab gestures. One primary action per screen.

---

## 2. Global Design Tokens

### 2.1 Color Palette
```
Primary Brand:
  - Deep Navy / Indigo: #1E3A8A  (Authority, trust, stability)
  - Royal Blue:        #3B82F6  (Interactive links, active states)
  - Midnight Dark:     #172554  (Deep headers, primary text)

Accent & Event Vibes:
  - Wedding Amber:     #F59E0B  (Festive marigold, badges, highlights)
  - Soft Gold:         #FEF3C7  (Accent container backgrounds)

Functional & Status:
  - Success / Active:  #10B981  (Emerald green for confirmed shifts, approved jobs)
  - Error / Alert:     #EF4444  (Clear red for errors, rejections, cancellations)
  - Warning / Pending: #F59E0B  (Amber for pending review, waiting states)
  - Info / Hint:       #3B82F6  (Blue for informative banners)

Surfaces & Neutral Grays:
  - App Background:    #F8FAFC  (Slate 50 - clean, glare-reducing light background)
  - Surface Card:      #FFFFFF  (Pure white for elevated cards)
  - Muted Container:   #F1F5F9  (Slate 100 - secondary inputs, chips)
  - Border & Dividers: #E2E8F0  (Slate 200 - clean 1px borders)
  - Text Primary:      #0F172A  (Slate 900 - high contrast readability)
  - Text Secondary:    #475569  (Slate 600 - subheadings, instructions)
  - Text Muted:        #94A3B8  (Slate 400 - placeholders, hints)
```

### 2.2 Typography Scale (Inter / Poppins)
- **Display 1 (Splash/Hero):** 28sp / Bold (700) / Tracking -0.5px
- **Headline (Screen Titles):** 22sp / Semi-Bold (600)
- **Subhead (Section Headers):** 18sp / Semi-Bold (600)
- **Body Large (Primary Buttons / Input Text):** 16sp / Medium (500)
- **Body Medium (List details / descriptions):** 14sp / Regular (400)
- **Caption / Meta (Dates, wage units, badges):** 12sp / Medium (500)

---

## 3. Screen Inventory & Information Architecture

### A. Worker App (14 Screens)
1. **W-01: Splash Screen** — Deep navy branded background, gold logo, Ghazipur tagline.
2. **W-02: Welcome / Language Screen** — Introduction to LaganStaff with Hindi/English selector.
3. **W-03: Mobile & 4-Digit PIN Login** — 10-digit phone field (+91) with numeric 4-digit PIN input.
4. **W-04: Role Selection** — Large visual cards choosing between "Worker (काम करने वाला)" and "Owner (मालिक)".
5. **W-05: Worker Profile Setup** — Full name, gender, age/DOB, Ghazipur locality selection.
6. **W-06: Skills & Categories Selection** — Multi-select chips (Waiters, Cleaners, Halwai Helpers, Loaders).
7. **W-07: Location Permission Setup** — GPS capture with visual map pin and neighborhood text.
8. **W-08: Selfie Capture & Verification** — Circular camera preview, face alignment oval, instant preview & compression indicator ($< 100\text{ KB}$).
9. **W-09: Worker Home Dashboard** — Active status badge, shift summary, nearby jobs feed.
10. **W-10: Job Listing Feed** — Filterable list (Category, Locality, Wage) with clear INR per shift tags.
11. **W-11: Job Details Sheet** — Venue address, reporting time, dress code, total wage, "Apply Now" bottom bar.
12. **W-12: My Applications Screen** — Tabbed views (`Pending`, `Accepted`, `Rejected`) with status timelines.
13. **W-13: My Bookings & Duty Pass** — Confirmed shift pass displaying large 4-digit Check-In PIN (`checkin_code`), venue map link, owner contact.
14. **W-14: Worker Profile & History** — Personal details, completed shifts count, earnings summary, logout.

---

### B. Owner App (9 Screens)
1. **O-01: Owner Registration** — Contact name, phone (+91), 4-digit PIN setup.
2. **O-02: Business Profile Setup** — Business legal/trade name, category (Marriage Lawn, Catering, Tent House), Ghazipur address.
3. **O-03: Owner Dashboard** — First-job status banner (Pending Admin Approval / Verified), active job cards, applicant counts.
4. **O-04: Post New Job Form** — Category dropdown, shift date, timings, worker quota (e.g. 10 Waiters), pay rate (INR), instructions.
5. **O-05: Job Management Hub** — List of all posted jobs (Draft, Pending Approval, Published, Filled, Completed).
6. **O-06: Applicants Review List** — List of worker candidates with skills, locality, and "Accept" / "Reject" actions with remaining slot counter.
7. **O-07: Worker Details Modal** — Non-sensitive worker profile, past experience, locality.
8. **O-08: Booking & On-Site Gate Check-In** — Shift roster with **4-Digit Check-in PIN Input** to mark worker arrival at the venue gate.
9. **O-09: Business Profile & Settings** — Address update, contact phone, business status.

---

### C. Admin Web Dashboard (10 Screens)
1. **ADM-01: Admin Login** — Clean desktop authentication card with 2FA / secure credentials.
2. **ADM-02: Executive Operations Overview** — KPI tiles: Total Workers, Verified Businesses, Pending Approvals, Active Shifts Today.
3. **ADM-03: First-Job Approval Queue** — Priority table displaying newly submitted first jobs from unverified businesses with submission time.
4. **ADM-04: Job Details Moderation Review** — Side-by-side view of business details, venue address in Ghazipur, wage rate analysis, "Approve" (green) & "Reject with Reason" (red).
5. **ADM-05: Workers Management Directory** — Filterable data table of registered workers, verification status, selfie review modal, account suspend toggle.
6. **ADM-06: Owners Management Directory** — Registered owners, linked businesses, verification status.
7. **ADM-07: Businesses Management Table** — Trade name, category, first-job approved status badge, location coordinates.
8. **ADM-08: Master Jobs Explorer** — Complete searchable history of all platform jobs across all lifecycle states.
9. **ADM-09: Bookings & Attendance Audit** — Historical log of confirmed bookings, check-in timestamps, no-shows.
10. **ADM-10: System Settings & Category Config** — Dynamic CRUD interface for job categories, skills, and admin audit log viewer.

---

## 4. Google Stitch Prompt Execution & Format

All detailed generation prompts are located in [docs/stitch-prompts/](file:///Users/samarborairabbas/Documents/Apps/Lagan%20Staff/docs/stitch-prompts/):
- `01_worker_app_prompts.md`
- `02_owner_app_prompts.md`
- `03_admin_dashboard_prompts.md`

> [!NOTE]
> **Status Disclosure:**  
> The design prompts are fully specified and ready for generation in Google Stitch. In accordance with strict Phase 1 compliance rules, no claim of pre-existing Stitch vector exports is made until actual exports are ingested into the repository.
