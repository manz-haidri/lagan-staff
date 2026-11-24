# Google Stitch UI Prompts — Owner Mobile App (Flutter)

**Context:** Business Owner interface for Marriage Lawns, Caterers, Tent Houses in Ghazipur.  
**Form Factor:** Mobile portrait (390 x 844 px / iOS & Android).  
**Design Language:** Material 3, Professional Business UI, Deep Navy (`#1E3A8A`), Warm Marigold (`#F59E0B`), Emerald (`#10B981`).  
**Language:** Bilingual (English + Hindi).  

---

### Screen O-01: Owner Registration & Profile
```
Prompt:
Mobile onboarding screen for business owners and banquet managers in Ghazipur.
Header: "व्यापारी खाता बनाएं (Business Owner Registration)".
Subtitle: "मैरिज हॉल, कैटरिंग व टेंट हाउस के लिए स्टाफ की बुकिंग करें।"
Fields:
- Contact Person Name ("मालिक / प्रबंधक का नाम").
- Mobile Number ("मोबाइल नंबर") with 🇮🇳 +91.
- 4-Digit Security PIN ("4-अंकों का सुरक्षा पिन").
- Confirm PIN ("पिन की पुष्टि करें").
Bottom Button: "आगे बढ़ें (Continue to Business Setup)".
```

### Screen O-02: Business Profile Setup
```
Prompt:
Setup screen for entering business details.
Title: "व्यापार की जानकारी (Business Profile)".
Fields:
- Business Legal / Trade Name ("प्रतिष्ठान / मैरिज लॉन का नाम", e.g. "राजवाड़ा मैरिज लॉन").
- Category Selection: Horizontal radio chips ("मैरिज हॉल / लॉन", "कैटरिंग सर्विस", "टेंट हाउस", "इवेंट आयोजक").
- Physical Address ("विस्तृत पता"): Text box.
- Locality Dropdown: Ghazipur blocks (Lanka, Mahuabagh, City, etc.).
- Optional: GST / Trade License Number ("जीएसटी नंबर - यदि हो तो").
Bottom Button: "प्रोफाइल सुरक्षित करें और डैशबोर्ड खोलें (Save & Enter Dashboard)".
```

### Screen O-03: Owner Dashboard
```
Prompt:
Comprehensive mobile dashboard for an event business owner.
Top: Business name "राजवाड़ा मैरिज लॉन" with verification status badge:
- If First-Job Pending: Yellow banner "पहला काम समीक्षाधीन है (First Job Awaiting Admin Review)".
- If Verified: Green badge "प्रमाणित प्रतिष्ठान (Verified Business - Auto-Publish Active)".
KPI Grid (2x2):
- सक्रिय नौकरियां (Active Jobs): "2"
- प्राप्त आवेदन (Applications): "18"
- आज के कार्यकर्ता (Workers Today): "8"
- कुल खर्च (Staff Budget): "₹5,200"
Main Action Card: Big floating button (#1E3A8A) with plus icon: "नई नौकरी पोस्ट करें (Post New Staff Requirement)".
Recent Jobs List: Preview cards of posted jobs with applicant counter badges.
Bottom Nav: 4 items (डैशबोर्ड / Dashboard, नौकरियां / Jobs, स्टाफ उपस्थिति / Attendance, प्रोफाइल / Profile).
```

### Screen O-04: Post New Job Form
```
Prompt:
Clean, structured form for hiring temporary event staff.
Header: "स्टाफ की आवश्यकता पोस्ट करें (Post Job Requirement)".
Form Fields:
1. Category Dropdown: "वेटर / टेबल सर्विस" (or Cleaners, Halwai Helper, Loaders).
2. Number of Workers Required: Stepper counter (- [ 10 ] +) with label "कुल कार्यकर्ता संख्या".
3. Shift Date: Calendar picker (e.g. "24 नवम्बर 2026").
4. Timing: Start Time ("05:00 PM") and End Time ("12:00 AM midnight").
5. Wage Rate: Numeric input "₹ [ 650 ] प्रति व्यक्ति / प्रति शिफ्ट".
6. Reporting Address: Pre-filled with business address + option to change venue.
7. Special Instructions: Text field ("काली पैंट व सफेद शर्ट अनिवार्य, समय पर रिपोर्टिंग").
Notice Box: "नोट: आपके प्रतिष्ठान का पहला काम एडमिन जांच के बाद 30 मिनट में लाइव होगा।" (First-job moderation notice).
Bottom Button: "नौकरी प्रकाशित करें (Submit Job Posting)".
```

### Screen O-05: Job Management Hub
```
Prompt:
Screen listing all jobs created by this business owner.
Filter Tabs: "सक्रिय (Active)", "प्रतीक्षारत (Pending Review)", "पूर्ण (Completed)", "रद्द (Cancelled)".
Job Card Content:
- Title: "10 वेटर्स की आवश्यकता (Wedding Banquet)".
- Shift Date & Time: "कल, शाम 5:00 बजे".
- Capacity Progress Bar: "7/10 स्लॉट भर गए (7 of 10 workers confirmed)".
- Status Badge: Green "लाइव (Published)" or Yellow "एडमिन समीक्षाधीन (Pending Approval)".
- Buttons on Card: "आवेदन देखें (View 15 Applicants)" and "विवरण (Edit/Details)".
```

### Screen O-06: Applicants Review List & Capacity Enforcement
```
Prompt:
Screen where the business owner selects and accepts applicants.
Header: "आवेदन सूची: 10 वेटर्स (15 कुल आवेदन)".
Capacity Banner: Top sticky card showing "पुष्ट कार्यकर्ता: 7 / 10 | 3 स्लॉट शेष" (Remaining slots counter).
Worker Applicant Card:
- Left: Verified selfie thumbnail of worker with name "मनोज यादव" & locality "महुआबाग (2.1 km)".
- Subtitle: "अनुभव: 3 वर्ष • 18 शिफ्ट पूरी • 5★ रेटिंग".
- Action Buttons:
  - Red outlined button: "अस्वीकार (Reject)".
  - Green elevated button (#10B981): "स्वीकार करें (Accept & Book)".
Notice: When capacity reaches 10/10, unaccepted cards auto-lock with message "स्लॉट पूर्ण (Capacity Reached)".
```

### Screen O-07: Worker Details Modal
```
Prompt:
Detailed modal sheet showing applicant credentials to the owner.
Top: Worker name "सुरेश कुमार" with verified checkmark and locality in Ghazipur.
Experience Tags: "टेबल सर्विस (Table Service)", "बफे काउंटर (Buffet Management)", "अनुशासित (Punctual)".
Work History: "LaganStaff पर 12 सफल शिफ्ट में काम किया".
Owner Note: "कोई अग्रिम भुगतान आवश्यक नहीं है। काम समाप्ति पर भुगतान करें।"
Action: "इस कार्यकर्ता को चुनें (Confirm Booking for ₹650)".
```

### Screen O-08: On-Site Gate Check-In & Attendance Verification
```
Prompt:
Mobile attendance screen used by banquet owner at the marriage lawn entrance gate.
Header: "गेट उपस्थिति सत्यापन (Gate Check-In)".
Subtitle: "राजवाड़ा लॉन • आज रात की शिफ्ट (8 कार्यकर्ता पुष्ट)".
Interactive Input Box:
- Prominent 4-digit numeric code entry field: "[ _ ] [ _ ] [ _ ] [ _ ]".
- Button: "उपस्थिति दर्ज करें (Verify & Check-In)".
- Explanation: "कार्यकर्ता के ड्यूटी पास पर दिखाया गया 4-अंकों का कोड दर्ज करें।" (Enter the 4-digit code shown on the worker's phone).
Below Input: Live attendance roster table:
- "राहुल कुमार" - [ उपस्थित (Checked In 05:42 PM) ] (Green badge).
- "सोनू वर्मा" - [ कोड प्रतीक्षित (Awaiting PIN) ] (Yellow badge).
- "अमित सिंह" - [ कोड प्रतीक्षित (Awaiting PIN) ] (Yellow badge).
Bottom Summary: "5 / 8 कार्यकर्ता गेट पर पहुंच चुके हैं।"
```

### Screen O-09: Business Profile & Settings
```
Prompt:
Owner settings and business profile details.
Header: "राजवाड़ा मैरिज लॉन (Rajwada Marriage Lawn)".
Details: Contact Person "आलोक सिंह", Phone "+91 98765 12345", City "गाजीपुर (उ.प्र.)".
Verification Status: "प्रमाणित खाता (Verified - Auto-Publish Enabled)".
Actions:
- प्रतिष्ठान विवरण संपादित करें (Edit Business Details).
- सुरक्षा पिन बदलें (Change 4-Digit PIN).
- सहायता व कस्टमर केयर (Support Hotline).
- लॉग आउट (Sign Out).
```
