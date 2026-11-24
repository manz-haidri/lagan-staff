# Google Stitch UI Prompts — Worker Mobile App (Flutter)

**Context:** Hyperlocal temporary gig worker marketplace in Ghazipur, Uttar Pradesh, India.  
**Form Factor:** Mobile portrait (390 x 844 px / iOS & Android).  
**Design Language:** Material 3, High-contrast accessibility, Deep Navy (`#1E3A8A`), Warm Amber (`#F59E0B`), Slate 50 background (`#F8FAFC`).  
**Language:** Bilingual (English + Hindi Devanagari).  

---

### Screen W-01: Splash Screen
```
Prompt:
A modern mobile splash screen for a hyperlocal workforce app named "LaganStaff" (लगनस्टाफ).
Background: Deep indigo blue (#1E3A8A).
Center: Prominent rounded badge icon with stylized handshake/staff icon in warm amber gold (#F59E0B).
Typography: Bold modern sans-serif white text "LaganStaff" with a sub-label in Hindi "गाजीपुर स्टाफिंग नेटवर्क" (Ghazipur Staffing Network).
Bottom: Sleek circular progress indicator in white with 50% opacity and version tag "v1.0.0". Minimalist, clean, trustworthy.
```

### Screen W-02: Welcome / Language Selection
```
Prompt:
Mobile onboarding screen welcoming temporary workers to LaganStaff in Ghazipur.
Top: Clean illustration of local workers (caterer, waiter in uniform, decorator) standing together with cheerful expressions.
Header: "Find Event & Catering Work Daily" / "शादी-विवाह और आयोजनों में रोज़गार पाएं".
Center: Language selection radio cards: "हिन्दी (Hindi)" with pre-selected green checkmark, and "English".
Bottom: Full-width elevated button with rounded corners (height 54dp, color #1E3A8A, white text): "आगे बढ़ें (Get Started)".
```

### Screen W-03: Mobile & 4-Digit PIN Login
```
Prompt:
Ultra-clean mobile login screen designed for Tier-3 Indian city workers.
Header: "अपना मोबाइल नंबर दर्ज करें" (Enter your mobile number) with subtext "त्वरित लॉगिन: कोई SMS प्रतीक्षा नहीं" (Instant login: No SMS wait).
Input 1: 10-digit phone number text field with Indian flag emoji 🇮🇳, "+91" prefix, and clean outline.
Input 2: 4-digit security PIN input with 4 discrete numeric boxes or password field with show/hide eye icon.
Mode Toggle: Pill switch at top toggling between "लॉगिन (Log In)" and "नया खाता बनाएं (New Account)".
Bottom: Primary action button (#1E3A8A): "लॉगिन करें (Continue)".
Footer info card: Small icon with yellow lightning bolt: "याद रखें: अपना 4-अंकों का पिन हमेशा सुरक्षित रखें।"
```

### Screen W-04: Role Selection
```
Prompt:
Role selection screen with two large interactive cards.
Header: "आप क्या करना चाहते हैं?" (What is your goal today?).
Card 1 (Worker): Left icon of waiter tray & tools, bold title "काम करने वाला (Worker)", description "वेटर, कैटरिंग हेल्पर, सफाईकर्मी का काम खोजें", border in #1E3A8A.
Card 2 (Business Owner): Left icon of marriage lawn / store, bold title "मालिक / व्यापारी (Business Owner)", description "शादी-समारोह के लिए तुरंत स्टाफ बुक करें", border in #CBD5E1.
Each card has a subtle arrow icon indicating progression.
```

### Screen W-05: Worker Profile Setup
```
Prompt:
Step 1 of 4 in Worker Registration.
Top: Progress bar indicating Step 1 of 4 (25% filled).
Title: "व्यक्तिगत जानकारी (Personal Profile)".
Form Fields:
- Full Name ("पूरा नाम") text input.
- Gender selector: Horizontal chips for "पुरुष (Male)", "महिला (Female)", "अन्य (Other)".
- Date of Birth / Age picker.
- Locality dropdown/search pre-populated with Ghazipur blocks: "लंका (Lanka)", "महुआबाग (Mahuabagh)", "गाजीपुर सिटी (Ghazipur City)", "जमानिया (Zamania)", "मुहम्मदाबाद (Mohammadabad)".
Bottom Bar: Sticky elevated button "आगे बढ़ें (Next Step)".
```

### Screen W-06: Skills & Categories Selection
```
Prompt:
Step 2 of 4 in Worker Registration.
Title: "अपने काम के हुनर चुनें (Select Your Skills)".
Subtitle: "आप जिस काम में माहिर हैं उसे चुनें (Select all that apply)".
Grid of selectable multi-tag cards with icons:
1. "वेटर / टेबल सर्विस (Waiter)" - Food platter icon.
2. "हलवाई सहायक (Halwai Helper)" - Cooking vessel icon.
3. "सफाईकर्मी (Housekeeping/Cleaner)" - Broom/Sparkle icon.
4. "टेंट व लाइट मजदूर (Tent/Loader)" - Tent/Truck icon.
5. "इवेंट हेल्पर (Event Helper)" - Checklist icon.
Selected cards have a vibrant blue border (#1E3A8A), light blue background fill (#EFF6FF), and green checkmark.
Bottom sticky button: "हुनर सुरक्षित करें (Save & Continue)".
```

### Screen W-07: Location Setup
```
Prompt:
Step 3 of 4 in Worker Registration.
Title: "आपकी कार्य क्षेत्र स्थिति (Work Location)".
Center: Illustrated map pin hovering over Ghazipur district map graphic.
Text Card: "गाजीपुर और आसपास के 15 किमी क्षेत्र के काम पाने के लिए लोकेशन अनुमति दें।" (Grant location to discover jobs within 15km).
Large button with GPS crosshair icon: "वर्तमान स्थान का उपयोग करें (Use Current GPS Location)".
Alternative: Manual text search box for landmark/locality in Ghazipur.
Bottom button: "जारी रखें (Continue)".
```

### Screen W-08: Selfie Capture & Instant Activation
```
Prompt:
Step 4 of 4 in Worker Registration.
Title: "एक सेल्फी फोटो लें (Take a Live Selfie)".
Subtitle: "मालिकों को आपकी पहचान दिखाने के लिए अपनी स्पष्ट फोटो खींचें।" (For your profile badge).
Center: Large circular camera viewport with subtle green facial alignment guide oval.
Capture button: Round camera shutter button with yellow ring (#F59E0B).
Post-capture preview: Shows photo with "आकार: 85 KB (संपीड़ित)" (Compressed: <100KB).
Status Banner: "तुरंत सक्रियता: फोटो अपलोड होते ही आपका खाता सक्रिय हो जाएगा।" (Immediate auto-activation).
Bottom button: "फोटो अपलोड करें और काम शुरू करें (Upload & Activate)".
```

### Screen W-09: Worker Home Dashboard
```
Prompt:
Main home screen for an active worker in Ghazipur.
Top Bar: Greeting "नमस्ते, राहुल जी" with active green dot badge "सक्रिय खाता (Active)".
Notification & Duty Pass quick shortcuts.
Hero Card (Shift Summary): Gradient card showing "अगला काम (Next Shift): कल, शाम 6:00 बजे | राजवाड़ा मैरिज लॉन | ₹650".
Section 1: Quick filter chips ("सभी काम", "वेटर", "हलवाई", "आज रात").
Section 2: "उपलब्ध नौकरियां (Available Jobs Near You)" showing top 3 urgent job cards with date, pay, and distance (e.g. "2.4 km").
Bottom Navigation Bar: 4 items (होम / Home, नौकरियां / Jobs, मेरे आवेदन / Applications, प्रोफाइल / Profile).
```

### Screen W-10: Job Listing Feed
```
Prompt:
Searchable, filterable list of temporary work shifts.
Top: Search bar "लॉन, होटल या कैटरिंग खोजें..." with Filter icon.
Filter Chips: "गाजीपुर सिटी", "आज के काम", "₹500+", "वेटर".
Job Card Item:
- Header: "वेटर की आवश्यकता (10 पद)" - Badge: "तत्काल (Urgent)".
- Business Name: "शाही दावत कैटरर्स • लंका, गाजीपुर".
- Metadata row: 📅 24 नवम्बर (कल) | ⏰ शाम 5:00 - रात 12:00 | 📍 3.2 किमी दूर.
- Pay tag: "₹700 / शिफ्ट" in bold green (#10B981).
- Action: "आवेदन करें (Apply Now)" button on right.
```

### Screen W-11: Job Details Sheet
```
Prompt:
Comprehensive details sheet for an event shift.
Header: Job Title "8 वेटर्स (शादी समारोह)", Business "रॉयल मैरिज पैलेस, तुलसी सागर".
Pay Highlight Box: Green container highlighting "वेतन: ₹650 / शिफ्ट" + "नगद भुगतान (End of shift cash/UPI)".
Details Grid:
- रिपोर्टिंग समय (Reporting Time): 24 Nov 2026, 05:00 PM.
- कार्य स्थल (Venue): Royal Marriage Palace, GT Road, Ghazipur.
- पोशाक (Dress Code): "काली पैंट और सफेद शर्ट (Black Trouser & White Shirt)".
- रिक्त स्थान (Slots Remaining): "10 में से 4 स्थान बाकी (4 of 10 slots left)".
Bottom Floating Bar: Full-width elevated button "तुरंत आवेदन करें (Apply Now - 1 Tap)".
```

### Screen W-12: My Applications Screen
```
Prompt:
Screen tracking worker's submitted job applications.
Top Tab Bar: "सक्रिय (Applied - 2)", "स्वीकृत (Accepted - 1)", "समाप्त (History)".
Applied Card: Shows job title, date, yellow clock icon "मालिक की समीक्षा प्रतीक्षित (Pending Owner Review)".
Accepted Card: Bright emerald green card with checkmark "स्वीकृत! ड्यूटी पास तैयार है (Accepted! View Duty Pass)".
Rejected Card: Subtle gray container with gentle note "मालिक ने अन्य उम्मीदवार चुना (Slot Filled)".
```

### Screen W-13: My Bookings & Duty Pass (With 4-Digit Check-in Code)
```
Prompt:
Official mobile Duty Pass for a confirmed gig shift in Ghazipur.
Design: Ticket/boarding pass aesthetic with dotted tear-line dividers.
Header: "LaganStaff आधिकारिक ड्यूटी पास (Duty Pass)".
Prominent Feature: Large yellow golden card in center featuring:
- "गेट चेक-इन कोड (Gate Check-In PIN):"
- Huge bold 4-digit code: " 7 4 2 9 "
- Instruction: "मैरिज हॉल गेट पर मालिक को यह कोड बताएं।" (Show this 4-digit code to the owner at the hall entrance to mark attendance).
Shift Details:
- लॉन: "राजवाड़ा मैरिज लॉन, गाजीपुर".
- समय: 24 नवम्बर, शाम 6:00 बजे.
- वेतन: ₹650 (स्वीकृत).
Bottom Action: "गूगल मैप पर रास्ता देखें (Open Map Directions)" and "मालिक को कॉल करें (Call Owner)".
```

### Screen W-14: Worker Profile & Earnings History
```
Prompt:
Worker profile management screen.
Top: Verified circular selfie photo with green badge "खाता सक्रिय (Active Worker)".
Name: "राहुल कुमार" | Phone: "+91 98765 43210" | Locality: "गाजीपुर सदर".
Stats Row:
- 14 शिफ्ट पूर्ण (14 Shifts Completed).
- ₹9,800 कुल कमाई (Total Earned).
- 100% उपस्थिति (100% Attendance Rate).
Options List:
- मेरे हुनर बदलें (Edit Skills).
- सुरक्षा पिन बदलें (Change 4-Digit PIN).
- सहायता व हेल्पलाइन (Help & Support).
- लॉग आउट (Logout).
```
