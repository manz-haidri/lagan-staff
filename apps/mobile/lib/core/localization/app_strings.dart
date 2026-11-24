import 'app_language.dart';

export 'app_language.dart';
export 'language_provider.dart';
export 'language_selector_widget.dart';

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  // ==========================================
  // App General & Common Actions
  // ==========================================
  String get appTitle => 'LaganStaff';

  String get loading => switch (language) {
        AppLanguage.hindi => 'लोड हो रहा है...',
        AppLanguage.hinglish => 'Loading...',
        AppLanguage.english => 'Loading...',
      };

  String get workerRole => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ता',
        AppLanguage.hinglish => 'Worker',
        AppLanguage.english => 'Worker',
      };

  String get ownerRole => switch (language) {
        AppLanguage.hindi => 'मालिक',
        AppLanguage.hinglish => 'Owner',
        AppLanguage.english => 'Owner',
      };

  String get shiftWageLabel => switch (language) {
        AppLanguage.hindi => 'मानदेय:',
        AppLanguage.hinglish => 'Wage:',
        AppLanguage.english => 'Wage:',
      };

  String get statusCompleted => switch (language) {
        AppLanguage.hindi => 'संपन्न',
        AppLanguage.hinglish => 'Completed',
        AppLanguage.english => 'Completed',
      };

  String get statusPresent => switch (language) {
        AppLanguage.hindi => 'उपस्थित',
        AppLanguage.hinglish => 'Present',
        AppLanguage.english => 'Present',
      };

  String get statusCheckedIn => switch (language) {
        AppLanguage.hindi => 'चेक-इन',
        AppLanguage.hinglish => 'Checked In',
        AppLanguage.english => 'Checked In',
      };

  String get statusConfirmed => switch (language) {
        AppLanguage.hindi => 'पुष्ट',
        AppLanguage.hinglish => 'Confirmed',
        AppLanguage.english => 'Confirmed',
      };

  String get expiredStatus => switch (language) {
        AppLanguage.hindi => 'समाप्त',
        AppLanguage.hinglish => 'Expired',
        AppLanguage.english => 'Expired',
      };

  String get appTagline => switch (language) {
        AppLanguage.hindi => 'गाजीपुर इवेंट वर्कफोर्स नेटवर्क',
        AppLanguage.hinglish => 'Ghazipur Event Workforce Network',
        AppLanguage.english => 'Ghazipur Event Workforce Network',
      };

  String get languageTitle => switch (language) {
        AppLanguage.hindi => 'भाषा',
        AppLanguage.hinglish => 'Bhasha',
        AppLanguage.english => 'Language',
      };

  String get selectLanguage => switch (language) {
        AppLanguage.hindi => 'भाषा चुनें',
        AppLanguage.hinglish => 'Bhasha Chunein',
        AppLanguage.english => 'Select Language',
      };

  String get chooseLanguageHeading => switch (language) {
        AppLanguage.hindi => 'भाषा चुनें',
        AppLanguage.hinglish => 'Choose Language / भाषा चुनें',
        AppLanguage.english => 'Choose Language',
      };

  String get chooseLanguageSubheading => switch (language) {
        AppLanguage.hindi => 'अपनी पसंदीदा भाषा चुनें',
        AppLanguage.hinglish => 'Apni preferred language select karein',
        AppLanguage.english => 'Select your preferred display language',
      };

  String get signOut => switch (language) {
        AppLanguage.hindi => 'लॉग आउट',
        AppLanguage.hinglish => 'Log Out',
        AppLanguage.english => 'Sign Out',
      };

  String get signOutButton => signOut;

  String get ownerDashboardTitle => switch (language) {
        AppLanguage.hindi => 'व्यापार डैशबोर्ड',
        AppLanguage.hinglish => 'Business Dashboard',
        AppLanguage.english => 'Business Dashboard',
      };

  String get notifications => switch (language) {
        AppLanguage.hindi => 'सूचनाएं',
        AppLanguage.hinglish => 'Notifications',
        AppLanguage.english => 'Notifications',
      };

  String get refresh => switch (language) {
        AppLanguage.hindi => 'रिफ्रेश करें',
        AppLanguage.hinglish => 'Refresh Karein',
        AppLanguage.english => 'Refresh',
      };

  String get retry => switch (language) {
        AppLanguage.hindi => 'पुनः प्रयास करें',
        AppLanguage.hinglish => 'Dobara Try Karein',
        AppLanguage.english => 'Retry',
      };

  String get cancel => switch (language) {
        AppLanguage.hindi => 'रद्द करें',
        AppLanguage.hinglish => 'Cancel',
        AppLanguage.english => 'Cancel',
      };

  String get back => switch (language) {
        AppLanguage.hindi => 'वापस',
        AppLanguage.hinglish => 'Back',
        AppLanguage.english => 'Back',
      };

  String get save => switch (language) {
        AppLanguage.hindi => 'सुरक्षित करें',
        AppLanguage.hinglish => 'Save Karein',
        AppLanguage.english => 'Save',
      };

  String get edit => switch (language) {
        AppLanguage.hindi => 'संपादित करें',
        AppLanguage.hinglish => 'Edit Karein',
        AppLanguage.english => 'Edit',
      };

  String get close => switch (language) {
        AppLanguage.hindi => 'बंद करें',
        AppLanguage.hinglish => 'Close Karein',
        AppLanguage.english => 'Close',
      };

  String get errorPrefix => switch (language) {
        AppLanguage.hindi => 'त्रुटि: ',
        AppLanguage.hinglish => 'Error: ',
        AppLanguage.english => 'Error: ',
      };

  String get somethingWentWrong => switch (language) {
        AppLanguage.hindi => 'कुछ गलत हो गया',
        AppLanguage.hinglish => 'Kuch galat ho gaya',
        AppLanguage.english => 'Something went wrong',
      };

  // ==========================================
  // Auth / Login
  // ==========================================
  String get enterMobileNumber => switch (language) {
        AppLanguage.hindi => 'मोबाइल नंबर दर्ज करें',
        AppLanguage.hinglish => 'Mobile Number Dalein',
        AppLanguage.english => 'Enter Mobile Number',
      };

  String get sendOtpSubtitle => switch (language) {
        AppLanguage.hindi => 'सत्यापन के लिए हम 6-अंकों का OTP भेजेंगे।',
        AppLanguage.hinglish => 'Verification ke liye hum 6-digit OTP bhejenge.',
        AppLanguage.english => 'We will send a 6-digit OTP for verification.',
      };

  String get sendOtpButton => switch (language) {
        AppLanguage.hindi => 'OTP प्राप्त करें',
        AppLanguage.hinglish => 'OTP Bhejein',
        AppLanguage.english => 'Send OTP',
      };

  String get testModeCardTitle => switch (language) {
        AppLanguage.hindi => 'टेस्ट नंबर: 9876543210\n(OTP: 123456)',
        AppLanguage.hinglish => 'Test Number: 9876543210\n(OTP: 123456)',
        AppLanguage.english => 'Test Number: 9876543210\n(OTP: 123456)',
      };

  String get autoFillAndSend => switch (language) {
        AppLanguage.hindi => 'ऑटो-भरें व भेजें',
        AppLanguage.hinglish => 'Auto-fill & Bhejein',
        AppLanguage.english => 'Auto-fill & Send',
      };

  String get loginTrustNote => switch (language) {
        AppLanguage.hindi =>
          'गाजीपुर के मैरिज हॉल, कैटरिंग व टेंट हाउस के लिए सुरक्षित मंच',
        AppLanguage.hinglish =>
          'Ghazipur ke Marriage Hall, Catering aur Tent House ke liye trusted platform',
        AppLanguage.english =>
          'Trusted workforce platform for Marriage Halls, Caterers & Event Staff',
      };

  // ==========================================
  // OTP Verification
  // ==========================================
  String get otpVerificationTitle => switch (language) {
        AppLanguage.hindi => 'OTP सत्यापन',
        AppLanguage.hinglish => 'OTP Verification',
        AppLanguage.english => 'OTP Verification',
      };

  String get enterSixDigitOtp => switch (language) {
        AppLanguage.hindi => '6-अंकों का OTP दर्ज करें',
        AppLanguage.hinglish => '6-Digit OTP Dalein',
        AppLanguage.english => 'Enter 6-Digit OTP',
      };

  String verificationCodeSentTo(String phone) => switch (language) {
        AppLanguage.hindi => 'इस नंबर पर भेजा गया कोड दर्ज करें: $phone',
        AppLanguage.hinglish => 'Is number par bheja gaya code dalein: $phone',
        AppLanguage.english => 'Enter the verification code sent to $phone',
      };

  String get autoFill => switch (language) {
        AppLanguage.hindi => 'ऑटो-भरें',
        AppLanguage.hinglish => 'Auto-fill',
        AppLanguage.english => 'Auto-fill',
      };

  String get verifyAndContinue => switch (language) {
        AppLanguage.hindi => 'सत्यापित करें और आगे बढ़ें',
        AppLanguage.hinglish => 'Verify Karein & Aage Badhein',
        AppLanguage.english => 'Verify & Continue',
      };

  String resendOtpIn(int seconds) => switch (language) {
        AppLanguage.hindi => 'पुनः OTP भेजें ($seconds सेकंड में)',
        AppLanguage.hinglish => 'OTP dobara bhejein ($seconds sec)',
        AppLanguage.english => 'Resend OTP in ${seconds}s',
      };

  String get resendOtp => switch (language) {
        AppLanguage.hindi => 'पुनः OTP भेजें',
        AppLanguage.hinglish => 'OTP Dobara Bhejein',
        AppLanguage.english => 'Resend OTP',
      };

  String get changePhoneNumber => switch (language) {
        AppLanguage.hindi => 'मोबाइल नंबर बदलें',
        AppLanguage.hinglish => 'Phone Number Badlein',
        AppLanguage.english => 'Change Phone Number',
      };

  // ==========================================
  // Role Selection
  // ==========================================
  String get accountTypeTitle => switch (language) {
        AppLanguage.hindi => 'खाता प्रकार',
        AppLanguage.hinglish => 'Account Type',
        AppLanguage.english => 'Account Type',
      };

  String verifiedMobile(String phone) => switch (language) {
        AppLanguage.hindi => 'सत्यापित मोबाइल: $phone',
        AppLanguage.hinglish => 'Verified Mobile: $phone',
        AppLanguage.english => 'Verified Mobile: $phone',
      };

  String get chooseYourRole => switch (language) {
        AppLanguage.hindi => 'अपनी भूमिका चुनें',
        AppLanguage.hinglish => 'Apna Role Chunein',
        AppLanguage.english => 'Choose Your Role',
      };

  String get roleSelectionSubtitle => switch (language) {
        AppLanguage.hindi =>
          'अपना नाम दर्ज करें और चुनें कि आप ऐप का उपयोग कैसे करना चाहते हैं।',
        AppLanguage.hinglish =>
          'Apna naam dalein aur chunein ki aap app kaise use karna chahte hain.',
        AppLanguage.english =>
          'Enter your name and select how you would like to use LaganStaff.',
      };

  String get fullNameLabel => switch (language) {
        AppLanguage.hindi => 'पूरा नाम',
        AppLanguage.hinglish => 'Poora Naam',
        AppLanguage.english => 'Full Name',
      };

  String get selectAccountType => switch (language) {
        AppLanguage.hindi => 'खाता प्रकार चुनें:',
        AppLanguage.hinglish => 'Account Type Chunein:',
        AppLanguage.english => 'Select Account Type:',
      };

  String get workerRoleTitle => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ता (वर्कर)',
        AppLanguage.hinglish => 'Worker (Kaam Karne Wale)',
        AppLanguage.english => 'Worker',
      };

  String get workerRoleDesc => switch (language) {
        AppLanguage.hindi =>
          'वेटर, रसोइया हेल्पर, सफाईकर्मी या टेंट सहायक के रूप में शिफ्ट कार्य खोजें।',
        AppLanguage.hinglish =>
          'Waiter, cook helper, cleaner, ya tent assistant ke roop mein shift kaam paayein.',
        AppLanguage.english =>
          'Find shift work as a waiter, cook helper, cleaner, or tent assistant.',
      };

  String get ownerRoleTitle => switch (language) {
        AppLanguage.hindi => 'व्यापारी / मालिक',
        AppLanguage.hinglish => 'Business Owner (Maalik)',
        AppLanguage.english => 'Business Owner',
      };

  String get ownerRoleDesc => switch (language) {
        AppLanguage.hindi =>
          'मैरिज हॉल, कैटरिंग और टेंट हाउस के लिए काम पोस्ट करें और स्टाफ रखें।',
        AppLanguage.hinglish =>
          'Marriage Halls, Catering aur Tent Houses ke liye kaam post karein aur staff hire karein.',
        AppLanguage.english =>
          'Post jobs & hire staff for Marriage Halls, Catering & Tent Houses.',
      };

  String get saveAndContinue => switch (language) {
        AppLanguage.hindi => 'सुरक्षित करें और आगे बढ़ें',
        AppLanguage.hinglish => 'Save Karein & Aage Badhein',
        AppLanguage.english => 'Save & Continue',
      };

  // ==========================================
  // Worker Dashboard / Home Screen
  // ==========================================
  String get workerDashboardTitle => switch (language) {
        AppLanguage.hindi => 'वर्कर डैशबोर्ड',
        AppLanguage.hinglish => 'Worker Dashboard',
        AppLanguage.english => 'Worker Dashboard',
      };

  String helloName(String name) => switch (language) {
        AppLanguage.hindi => 'नमस्ते, $name',
        AppLanguage.hinglish => 'Namaste, $name',
        AppLanguage.english => 'Hello, $name',
      };

  String get profileIncompleteBadge => switch (language) {
        AppLanguage.hindi => 'प्रोफाइल अधूरी',
        AppLanguage.hinglish => 'Profile Incomplete',
        AppLanguage.english => 'Profile Incomplete',
      };

  String get profileIncompleteDesc => switch (language) {
        AppLanguage.hindi =>
          'काम खोजने के लिए अपनी प्रोफाइल, कौशल (Skills) और लाइव सेल्फी पूरी करें। पूरा होते ही खाता तुरंत सक्रिय हो जाएगा।',
        AppLanguage.hinglish =>
          'Kaam paane ke liye apni profile, skills aur live selfie poori karein. Account turant active ho jayega.',
        AppLanguage.english =>
          'Complete your profile, skills, and live selfie to find jobs. Your account will be activated immediately.',
      };

  String get completeProfileButton => switch (language) {
        AppLanguage.hindi => 'प्रोफाइल पूरी करें',
        AppLanguage.hinglish => 'Profile Poori Karein',
        AppLanguage.english => 'Complete Profile',
      };

  String get upcomingBookings => switch (language) {
        AppLanguage.hindi => 'आगामी बुकिंग्स',
        AppLanguage.hinglish => 'Upcoming Bookings',
        AppLanguage.english => 'Upcoming Bookings',
      };

  String get workHistory => switch (language) {
        AppLanguage.hindi => 'कार्य इतिहास',
        AppLanguage.hinglish => 'Work History',
        AppLanguage.english => 'Work History',
      };

  String get availableJobsTitle => switch (language) {
        AppLanguage.hindi => 'गाजीपुर में उपलब्ध काम',
        AppLanguage.hinglish => 'Ghazipur Mein Available Kaam',
        AppLanguage.english => 'Available Job Shifts in Ghazipur',
      };

  String get filterAndSearch => switch (language) {
        AppLanguage.hindi => 'फ़िल्टर व खोज',
        AppLanguage.hinglish => 'Filter & Search',
        AppLanguage.english => 'Filter & Search',
      };

  String get noJobsAvailableTitle => switch (language) {
        AppLanguage.hindi => 'वर्तमान में कोई नया काम उपलब्ध नहीं है',
        AppLanguage.hinglish => 'Abhi koi naya kaam available nahi hai',
        AppLanguage.english => 'No new jobs available right now',
      };

  String get noJobsAvailableSubtext => switch (language) {
        AppLanguage.hindi =>
          'गाजीपुर के शादी लॉन और कैटरिंग मालिकों द्वारा नया काम पोस्ट होते ही यहाँ दिखाई देगा। कृपया थोड़ी देर बाद देखें।',
        AppLanguage.hinglish =>
          'Ghazipur ke marriage hall aur caterers jab kaam post karenge toh yahan dikhega. Thodi der baad check karein.',
        AppLanguage.english =>
          'Jobs posted by marriage halls and caterers in Ghazipur will appear here. Please check back shortly.',
      };

  String get myProfileTooltip => switch (language) {
        AppLanguage.hindi => 'मेरी प्रोफाइल',
        AppLanguage.hinglish => 'Meri Profile',
        AppLanguage.english => 'My Profile',
      };

  String get workerFooterNote => switch (language) {
        AppLanguage.hindi => 'LaganStaff • गाजीपुर वर्कर नेटवर्क',
        AppLanguage.hinglish => 'LaganStaff • Ghazipur Worker Network',
        AppLanguage.english => 'LaganStaff • Ghazipur Worker Network',
      };

  String get activeStatus => switch (language) {
        AppLanguage.hindi => 'सक्रिय',
        AppLanguage.hinglish => 'Active',
        AppLanguage.english => 'Active',
      };

  String get accountSuspendedTitle => switch (language) {
        AppLanguage.hindi => 'खाता निलंबित',
        AppLanguage.hinglish => 'Account Suspended',
        AppLanguage.english => 'Account Suspended',
      };

  String get accountSuspendedDesc => switch (language) {
        AppLanguage.hindi =>
          'व्यवस्थापक द्वारा आपका खाता अस्थायी रूप से निलंबित कर दिया गया है। सहायता के लिए लगनस्टाफ सहायता टीम से संपर्क करें।',
        AppLanguage.hinglish =>
          'Aapka account administrator dwaara temporarily suspend kar diya gaya hai. Madad ke liye LaganStaff support se contact karein.',
        AppLanguage.english =>
          'Your account has been temporarily suspended by the administrator. Contact LaganStaff support for assistance.',
      };

  String verifiedMobileAndArea(String phone, String locality) =>
      switch (language) {
        AppLanguage.hindi =>
          'सत्यापित मोबाइल: +91 $phone • कार्यक्षेत्र: $locality, गाजीपुर',
        AppLanguage.hinglish =>
          'Verified Mobile: +91 $phone • Area: $locality, Ghazipur',
        AppLanguage.english =>
          'Verified Mobile: +91 $phone • Area: $locality, Ghazipur',
      };

  String get checkingProfileStatus => switch (language) {
        AppLanguage.hindi => 'प्रोफाइल स्थिति जांची जा रही है...',
        AppLanguage.hinglish => 'Profile status check kiya ja raha hai...',
        AppLanguage.english => 'Checking profile status...',
      };

  // ==========================================
  // Worker Bookings Screen
  // ==========================================
  String get upcomingBookingsScreenTitle => switch (language) {
        AppLanguage.hindi => 'मेरी आगामी बुकिंग्स',
        AppLanguage.hinglish => 'Upcoming Bookings',
        AppLanguage.english => 'Upcoming Bookings',
      };

  String get noUpcomingBookingsTitle => switch (language) {
        AppLanguage.hindi => 'कोई आगामी बुकिंग नहीं है',
        AppLanguage.hinglish => 'Koi upcoming booking nahi hai',
        AppLanguage.english => 'No upcoming bookings',
      };

  String get noUpcomingBookingsDesc => switch (language) {
        AppLanguage.hindi =>
          'फिलहाल आपकी कोई शिफ्ट पुष्ट नहीं है। नए कार्य खोजें और आवेदन करें।',
        AppLanguage.hinglish =>
          'Filhaal aapki koi shift confirmed nahi hai. Naye kaam dekhein aur apply karein.',
        AppLanguage.english =>
          'You currently have no confirmed shifts. Discover available jobs and apply.',
      };

  String get viewAvailableJobsAction => switch (language) {
        AppLanguage.hindi => 'उपलब्ध कार्य देखें',
        AppLanguage.hinglish => 'Available Jobs Dekhein',
        AppLanguage.english => 'View Available Jobs',
      };

  String get checkInSuccessMessage => switch (language) {
        AppLanguage.hindi =>
          'चेक-इन सफलतापूर्वक दर्ज हुआ! आयोजक को आपकी उपस्थिति दिखाई दे रही है।',
        AppLanguage.hinglish =>
          'Check-in successfully complete! Host ko aapki attendance dikh rahi hai.',
        AppLanguage.english =>
          'Check-in successful! The event host can now see your attendance.',
      };

  String get cancelBookingDialogTitle => switch (language) {
        AppLanguage.hindi => 'बुकिंग रद्द करें?',
        AppLanguage.hinglish => 'Booking Cancel Karein?',
        AppLanguage.english => 'Cancel Booking?',
      };

  String cancelBookingConfirmQuestion(String jobTitle) => switch (language) {
        AppLanguage.hindi =>
          'क्या आप "$jobTitle" की अपनी पुष्ट शिफ्ट रद्द करना चाहते हैं?',
        AppLanguage.hinglish =>
          'Kya aap "$jobTitle" ki confirmed shift cancel karna chahte hain?',
        AppLanguage.english =>
          'Are you sure you want to cancel your confirmed shift for "$jobTitle"?',
      };

  String get cancelBookingReasonLabel => switch (language) {
        AppLanguage.hindi => 'रद्द करने का कारण*',
        AppLanguage.hinglish => 'Cancel karne ka reason*',
        AppLanguage.english => 'Reason for cancellation*',
      };

  String get cancelBookingReasonHint => switch (language) {
        AppLanguage.hindi => 'उदा. स्वास्थ्य समस्या या आकस्मिक कार्य',
        AppLanguage.hinglish => 'E.g., Health issue ya emergency work',
        AppLanguage.english => 'E.g., Health issue or emergency',
      };

  String get cancelBookingReasonRequired => switch (language) {
        AppLanguage.hindi => 'रद्द करने का कारण दर्ज करना आवश्यक है।',
        AppLanguage.hinglish => 'Cancel karne ka reason likhna zaroori hai.',
        AppLanguage.english => 'Please provide a reason for cancellation.',
      };

  String get cancelBookingSuccess => switch (language) {
        AppLanguage.hindi => 'बुकिंग सफलतापूर्वक रद्द कर दी गई।',
        AppLanguage.hinglish => 'Booking successfully cancel kar di gayi.',
        AppLanguage.english => 'Booking cancelled successfully.',
      };

  String get yesCancel => switch (language) {
        AppLanguage.hindi => 'हाँ, रद्द करें',
        AppLanguage.hinglish => 'Haan, Cancel Karein',
        AppLanguage.english => 'Yes, Cancel',
      };

  String get checkInButton => switch (language) {
        AppLanguage.hindi => 'चेक-इन करें',
        AppLanguage.hinglish => 'Check In Karein',
        AppLanguage.english => 'Check In',
      };

  String get checkInAtVenue => switch (language) {
        AppLanguage.hindi => 'स्थल पर चेक-इन करें',
        AppLanguage.hinglish => 'Check In at Venue',
        AppLanguage.english => 'Check In at Venue',
      };

  String get checkInWindowWait => switch (language) {
        AppLanguage.hindi => 'चेक-इन (विंडो 2 घंटे पूर्व)',
        AppLanguage.hinglish => 'Check-in (Window 2h before)',
        AppLanguage.english => 'Check-in (Opens 2h before)',
      };

  String get cancelBookingButton => switch (language) {
        AppLanguage.hindi => 'शिफ्ट रद्द करें',
        AppLanguage.hinglish => 'Shift Cancel Karein',
        AppLanguage.english => 'Cancel Shift',
      };

  String get hostLabel => switch (language) {
        AppLanguage.hindi => 'आयोजक: ',
        AppLanguage.hinglish => 'Host: ',
        AppLanguage.english => 'Host: ',
      };

  String get toTime => switch (language) {
        AppLanguage.hindi => ' से ',
        AppLanguage.hinglish => ' to ',
        AppLanguage.english => ' to ',
      };

  String get nightShiftTag => switch (language) {
        AppLanguage.hindi => ' (रात)',
        AppLanguage.hinglish => ' (Night)',
        AppLanguage.english => ' (Night)',
      };

  String agreedWageLabel(int wage) => switch (language) {
        AppLanguage.hindi => 'तय मानदेय: ₹$wage (शिफ्ट पूर्ण होने पर)',
        AppLanguage.hinglish => 'Agreed Wage: ₹$wage (shift complete hone par)',
        AppLanguage.english => 'Agreed Wage: ₹$wage (on shift completion)',
      };

  String agreedWagePaidByHost(int wage) => switch (language) {
        AppLanguage.hindi => 'तय मानदेय: ₹$wage (भुगतान आयोजक द्वारा सीधे देय)',
        AppLanguage.hinglish => 'Agreed Wage: ₹$wage (Host dwara directly payable)',
        AppLanguage.english => 'Agreed Wage: ₹$wage (Paid directly by host)',
      };

  String earnedWageLabel(int wage) => switch (language) {
        AppLanguage.hindi => 'अर्जित मानदेय: ₹$wage',
        AppLanguage.hinglish => 'Earned Wage: ₹$wage',
        AppLanguage.english => 'Earned Wage: ₹$wage',
      };

  String get dutyPassPinTitle => switch (language) {
        AppLanguage.hindi => 'ड्यूटी पास सत्यापन कोड (PIN)',
        AppLanguage.hinglish => 'Duty Pass Verification PIN',
        AppLanguage.english => 'Duty Pass Verification PIN',
      };

  String get dutyPassGateInstruction => switch (language) {
        AppLanguage.hindi => 'प्रवेश द्वार पर आयोजक को दिखाएं',
        AppLanguage.hinglish => 'Gate par organizer ko dikhayein',
        AppLanguage.english => 'Show to host at entrance gate',
      };

  String get awaitingHostConfirmation => switch (language) {
        AppLanguage.hindi =>
          'चेक-इन पूर्ण। आयोजक द्वारा उपस्थिति की पुष्टि प्रतीक्षित है।',
        AppLanguage.hinglish =>
          'Check-in complete. Host verification pending.',
        AppLanguage.english =>
          'Check-in complete. Awaiting host confirmation.',
      };

  String get loadingBookings => switch (language) {
        AppLanguage.hindi => 'बुकिंग्स लोड हो रही हैं...',
        AppLanguage.hinglish => 'Bookings load ho rahi hain...',
        AppLanguage.english => 'Loading bookings...',
      };

  String get cancellationReasonLabel => switch (language) {
        AppLanguage.hindi => 'रद्द करने का कारण: ',
        AppLanguage.hinglish => 'Cancellation Reason: ',
        AppLanguage.english => 'Cancellation Reason: ',
      };

  // ==========================================
  // Worker Work History Screen
  // ==========================================
  String get workHistoryScreenTitle => switch (language) {
        AppLanguage.hindi => 'कार्य इतिहास',
        AppLanguage.hinglish => 'Work History',
        AppLanguage.english => 'Work History',
      };

  String get tabAll => switch (language) {
        AppLanguage.hindi => 'सभी',
        AppLanguage.hinglish => 'All',
        AppLanguage.english => 'All',
      };

  String get tabCompleted => switch (language) {
        AppLanguage.hindi => 'संपन्न',
        AppLanguage.hinglish => 'Completed',
        AppLanguage.english => 'Completed',
      };

  String get tabCancelled => switch (language) {
        AppLanguage.hindi => 'रद्द',
        AppLanguage.hinglish => 'Cancelled',
        AppLanguage.english => 'Cancelled',
      };

  String get tabPastShifts => switch (language) {
        AppLanguage.hindi => 'पिछली शिफ्ट्स',
        AppLanguage.hinglish => 'Past Shifts',
        AppLanguage.english => 'Past Shifts',
      };

  String get noWorkHistoryTitle => switch (language) {
        AppLanguage.hindi => 'कोई इतिहास दर्ज नहीं है',
        AppLanguage.hinglish => 'Koi history darj nahi hai',
        AppLanguage.english => 'No work history recorded',
      };

  String get noWorkHistoryDesc => switch (language) {
        AppLanguage.hindi =>
          'इस श्रेणी में फिलहाल कोई कार्य इतिहास उपलब्ध नहीं है।',
        AppLanguage.hinglish =>
          'Is category mein filhaal koi work history available nahi hai.',
        AppLanguage.english =>
          'No work history is available in this category.',
      };

  String get loadingHistory => switch (language) {
        AppLanguage.hindi => 'इतिहास लोड हो रहा है...',
        AppLanguage.hinglish => 'History load ho rahi hai...',
        AppLanguage.english => 'Loading history...',
      };

  // ==========================================
  // Worker Job Discovery & Details
  // ==========================================
  String get availableJobsScreenTitle => switch (language) {
        AppLanguage.hindi => 'उपलब्ध कार्य',
        AppLanguage.hinglish => 'Available Jobs',
        AppLanguage.english => 'Available Jobs',
      };

  String get searchJobsHint => switch (language) {
        AppLanguage.hindi => 'कार्य, स्थल, या मुहल्ले के नाम से खोजें...',
        AppLanguage.hinglish => 'Kaam, venue ya locality se khojein...',
        AppLanguage.english => 'Search by job, venue, or locality...',
      };

  String get filtersTooltip => switch (language) {
        AppLanguage.hindi => 'फ़िल्टर',
        AppLanguage.hinglish => 'Filters',
        AppLanguage.english => 'Filters',
      };

  String get jobDetailsTitle => switch (language) {
        AppLanguage.hindi => 'कार्य विवरण',
        AppLanguage.hinglish => 'Job Details',
        AppLanguage.english => 'Job Details',
      };

  String get perShiftLabel => switch (language) {
        AppLanguage.hindi => 'मानदेय (प्रति शिफ्ट)',
        AppLanguage.hinglish => 'Wage (Per Shift)',
        AppLanguage.english => 'Wage (Per Shift)',
      };

  String get shiftExpired => switch (language) {
        AppLanguage.hindi => 'शिफ्ट समाप्त',
        AppLanguage.hinglish => 'Shift Expired',
        AppLanguage.english => 'Shift Expired',
      };

  String get applyNow => switch (language) {
        AppLanguage.hindi => 'आवेदन करें',
        AppLanguage.hinglish => 'Apply Karein',
        AppLanguage.english => 'Apply Now',
      };

  String get alreadyApplied => switch (language) {
        AppLanguage.hindi => 'आवेदन किया गया',
        AppLanguage.hinglish => 'Applied',
        AppLanguage.english => 'Applied',
      };

  String get applying => switch (language) {
        AppLanguage.hindi => 'आवेदन किया जा रहा है...',
        AppLanguage.hinglish => 'Applying...',
        AppLanguage.english => 'Applying...',
      };

  String get applicationSuccess => switch (language) {
        AppLanguage.hindi => 'आवेदन सफलतापूर्वक जमा हुआ!',
        AppLanguage.hinglish => 'Application successfully submit ho gayi!',
        AppLanguage.english => 'Application submitted successfully!',
      };

  String get noJobsFoundTitle => switch (language) {
        AppLanguage.hindi => 'कोई कार्य उपलब्ध नहीं है',
        AppLanguage.hinglish => 'Koi kaam nahi mila',
        AppLanguage.english => 'No jobs found',
      };

  String get noJobsFoundDesc => switch (language) {
        AppLanguage.hindi => 'अपनी खोज या फ़िल्टर बदलकर देखें।',
        AppLanguage.hinglish => 'Apna search ya filter badal kar try karein.',
        AppLanguage.english => 'Try adjusting your search query or filters.',
      };

  // ==========================================
  // Worker Profile Placeholder Screen
  // ==========================================
  String get workerProfileTitle => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ता प्रोफाइल',
        AppLanguage.hinglish => 'Worker Profile',
        AppLanguage.english => 'Worker Profile',
      };

  String get personalDetails => switch (language) {
        AppLanguage.hindi => 'व्यक्तिगत विवरण',
        AppLanguage.hinglish => 'Personal Details',
        AppLanguage.english => 'Personal Details',
      };

  String get skillsAndWork => switch (language) {
        AppLanguage.hindi => 'कौशल एवं कार्य क्षेत्र',
        AppLanguage.hinglish => 'Skills & Work Categories',
        AppLanguage.english => 'Skills & Work Categories',
      };

  String get editProfile => switch (language) {
        AppLanguage.hindi => 'प्रोफाइल संपादित करें',
        AppLanguage.hinglish => 'Profile Edit Karein',
        AppLanguage.english => 'Edit Profile',
      };

  // ==========================================
  // Owner Flow (Home, Jobs, Attendance, History)
  // ==========================================
  String get ownerDashboardScreenTitle => switch (language) {
        AppLanguage.hindi => 'व्यापारी डैशबोर्ड',
        AppLanguage.hinglish => 'Owner Dashboard',
        AppLanguage.english => 'Owner Dashboard',
      };

  String get postJobButton => switch (language) {
        AppLanguage.hindi => 'नया कार्य पोस्ट करें',
        AppLanguage.hinglish => 'Naya Kaam Post Karein',
        AppLanguage.english => 'Post New Job',
      };

  String get businessProfileTooltip => switch (language) {
        AppLanguage.hindi => 'व्यापार प्रोफाइल',
        AppLanguage.hinglish => 'Business Profile',
        AppLanguage.english => 'Business Profile',
      };

  String get checkingBusinessStatus => switch (language) {
        AppLanguage.hindi => 'व्यापार स्थिति जांची जा रही है...',
        AppLanguage.hinglish => 'Business status check ho raha hai...',
        AppLanguage.english => 'Checking business status...',
      };

  String get myJobsTitle => switch (language) {
        AppLanguage.hindi => 'मेरे कार्य',
        AppLanguage.hinglish => 'My Jobs',
        AppLanguage.english => 'My Jobs',
      };

  String get myJobsSubtitle => switch (language) {
        AppLanguage.hindi => 'कार्य पोस्टिंग व प्रबंधन',
        AppLanguage.hinglish => 'Job postings aur management',
        AppLanguage.english => 'Job postings & management',
      };

  String get attendanceRosterTitle => switch (language) {
        AppLanguage.hindi => 'उपस्थिति रोस्टर',
        AppLanguage.hinglish => 'Attendance Roster',
        AppLanguage.english => 'Attendance Roster',
      };

  String get attendanceRosterSubtitle => switch (language) {
        AppLanguage.hindi => 'रोस्टर व चेक-इन प्रबंधन',
        AppLanguage.hinglish => 'Roster aur check-in management',
        AppLanguage.english => 'Roster & check-in management',
      };

  String get ownerJobHistoryTitle => switch (language) {
        AppLanguage.hindi => 'कार्य इतिहास',
        AppLanguage.hinglish => 'Job History',
        AppLanguage.english => 'Job History',
      };

  String get ownerJobHistorySubtitle => switch (language) {
        AppLanguage.hindi => 'पिछली पोस्टिंग व रिकॉर्ड्स',
        AppLanguage.hinglish => 'Past postings aur records',
        AppLanguage.english => 'Past postings & records',
      };

  String get completeBusinessProfilePrompt => switch (language) {
        AppLanguage.hindi => 'व्यवसाय विवरण पूरा करें',
        AppLanguage.hinglish => 'Business details poora karein',
        AppLanguage.english => 'Complete Business Details',
      };

  String get verificationPendingTitle => switch (language) {
        AppLanguage.hindi => 'सत्यापन लंबित',
        AppLanguage.hinglish => 'Verification Pending',
        AppLanguage.english => 'Verification Pending',
      };

  String get underReviewTitle => switch (language) {
        AppLanguage.hindi => 'समीक्षा जारी',
        AppLanguage.hinglish => 'Under Review',
        AppLanguage.english => 'Under Review',
      };

  String get verifiedBusinessTitle => switch (language) {
        AppLanguage.hindi => 'सत्यापित व्यवसाय',
        AppLanguage.hinglish => 'Verified Business',
        AppLanguage.english => 'Verified Business',
      };

  String get suspendedBusinessTitle => switch (language) {
        AppLanguage.hindi => 'खाता निलंबित',
        AppLanguage.hinglish => 'Suspended Business',
        AppLanguage.english => 'Suspended Business',
      };

  String get myJobsScreenTitle => switch (language) {
        AppLanguage.hindi => 'मेरे कार्य पोस्टिंग',
        AppLanguage.hinglish => 'My Jobs',
        AppLanguage.english => 'My Jobs',
      };

  String get tabPendingApproval => switch (language) {
        AppLanguage.hindi => 'समीक्षाधीन',
        AppLanguage.hinglish => 'Pending',
        AppLanguage.english => 'Pending',
      };

  String get tabLive => switch (language) {
        AppLanguage.hindi => 'प्रकाशित',
        AppLanguage.hinglish => 'Live',
        AppLanguage.english => 'Live',
      };

  String get tabDraft => switch (language) {
        AppLanguage.hindi => 'ड्राफ्ट',
        AppLanguage.hinglish => 'Draft',
        AppLanguage.english => 'Draft',
      };

  String get tabRejected => switch (language) {
        AppLanguage.hindi => 'अस्वीकृत',
        AppLanguage.hinglish => 'Rejected',
        AppLanguage.english => 'Rejected',
      };

  String get tabExpired => switch (language) {
        AppLanguage.hindi => 'समाप्त',
        AppLanguage.hinglish => 'Expired',
        AppLanguage.english => 'Expired',
      };

  String get cancelJobDialogTitle => switch (language) {
        AppLanguage.hindi => 'कार्य रद्द करें?',
        AppLanguage.hinglish => 'Job Cancel Karein?',
        AppLanguage.english => 'Cancel Job?',
      };

  String get cancelJobConfirmMessage => switch (language) {
        AppLanguage.hindi =>
          'क्या आप वाकई इस कार्य को रद्द करना चाहते हैं? रद्द करने के बाद यह कार्य कार्यकर्ताओं की सूची से तुरंत हटा दिया जाएगा।',
        AppLanguage.hinglish =>
          'Kya aap sach mein ye job cancel karna chahte hain? Cancel karne ke baad ye workers ki list se hat jayega.',
        AppLanguage.english =>
          'Are you sure you want to cancel this job? Once cancelled, it will be immediately removed from the worker feed.',
      };

  String get cancelJobReasonLabel => switch (language) {
        AppLanguage.hindi => 'रद्द करने का कारण',
        AppLanguage.hinglish => 'Cancel karne ka reason',
        AppLanguage.english => 'Reason for cancellation',
      };

  String get cancelJobReasonHint => switch (language) {
        AppLanguage.hindi => 'उदा. कार्यक्रम स्थगित या तिथि परिवर्तित',
        AppLanguage.hinglish => 'E.g., Event postponed ya date change',
        AppLanguage.english => 'E.g., Event postponed or date changed',
      };

  String get cancelJobSuccess => switch (language) {
        AppLanguage.hindi => 'कार्य सफलतापूर्वक रद्द कर दिया गया।',
        AppLanguage.hinglish => 'Job successfully cancel kar diya gaya.',
        AppLanguage.english => 'Job cancelled successfully.',
      };

  String get attendanceStatusUpdated => switch (language) {
        AppLanguage.hindi => 'उपस्थिति स्थिति सफलतापूर्वक अपडेट की गई।',
        AppLanguage.hinglish => 'Attendance status successfully update ho gaya.',
        AppLanguage.english => 'Attendance status updated successfully.',
      };

  String get workCompletedMarked => switch (language) {
        AppLanguage.hindi => 'कार्य सफलतापूर्वक संपन्न चिह्नित किया गया।',
        AppLanguage.hinglish => 'Work successfully completed mark kiya gaya.',
        AppLanguage.english => 'Work marked as completed successfully.',
      };

  String manualCheckInTitle(String workerName) => switch (language) {
        AppLanguage.hindi => '$workerName का मैन्युअल चेक-इन',
        AppLanguage.hinglish => '$workerName ka Manual Check-in',
        AppLanguage.english => 'Manual Check-in for $workerName',
      };

  String get manualCheckInDesc => switch (language) {
        AppLanguage.hindi =>
          'यदि कार्यकर्ता फोन या नेटवर्क समस्या के कारण ऐप से चेक-इन नहीं कर सका, तो कारण दर्ज कर सीधे उपस्थित चिह्नित करें:',
        AppLanguage.hinglish =>
          'Agar worker phone ya network problem se check-in nahi kar paaya, toh reason daal kar present mark karein:',
        AppLanguage.english =>
          'If the worker could not check in due to phone or network issues, enter a reason to mark them present directly:',
      };

  String get markPresentButton => switch (language) {
        AppLanguage.hindi => 'उपस्थित मार्क करें',
        AppLanguage.hinglish => 'Present Mark Karein',
        AppLanguage.english => 'Mark Present',
      };

  String get manualAttendanceRecorded => switch (language) {
        AppLanguage.hindi => 'मैन्युअल उपस्थिति दर्ज की गई।',
        AppLanguage.hinglish => 'Manual attendance darj ho gayi.',
        AppLanguage.english => 'Manual attendance recorded.',
      };

  String get attendanceHistoryScreenTitle => switch (language) {
        AppLanguage.hindi => 'उपस्थिति इतिहास',
        AppLanguage.hinglish => 'Attendance History',
        AppLanguage.english => 'Attendance History',
      };

  String get noAttendanceHistoryTitle => switch (language) {
        AppLanguage.hindi => 'कोई उपस्थिति रिकॉर्ड नहीं',
        AppLanguage.hinglish => 'Koi attendance record nahi',
        AppLanguage.english => 'No attendance records',
      };

  String get noAttendanceHistoryDesc => switch (language) {
        AppLanguage.hindi =>
          'फिलहाल आपके व्यवसाय द्वारा पोस्ट किए गए कार्यों में कोई उपस्थिति इतिहास दर्ज नहीं है।',
        AppLanguage.hinglish =>
          'Filhaal aapke business ke jobs mein koi attendance history nahi hai.',
        AppLanguage.english =>
          'No attendance history recorded yet for jobs posted by your business.',
      };

  String get businessProfileScreenTitle => switch (language) {
        AppLanguage.hindi => 'व्यापार प्रोफाइल',
        AppLanguage.hinglish => 'Business Profile',
        AppLanguage.english => 'Business Profile',
      };

  String get postJobWizardTitle => switch (language) {
        AppLanguage.hindi => 'नया कार्य पोस्ट करें',
        AppLanguage.hinglish => 'Post New Job',
        AppLanguage.english => 'Post New Job',
      };

  String get editJobWizardTitle => switch (language) {
        AppLanguage.hindi => 'कार्य संपादित करें',
        AppLanguage.hinglish => 'Edit Job',
        AppLanguage.english => 'Edit Job',
      };

  String get draftButton => switch (language) {
        AppLanguage.hindi => 'ड्राफ्ट',
        AppLanguage.hinglish => 'Draft',
        AppLanguage.english => 'Draft',
      };

  String get goToDashboardAction => switch (language) {
        AppLanguage.hindi => 'डैशबोर्ड पर जाएं',
        AppLanguage.hinglish => 'Go to Dashboard',
        AppLanguage.english => 'Go to Dashboard',
      };

  // ==========================================
  // Notifications Center & Preferences
  // ==========================================
  String get notificationCenterTitle => switch (language) {
        AppLanguage.hindi => 'सूचनाएं',
        AppLanguage.hinglish => 'Notifications',
        AppLanguage.english => 'Notifications',
      };

  String get markAllAsReadTooltip => switch (language) {
        AppLanguage.hindi => 'सभी पढ़ी हुई मार्क करें',
        AppLanguage.hinglish => 'Sabhi read mark karein',
        AppLanguage.english => 'Mark all as read',
      };

  String get allMarkedAsReadMessage => switch (language) {
        AppLanguage.hindi => 'सभी सूचनाएं पढ़ी गईं',
        AppLanguage.hinglish => 'Sabhi notifications read ho gayi',
        AppLanguage.english => 'All notifications marked as read',
      };

  String get notificationSettingsTooltip => switch (language) {
        AppLanguage.hindi => 'सूचना सेटिंग्स',
        AppLanguage.hinglish => 'Notification Settings',
        AppLanguage.english => 'Notification Settings',
      };

  String get tabUnread => switch (language) {
        AppLanguage.hindi => 'अपठित',
        AppLanguage.hinglish => 'Unread',
        AppLanguage.english => 'Unread',
      };

  String get noNotificationsTitle => switch (language) {
        AppLanguage.hindi => 'कोई सूचनाएं नहीं',
        AppLanguage.hinglish => 'Koi notifications nahi',
        AppLanguage.english => 'No notifications',
      };

  String get noNotificationsDesc => switch (language) {
        AppLanguage.hindi =>
          'आपके पास फिलहाल कोई सूचना नहीं है। नया कार्य या बुकिंग अपडेट आते ही यहाँ दिखाई देगा।',
        AppLanguage.hinglish =>
          'Aapke paas filhaal koi notification nahi hai. Naye updates aane par yahan dikhenge.',
        AppLanguage.english =>
          'You currently have no notifications. New updates will appear here.',
      };

  String get notificationPreferencesTitle => switch (language) {
        AppLanguage.hindi => 'सूचना सेटिंग्स',
        AppLanguage.hinglish => 'Notification Preferences',
        AppLanguage.english => 'Notification Preferences',
      };

  String get timeJustNow => switch (language) {
        AppLanguage.hindi => 'अभी',
        AppLanguage.hinglish => 'Just now',
        AppLanguage.english => 'Just now',
      };

  String timeMinutesAgo(int m) => switch (language) {
        AppLanguage.hindi => '$m मिनट पहले',
        AppLanguage.hinglish => '$m min pehle',
        AppLanguage.english => '${m}m ago',
      };

  String timeHoursAgo(int h) => switch (language) {
        AppLanguage.hindi => '$h घंटे पहले',
        AppLanguage.hinglish => '$h ghante pehle',
        AppLanguage.english => '${h}h ago',
      };

  String get timeYesterday => switch (language) {
        AppLanguage.hindi => 'कल',
        AppLanguage.hinglish => 'Yesterday',
        AppLanguage.english => 'Yesterday',
      };

  String timeDaysAgo(int d) => switch (language) {
        AppLanguage.hindi => '$d दिन पहले',
        AppLanguage.hinglish => '$d din pehle',
        AppLanguage.english => '${d}d ago',
      };

  // ==========================================
  // Access Denied Screen
  // ==========================================
  String get accessDeniedTitle => switch (language) {
        AppLanguage.hindi => 'प्रवेश वर्जित',
        AppLanguage.hinglish => 'Access Denied',
        AppLanguage.english => 'Access Denied',
      };

  String get adminAccountTitle => switch (language) {
        AppLanguage.hindi => 'प्रशासक खाता',
        AppLanguage.hinglish => 'Admin Account',
        AppLanguage.english => 'Admin Account',
      };

  String get adminConsoleDesc => switch (language) {
        AppLanguage.hindi =>
          'प्रशासकीय कार्यों के लिए कृपया Next.js एडमिन वेब कंसोल का उपयोग करें। मोबाइल ऐप केवल कार्यकर्ताओं और व्यवसाय मालिकों के लिए है।',
        AppLanguage.hinglish =>
          'Admin operations ke liye kripya Next.js admin web console ka use karein. Mobile app sirf Workers aur Business Owners ke liye hai.',
        AppLanguage.english =>
          'Admin operations are restricted to the web console. This mobile app is exclusively for Workers and Business Owners.',
      };

  String get backToLoginButton => switch (language) {
        AppLanguage.hindi => 'लॉगिन स्क्रीन पर वापस जाएं',
        AppLanguage.hinglish => 'Login screen par wapas jayein',
        AppLanguage.english => 'Back to Login',
      };

  // ==========================================
  // Additional Screen Helpers & Labels
  // ==========================================
  String get ok => switch (language) {
        AppLanguage.hindi => 'ठीक है',
        AppLanguage.hinglish => 'OK',
        AppLanguage.english => 'OK',
      };

  String get viewDetails => switch (language) {
        AppLanguage.hindi => 'विवरण देखें',
        AppLanguage.hinglish => 'Details Dekhein',
        AppLanguage.english => 'View Details',
      };

  String filtersActive(int count) => switch (language) {
        AppLanguage.hindi => '$count फ़िल्टर सक्रिय हैं',
        AppLanguage.hinglish => '$count filters active',
        AppLanguage.english => '$count filters active',
      };

  String get clearAll => switch (language) {
        AppLanguage.hindi => 'हटाएं',
        AppLanguage.hinglish => 'Clear All',
        AppLanguage.english => 'Clear All',
      };

  String get searchingJobs => switch (language) {
        AppLanguage.hindi => 'कार्य खोजे जा रहे हैं...',
        AppLanguage.hinglish => 'Jobs khoji ja rahi hain...',
        AppLanguage.english => 'Searching jobs...',
      };

  String get loadingProfile => switch (language) {
        AppLanguage.hindi => 'प्रोफाइल लोड हो रही है...',
        AppLanguage.hinglish => 'Profile load ho rahi hai...',
        AppLanguage.english => 'Loading profile...',
      };

  String get loadingBusinessProfile => switch (language) {
        AppLanguage.hindi => 'व्यापार विवरण लोड हो रहा है...',
        AppLanguage.hinglish => 'Business details load ho rahi hain...',
        AppLanguage.english => 'Loading business details...',
      };

  String get areaLocality => switch (language) {
        AppLanguage.hindi => 'कार्यक्षेत्र (मुहल्ला)',
        AppLanguage.hinglish => 'Area / Locality',
        AppLanguage.english => 'Area / Locality',
      };

  String get cityDistrict => switch (language) {
        AppLanguage.hindi => 'शहर व जिला',
        AppLanguage.hinglish => 'City & District',
        AppLanguage.english => 'City & District',
      };

  String get pincode => switch (language) {
        AppLanguage.hindi => 'पिनकोड',
        AppLanguage.hinglish => 'Pincode',
        AppLanguage.english => 'Pincode',
      };

  String get skillsSection => switch (language) {
        AppLanguage.hindi => 'कौशल एवं श्रेणियाँ',
        AppLanguage.hinglish => 'Skills & Categories',
        AppLanguage.english => 'Skills & Categories',
      };

  String get noSkillsAdded => switch (language) {
        AppLanguage.hindi => 'कोई कौशल नहीं जुड़ा है',
        AppLanguage.hinglish => 'Koi skills added nahi hain',
        AppLanguage.english => 'No skills added yet',
      };

  String get businessDetailsSection => switch (language) {
        AppLanguage.hindi => 'व्यापार विवरण',
        AppLanguage.hinglish => 'Business Details',
        AppLanguage.english => 'Business Details',
      };

  String get ownerContactSection => switch (language) {
        AppLanguage.hindi => 'मालिक संपर्क',
        AppLanguage.hinglish => 'Owner Contact',
        AppLanguage.english => 'Owner Contact',
      };

  String get documentsSection => switch (language) {
        AppLanguage.hindi => 'सत्यापन दस्तावेज़',
        AppLanguage.hinglish => 'Verification Documents',
        AppLanguage.english => 'Verification Documents',
      };

  String get addressLabel => switch (language) {
        AppLanguage.hindi => 'पता',
        AppLanguage.hinglish => 'Address',
        AppLanguage.english => 'Address',
      };

  String get categoryLabel => switch (language) {
        AppLanguage.hindi => 'श्रेणी',
        AppLanguage.hinglish => 'Category',
        AppLanguage.english => 'Category',
      };

  String get businessNameLabel => switch (language) {
        AppLanguage.hindi => 'प्रतिष्ठान का नाम',
        AppLanguage.hinglish => 'Business Name',
        AppLanguage.english => 'Business Name',
      };

  String get allCategories => switch (language) {
        AppLanguage.hindi => 'सभी श्रेणियाँ',
        AppLanguage.hinglish => 'All Categories',
        AppLanguage.english => 'All Categories',
      };

  String workersNeeded(int count) => switch (language) {
        AppLanguage.hindi => '$count कार्यकर्ता आवश्यक',
        AppLanguage.hinglish => '$count workers required',
        AppLanguage.english => '$count workers needed',
      };

  String spotsLeft(int count) => switch (language) {
        AppLanguage.hindi => '$count स्थान शेष',
        AppLanguage.hinglish => '$count spots bache hain',
        AppLanguage.english => '$count spots left',
      };

  String get reportingTimeLabel => switch (language) {
        AppLanguage.hindi => 'रिपोर्टिंग समय: ',
        AppLanguage.hinglish => 'Reporting Time: ',
        AppLanguage.english => 'Reporting Time: ',
      };

  String get venueAddressLabel => switch (language) {
        AppLanguage.hindi => 'स्थल का पता: ',
        AppLanguage.hinglish => 'Venue Address: ',
        AppLanguage.english => 'Venue Address: ',
      };

  String get descriptionLabel => switch (language) {
        AppLanguage.hindi => 'कार्य का विवरण',
        AppLanguage.hinglish => 'Job Description',
        AppLanguage.english => 'Job Description',
      };

  String get requirementsLabel => switch (language) {
        AppLanguage.hindi => 'आवश्यकताएं',
        AppLanguage.hinglish => 'Requirements',
        AppLanguage.english => 'Requirements',
      };

  String get perksLabel => switch (language) {
        AppLanguage.hindi => 'सुविधाएं (भोजन आदि)',
        AppLanguage.hinglish => 'Perks & Benefits',
        AppLanguage.english => 'Perks & Benefits',
      };

  String get noJobsPostedTitle => switch (language) {
        AppLanguage.hindi => 'कोई कार्य पोस्ट नहीं है',
        AppLanguage.hinglish => 'Koi job post nahi hui',
        AppLanguage.english => 'No jobs posted yet',
      };

  String get noJobsPostedDesc => switch (language) {
        AppLanguage.hindi =>
          'मैरिज हॉल, कैटरिंग या टेंट हाउस के लिए काम पोस्ट करने हेतु "नया कार्य पोस्ट करें" पर टैप करें।',
        AppLanguage.hinglish =>
          'Marriage hall, catering ya tent house ke liye kaam post karne ke liye "Post New Job" par tap karein.',
        AppLanguage.english =>
          'Tap "Post New Job" to post shifts for marriage halls, catering, or tent houses.',
      };

  String get searchMyJobsHint => switch (language) {
        AppLanguage.hindi => 'अपने पोस्ट किए गए कार्य खोजें...',
        AppLanguage.hinglish => 'Apne posted jobs search karein...',
        AppLanguage.english => 'Search your posted jobs...',
      };

  String get loadingRoster => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ता रोस्टर लोड हो रहा है...',
        AppLanguage.hinglish => 'Worker roster load ho raha hai...',
        AppLanguage.english => 'Loading worker roster...',
      };

  String get totalWorkersLabel => switch (language) {
        AppLanguage.hindi => 'कुल कार्यकर्ता',
        AppLanguage.hinglish => 'Total Workers',
        AppLanguage.english => 'Total Workers',
      };

  String get checkedInLabel => switch (language) {
        AppLanguage.hindi => 'चेक-इन',
        AppLanguage.hinglish => 'Checked In',
        AppLanguage.english => 'Checked In',
      };

  String get presentLabel => switch (language) {
        AppLanguage.hindi => 'उपस्थित',
        AppLanguage.hinglish => 'Present',
        AppLanguage.english => 'Present',
      };

  String get completedLabel => switch (language) {
        AppLanguage.hindi => 'संपन्न',
        AppLanguage.hinglish => 'Completed',
        AppLanguage.english => 'Completed',
      };

  String get completeJobButton => switch (language) {
        AppLanguage.hindi => 'शिफ्ट संपन्न करें',
        AppLanguage.hinglish => 'Mark Shift Completed',
        AppLanguage.english => 'Mark Shift Completed',
      };

  String get manualCheckInButton => switch (language) {
        AppLanguage.hindi => 'मैन्युअल चेक-इन',
        AppLanguage.hinglish => 'Manual Check-in',
        AppLanguage.english => 'Manual Check-in',
      };

  // ==========================================
  // Attendance & Job History
  // ==========================================
  String get attendanceHistoryTitle => switch (language) {
        AppLanguage.hindi => 'उपस्थिति इतिहास',
        AppLanguage.hinglish => 'Attendance History',
        AppLanguage.english => 'Attendance History',
      };

  String get viewRoster => switch (language) {
        AppLanguage.hindi => 'रोस्टर देखें',
        AppLanguage.hinglish => 'Roster Dekhein',
        AppLanguage.english => 'View Roster',
      };

  String get filterAll => switch (language) {
        AppLanguage.hindi => 'सभी',
        AppLanguage.hinglish => 'All',
        AppLanguage.english => 'All',
      };

  String get filterPublished => switch (language) {
        AppLanguage.hindi => 'सक्रिय / प्रकाशित',
        AppLanguage.hinglish => 'Active / Published',
        AppLanguage.english => 'Active / Published',
      };

  String get filterCompleted => switch (language) {
        AppLanguage.hindi => 'पूर्ण',
        AppLanguage.hinglish => 'Completed',
        AppLanguage.english => 'Completed',
      };

  String get filterCancelled => switch (language) {
        AppLanguage.hindi => 'रद्द',
        AppLanguage.hinglish => 'Cancelled',
        AppLanguage.english => 'Cancelled',
      };

  String get noJobHistoryTitle => switch (language) {
        AppLanguage.hindi => 'कोई कार्य इतिहास उपलब्ध नहीं है',
        AppLanguage.hinglish => 'Koi job history available nahi hai',
        AppLanguage.english => 'No job history available',
      };

  String get noJobHistoryDesc => switch (language) {
        AppLanguage.hindi =>
          'इस व्यापार के लिए अभी तक कोई कार्य शिफ्ट नहीं बनाई गई है।',
        AppLanguage.hinglish =>
          'Is business ke liye abhi tak koi shift nahi bani hai.',
        AppLanguage.english =>
          'No shifts have been created for this business yet.',
      };

  String workersConfirmedCount(int confirmed, int needed) => switch (language) {
        AppLanguage.hindi => '$confirmed / $needed कार्यकर्ता पुष्ट',
        AppLanguage.hinglish => '$confirmed / $needed workers confirmed',
        AppLanguage.english => '$confirmed / $needed workers confirmed',
      };

  // ==========================================
  // Business Profile Screen
  // ==========================================
  String get businessProfileTitle => switch (language) {
        AppLanguage.hindi => 'व्यापार प्रोफाइल',
        AppLanguage.hinglish => 'Business Profile',
        AppLanguage.english => 'Business Profile',
      };

  String get businessProfileIncomplete => switch (language) {
        AppLanguage.hindi => 'व्यापार प्रोफाइल अधूरी है',
        AppLanguage.hinglish => 'Business profile adhuri hai',
        AppLanguage.english => 'Business Profile Incomplete',
      };

  String get businessProfileIncompleteDesc => switch (language) {
        AppLanguage.hindi =>
          'अस्थायी कार्यकर्ता बुकिंग हेतु पहले अपने व्यापार का पंजीकरण करें।',
        AppLanguage.hinglish =>
          'Workers book karne ke liye pehle apne business ka registration karein.',
        AppLanguage.english =>
          'Please complete business registration before booking temporary workers.',
      };

  String get setupBusinessButton => switch (language) {
        AppLanguage.hindi => 'प्रोफाइल बनाएं',
        AppLanguage.hinglish => 'Setup Business',
        AppLanguage.english => 'Setup Business',
      };

  String get rejectionReasonLabel => switch (language) {
        AppLanguage.hindi => 'अस्वीकृति का कारण:',
        AppLanguage.hinglish => 'Rejection Reason:',
        AppLanguage.english => 'Rejection Reason:',
      };

  String get editAndResubmit => switch (language) {
        AppLanguage.hindi => 'संशोधन करें और पुनः सबमिट करें',
        AppLanguage.hinglish => 'Edit karein aur resubmit karein',
        AppLanguage.english => 'Edit and Resubmit',
      };

  String get ownerOrAuthorizedPerson => switch (language) {
        AppLanguage.hindi => 'मालिक / अधिकृत व्यक्ति',
        AppLanguage.hinglish => 'Owner / Authorized Person',
        AppLanguage.english => 'Owner / Authorized Person',
      };

  String get verifiedMobileNumber => switch (language) {
        AppLanguage.hindi => 'सत्यापित मोबाइल',
        AppLanguage.hinglish => 'Verified Mobile',
        AppLanguage.english => 'Verified Mobile',
      };

  String get businessContactNumber => switch (language) {
        AppLanguage.hindi => 'व्यापार संपर्क नंबर',
        AppLanguage.hinglish => 'Business Contact',
        AppLanguage.english => 'Business Contact',
      };

  String get locationAndArea => switch (language) {
        AppLanguage.hindi => 'कार्यक्षेत्र व स्थान',
        AppLanguage.hinglish => 'Location & Area',
        AppLanguage.english => 'Location & Area',
      };

  String get fullAddressLabel => switch (language) {
        AppLanguage.hindi => 'पूरा पता',
        AppLanguage.hinglish => 'Full Address',
        AppLanguage.english => 'Full Address',
      };

  String attachedDocumentsCount(int count) => switch (language) {
        AppLanguage.hindi => 'संलग्न दस्तावेज़ ($count):',
        AppLanguage.hinglish => 'Attached Documents ($count):',
        AppLanguage.english => 'Attached Documents ($count):',
      };

  String get editBusinessProfile => switch (language) {
        AppLanguage.hindi => 'विवरण संपादित करें',
        AppLanguage.hinglish => 'Edit Profile',
        AppLanguage.english => 'Edit Profile',
      };

  // ==========================================
  // Post Job Wizard
  // ==========================================
  String get editJobTitle => switch (language) {
        AppLanguage.hindi => 'कार्य संपादित करें',
        AppLanguage.hinglish => 'Edit Job',
        AppLanguage.english => 'Edit Job',
      };

  String get postNewJobTitle => switch (language) {
        AppLanguage.hindi => 'नया कार्य पोस्ट करें',
        AppLanguage.hinglish => 'Post New Job',
        AppLanguage.english => 'Post New Job',
      };

  String get draftSavedSuccess => switch (language) {
        AppLanguage.hindi => 'ड्राफ्ट सफलतापूर्वक सुरक्षित किया गया।',
        AppLanguage.hinglish => 'Draft successfully save ho gaya.',
        AppLanguage.english => 'Draft saved successfully.',
      };

  String get jobSubmittedSuccess => switch (language) {
        AppLanguage.hindi => 'कार्य सफलतापूर्वक सबमिट कर दिया गया!',
        AppLanguage.hinglish => 'Job successfully submit ho gayi!',
        AppLanguage.english => 'Job submitted successfully!',
      };

  String get backStepButton => switch (language) {
        AppLanguage.hindi => 'पीछे',
        AppLanguage.hinglish => 'Back',
        AppLanguage.english => 'Back',
      };

  String get nextStepButton => switch (language) {
        AppLanguage.hindi => 'आगे बढ़ें',
        AppLanguage.hinglish => 'Next',
        AppLanguage.english => 'Next',
      };

  String get businessVerificationPendingTitle => switch (language) {
        AppLanguage.hindi => 'व्यापार सत्यापन प्रतीक्षित है',
        AppLanguage.hinglish => 'Business verification pending hai',
        AppLanguage.english => 'Business Verification Pending',
      };

  String get businessVerificationPendingDesc => switch (language) {
        AppLanguage.hindi =>
          'सुरक्षा कारणों से केवल सत्यापित व्यापार ही कार्य पोस्ट कर सकते हैं। सत्यापन होते ही यह सुविधा अनलॉक हो जाएगी।',
        AppLanguage.hinglish =>
          'Security ke liye sirf verified business hi job post kar sakte hain. Verification hote hi ye unlock ho jayega.',
        AppLanguage.english =>
          'For security, only verified businesses can post jobs. This will unlock once verification is approved.',
      };

  String get returnToDashboard => switch (language) {
        AppLanguage.hindi => 'डैशबोर्ड पर वापस जाएं',
        AppLanguage.hinglish => 'Dashboard par wapas jayein',
        AppLanguage.english => 'Back to Dashboard',
      };

  // ==========================================
  // Access Denied Screen
  // ==========================================
  String get adminAccountNotice => switch (language) {
        AppLanguage.hindi =>
          'प्रशासकीय कार्यों के लिए कृपया Next.js एडमिन वेब कंसोल का उपयोग करें। मोबाइल ऐप केवल कार्यकर्ताओं और व्यापार मालिकों के लिए उपलब्ध है।',
        AppLanguage.hinglish =>
          'Admin operations ke liye kripya Next.js web console use karein. Mobile app sirf workers aur business owners ke liye hai.',
        AppLanguage.english =>
          'Admin operations are restricted to the web console at admin.<domain>. Mobile app is designed exclusively for Workers and Business Owners.',
      };

  // ==========================================
  // Onboarding & Shared Wizard Navigation
  // ==========================================
  String onboardingStepProgress(int current, int total, String label) => switch (language) {
        AppLanguage.hindi => 'चरण $current / $total: $label',
        AppLanguage.hinglish => 'Step $current / $total: $label',
        AppLanguage.english => 'Step $current / $total: $label',
      };

  String get previous => switch (language) {
        AppLanguage.hindi => 'पिछला',
        AppLanguage.hinglish => 'Back',
        AppLanguage.english => 'Back',
      };

  String get next => switch (language) {
        AppLanguage.hindi => 'आगे बढ़ें',
        AppLanguage.hinglish => 'Next',
        AppLanguage.english => 'Next',
      };

  String get quickSelect => switch (language) {
        AppLanguage.hindi => 'त्वरित चयन:',
        AppLanguage.hinglish => 'Quick Select:',
        AppLanguage.english => 'Quick Select:',
      };

  String get yesLabel => switch (language) {
        AppLanguage.hindi => 'हाँ',
        AppLanguage.hinglish => 'Haan',
        AppLanguage.english => 'Yes',
      };

  String get noLabel => switch (language) {
        AppLanguage.hindi => 'नहीं',
        AppLanguage.hinglish => 'Nahi',
        AppLanguage.english => 'No',
      };

  String yesWithDetails(String details) => switch (language) {
        AppLanguage.hindi => 'हाँ ($details)',
        AppLanguage.hinglish => 'Yes ($details)',
        AppLanguage.english => 'Yes ($details)',
      };

  // ==========================================
  // Worker Onboarding
  // ==========================================
  String get workerStep1Label => switch (language) {
        AppLanguage.hindi => 'व्यक्तिगत विवरण',
        AppLanguage.hinglish => 'Personal Details',
        AppLanguage.english => 'Personal Details',
      };

  String get workerStep2Label => switch (language) {
        AppLanguage.hindi => 'कार्य कौशल',
        AppLanguage.hinglish => 'Work Skills',
        AppLanguage.english => 'Work Skills',
      };

  String get workerStep3Label => switch (language) {
        AppLanguage.hindi => 'कार्यक्षेत्र / स्थान',
        AppLanguage.hinglish => 'Work Location',
        AppLanguage.english => 'Work Location',
      };

  String get workerStep4Label => switch (language) {
        AppLanguage.hindi => 'लाइव सेल्फी',
        AppLanguage.hinglish => 'Live Selfie',
        AppLanguage.english => 'Live Selfie',
      };

  String get workerStep5Label => switch (language) {
        AppLanguage.hindi => 'समीक्षा व सक्रियता',
        AppLanguage.hinglish => 'Review & Activate',
        AppLanguage.english => 'Review & Activate',
      };

  String get personalDetailsTitle => switch (language) {
        AppLanguage.hindi => 'व्यक्तिगत विवरण',
        AppLanguage.hinglish => 'Personal Details',
        AppLanguage.english => 'Personal Details',
      };

  String get personalDetailsSubtitle => switch (language) {
        AppLanguage.hindi => 'कृपया अपना सही नाम दर्ज करें जैसा आपके पहचान पत्र पर है।',
        AppLanguage.hinglish => 'Kripya apna sahi naam dalein jaise identity card par hai.',
        AppLanguage.english => 'Please enter your real name as shown on your government ID.',
      };

  String get verifiedPhoneCardTitle => switch (language) {
        AppLanguage.hindi => 'सत्यापित मोबाइल नंबर',
        AppLanguage.hinglish => 'Verified Mobile Number',
        AppLanguage.english => 'Verified Phone Number',
      };

  String get workerFullNameLabel => switch (language) {
        AppLanguage.hindi => 'पूरा नाम*',
        AppLanguage.hinglish => 'Full Name*',
        AppLanguage.english => 'Full Name*',
      };

  String get workerFullNameHint => switch (language) {
        AppLanguage.hindi => 'उदा. रमेश कुमार यादव',
        AppLanguage.hinglish => 'E.g. Ramesh Kumar Yadav',
        AppLanguage.english => 'E.g. Ramesh Kumar Yadav',
      };

  String get workerFullNameNote => switch (language) {
        AppLanguage.hindi => 'यह नाम काम के दौरान शादी लॉन और कैटरिंग मालिकों को दिखेगा।',
        AppLanguage.hinglish => 'Ye naam kaam ke dauran event hosts ko dikhega.',
        AppLanguage.english => 'This name will be visible to event hosts and banquet halls.',
      };

  String get fullNameRequiredError => switch (language) {
        AppLanguage.hindi => 'कृपया अपना पूरा नाम दर्ज करें।',
        AppLanguage.hinglish => 'Kripya apna pura naam dalein.',
        AppLanguage.english => 'Please enter your full name.',
      };

  String get selectSkillsTitle => switch (language) {
        AppLanguage.hindi => 'कार्य कौशल चुनें',
        AppLanguage.hinglish => 'Select Your Skills',
        AppLanguage.english => 'Select Your Skills',
      };

  String get selectSkillsSubtitle => switch (language) {
        AppLanguage.hindi => 'आप जिस काम में निपुण हैं, 1 से 5 कौशल चुनें:',
        AppLanguage.hinglish => 'Aap jis kaam me expert hain, 1 se 5 skills chunein:',
        AppLanguage.english => 'Select 1 to 5 skills you are experienced in:',
      };

  String selectedSkillsCount(int count) => switch (language) {
        AppLanguage.hindi => 'चयनित कौशल: $count / 5',
        AppLanguage.hinglish => 'Selected Skills: $count / 5',
        AppLanguage.english => 'Selected Skills: $count / 5',
      };

  String get atLeastOneSkillRequired => switch (language) {
        AppLanguage.hindi => '* कम से कम 1 कौशल अनिवार्य',
        AppLanguage.hinglish => '* Kam se kam 1 skill zaroori hai',
        AppLanguage.english => '* At least 1 skill is required',
      };

  String get loadingSkills => switch (language) {
        AppLanguage.hindi => 'कौशल लोड हो रहे हैं...',
        AppLanguage.hinglish => 'Skills load ho rahe hain...',
        AppLanguage.english => 'Loading skills...',
      };

  String get otherSkillLabel => switch (language) {
        AppLanguage.hindi => 'अन्य हुनर / कौशल',
        AppLanguage.hinglish => 'Other Skill',
        AppLanguage.english => 'Other Skill',
      };

  String get otherSkillHint => switch (language) {
        AppLanguage.hindi => 'अपने कौशल का नाम लिखें',
        AppLanguage.hinglish => 'Apne skill ka naam likhein',
        AppLanguage.english => 'Enter name of your skill',
      };

  String get selectAtLeastOneSkillError => switch (language) {
        AppLanguage.hindi => 'कम से कम 1 कौशल चुनें।',
        AppLanguage.hinglish => 'Kam se kam 1 skill select karein.',
        AppLanguage.english => 'Please select at least 1 skill.',
      };

  String get workerLocationTitle => switch (language) {
        AppLanguage.hindi => 'कार्यक्षेत्र व पता',
        AppLanguage.hinglish => 'Location Details',
        AppLanguage.english => 'Location Details',
      };

  String get workerLocationSubtitle => switch (language) {
        AppLanguage.hindi => 'गाजीपुर में आपका निवास या कार्यक्षेत्र कहाँ है?',
        AppLanguage.hinglish => 'Ghazipur me aapka residence ya work area kahan hai?',
        AppLanguage.english => 'Where is your residence or preferred work area in Ghazipur?',
      };

  String get localityLabel => switch (language) {
        AppLanguage.hindi => 'मोहल्ला / गाँव / क्षेत्र*',
        AppLanguage.hinglish => 'Area / Locality*',
        AppLanguage.english => 'Area / Locality*',
      };

  String get localityHint => switch (language) {
        AppLanguage.hindi => 'उदा. लंका, शास्त्री नगर, तुलसी सागर',
        AppLanguage.hinglish => 'E.g. Lanka, Shastri Nagar',
        AppLanguage.english => 'E.g. Lanka, Shastri Nagar',
      };

  String get pincodeLabel => switch (language) {
        AppLanguage.hindi => 'पिन कोड (PIN Code)*',
        AppLanguage.hinglish => 'PIN Code*',
        AppLanguage.english => 'PIN Code*',
      };

  String get pincodeHint => switch (language) {
        AppLanguage.hindi => 'उदा. 233001',
        AppLanguage.hinglish => 'E.g. 233001',
        AppLanguage.english => 'E.g. 233001',
      };

  String get cityFixedLabel => switch (language) {
        AppLanguage.hindi => 'शहर',
        AppLanguage.hinglish => 'City',
        AppLanguage.english => 'City',
      };

  String get districtFixedLabel => switch (language) {
        AppLanguage.hindi => 'जिला',
        AppLanguage.hinglish => 'District',
        AppLanguage.english => 'District',
      };

  String get ghazipurCity => switch (language) {
        AppLanguage.hindi => 'गाजीपुर',
        AppLanguage.hinglish => 'Ghazipur',
        AppLanguage.english => 'Ghazipur',
      };

  String get ghazipurDistrict => switch (language) {
        AppLanguage.hindi => 'गाजीपुर, उ.प्र.',
        AppLanguage.hinglish => 'Ghazipur, U.P.',
        AppLanguage.english => 'Ghazipur, U.P.',
      };

  String get optionalGpsTitle => switch (language) {
        AppLanguage.hindi => 'सटीक स्थान जोड़ें (वैकल्पिक GPS)',
        AppLanguage.hinglish => 'Add Exact Location (Optional GPS)',
        AppLanguage.english => 'Add Exact Location (Optional GPS)',
      };

  String get optionalGpsSubtitle => switch (language) {
        AppLanguage.hindi => 'नजदीकी काम खोजने में मदद मिलेगी',
        AppLanguage.hinglish => 'Nazdeeki kaam khojne me help milegi',
        AppLanguage.english => 'Helps discover jobs closest to you',
      };

  String get gpsLinked => switch (language) {
        AppLanguage.hindi => 'लिंक हुआ',
        AppLanguage.hinglish => 'Linked',
        AppLanguage.english => 'Linked',
      };

  String get linkGps => switch (language) {
        AppLanguage.hindi => 'लिंक करें',
        AppLanguage.hinglish => 'Link Karein',
        AppLanguage.english => 'Link GPS',
      };

  String get popularAreasTitle => switch (language) {
        AppLanguage.hindi => 'लोकप्रिय क्षेत्र (त्वरित चयन):',
        AppLanguage.hinglish => 'Popular Areas (Quick Select):',
        AppLanguage.english => 'Popular Areas (Quick Select):',
      };

  String get cityDistrictLabel => switch (language) {
        AppLanguage.hindi => 'शहर / जिला',
        AppLanguage.hinglish => 'City / District',
        AppLanguage.english => 'City / District',
      };

  String get stateLabel => switch (language) {
        AppLanguage.hindi => 'राज्य',
        AppLanguage.hinglish => 'State',
        AppLanguage.english => 'State',
      };

  String get uttarPradeshState => switch (language) {
        AppLanguage.hindi => 'उत्तर प्रदेश',
        AppLanguage.hinglish => 'Uttar Pradesh',
        AppLanguage.english => 'Uttar Pradesh',
      };

  String get linkLocationAction => switch (language) {
        AppLanguage.hindi => 'लिंक करें',
        AppLanguage.hinglish => 'Link GPS',
        AppLanguage.english => 'Link GPS',
      };

  String get invalidLocationPincodeError => switch (language) {
        AppLanguage.hindi => 'कृपया सही मोहल्ला और 6 अंकों का पिन कोड दर्ज करें।',
        AppLanguage.hinglish => 'Kripya valid locality aur 6 digit pincode dalein.',
        AppLanguage.english => 'Please enter a valid locality and 6-digit PIN code.',
      };

  String get selfieVerificationTitle => switch (language) {
        AppLanguage.hindi => 'लाइव सेल्फी सत्यापन',
        AppLanguage.hinglish => 'Live Selfie Verification',
        AppLanguage.english => 'Live Selfie Verification',
      };

  String get selfieVerificationSubtitle => switch (language) {
        AppLanguage.hindi => 'सुरक्षा और पहचान के लिए फ्रंट कैमरे से अपनी साफ सेल्फी लें। गैलरी फोटो मान्य नहीं है।',
        AppLanguage.hinglish => 'Suraksha aur pehchan ke liye front camera se apni saaf selfie lein. Gallery photo allow nahi hai.',
        AppLanguage.english => 'Take a clear selfie using your front camera for identity verification. Gallery photos are not permitted.',
      };

  String get selfieRulesTitle => switch (language) {
        AppLanguage.hindi => 'सेल्फी के नियम:',
        AppLanguage.hinglish => 'Selfie Rules:',
        AppLanguage.english => 'Selfie Rules:',
      };

  String get selfieRulesDesc => switch (language) {
        AppLanguage.hindi => '• अच्छी रोशनी वाले स्थान पर खड़े हों।\n• टोपी, चश्मा या मास्क न पहनें।\n• सीधा कैमरे की ओर देखें।',
        AppLanguage.hinglish => '• Acchi light me khade rahein.\n• Topi, chashma ya mask na pehnein.\n• Camera ki taraf seedha dekhein.',
        AppLanguage.english => '• Stand in good lighting.\n• Do not wear a hat, sunglasses, or mask.\n• Look directly at the camera.',
      };

  String get takeSelfieButton => switch (language) {
        AppLanguage.hindi => 'सेल्फी लें',
        AppLanguage.hinglish => 'Take Selfie',
        AppLanguage.english => 'Take Live Selfie',
      };

  String get retakePhoto => switch (language) {
        AppLanguage.hindi => 'दोबारा लें',
        AppLanguage.hinglish => 'Retake',
        AppLanguage.english => 'Retake',
      };

  String get selfieReady => switch (language) {
        AppLanguage.hindi => 'सेल्फी तैयार',
        AppLanguage.hinglish => 'Selfie Ready',
        AppLanguage.english => 'Selfie Ready',
      };

  String get compressed => switch (language) {
        AppLanguage.hindi => 'संकुचित',
        AppLanguage.hinglish => 'Compressed',
        AppLanguage.english => 'Compressed',
      };

  String get selfieRequiredError => switch (language) {
        AppLanguage.hindi => 'कृपया फ्रंट कैमरे से सेल्फी लें।',
        AppLanguage.hinglish => 'Kripya front camera se selfie lein.',
        AppLanguage.english => 'Please take a front camera selfie.',
      };

  String get cameraErrorPrefix => switch (language) {
        AppLanguage.hindi => 'कैमरा खोलने में असमर्थ: ',
        AppLanguage.hinglish => 'Camera open nahi ho saka: ',
        AppLanguage.english => 'Unable to open camera: ',
      };

  String get reviewDetailsTitle => switch (language) {
        AppLanguage.hindi => 'विवरण की समीक्षा करें',
        AppLanguage.hinglish => 'Review Details',
        AppLanguage.english => 'Review & Confirmation',
      };

  String get reviewDetailsSubtitle => switch (language) {
        AppLanguage.hindi => 'कृपया अंतिम सबमिशन से पहले सभी जानकारी की पुष्टि करें:',
        AppLanguage.hinglish => 'Kripya final submit se pehle sabhi details check karein:',
        AppLanguage.english => 'Please verify all details before final submission:',
      };

  String get instantActivationTitle => switch (language) {
        AppLanguage.hindi => 'त्वरित खाता सक्रियता',
        AppLanguage.hinglish => 'Instant Account Activation',
        AppLanguage.english => 'Instant Account Activation',
      };

  String get instantActivationDesc => switch (language) {
        AppLanguage.hindi => 'सबमिट करते ही आपका खाता सक्रिय हो जाएगा और आप सीधे गाजीपुर में उपलब्ध काम देख सकेंगे।',
        AppLanguage.hinglish => 'Submit karte hi aapka account active ho jayega aur aap kaam dekh payenge.',
        AppLanguage.english => 'Your profile activates immediately upon submission so you can start browsing jobs in Ghazipur.',
      };

  String get declarationText => switch (language) {
        AppLanguage.hindi => 'मैं प्रमाणित करता हूँ कि दी गई सभी जानकारी और सेल्फी वास्तविक एवं मेरी अपनी है।',
        AppLanguage.hinglish => 'Main certify karta hoon ki sabhi jaankari aur selfie meri apni hai.',
        AppLanguage.english => 'I confirm that all details and the selfie provided belong to me and are authentic.',
      };

  String get submitWorkerProfile => switch (language) {
        AppLanguage.hindi => 'खाता सक्रिय करें व सबमिट करें',
        AppLanguage.hinglish => 'Activate Account & Submit',
        AppLanguage.english => 'Activate Account & Submit',
      };

  String get congratulationsAccountActive => switch (language) {
        AppLanguage.hindi => 'बधाई! खाता सक्रिय हो गया!',
        AppLanguage.hinglish => 'Badhaai! Account active ho gaya!',
        AppLanguage.english => 'Congratulations! Account Activated!',
      };

  String get accountActiveDesc => switch (language) {
        AppLanguage.hindi => 'आपकी जानकारी और सेल्फी सत्यापित हो चुकी है। अब आप गाजीपुर में उपलब्ध सभी शादियों और आयोजनों के काम देख सकते हैं।',
        AppLanguage.hinglish => 'Aapki profile verify ho gayi hai. Ab aap sabhi wedding aur event jobs dekh sakte hain.',
        AppLanguage.english => 'Your profile and selfie have been verified. You can now browse all active wedding and banquet jobs across Ghazipur.',
      };

  String get browseJobsAction => switch (language) {
        AppLanguage.hindi => 'उपलब्ध काम देखें',
        AppLanguage.hinglish => 'Browse Jobs',
        AppLanguage.english => 'Browse Available Jobs',
      };

  /// Cleans and extracts a single language name if a string is in bilingual format like
  /// "Waiters (वेटर)" or "लंका (Lanka)".
  String localizedName(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'^(.*?)\s*[\(\[]\s*(.*?)\s*[\)\]]$').firstMatch(trimmed);
    if (match == null) return trimmed;

    final first = match.group(1)?.trim() ?? '';
    final second = match.group(2)?.trim() ?? '';

    final hasDevanagariFirst = RegExp(r'[\u0900-\u097F]').hasMatch(first);
    final hasDevanagariSecond = RegExp(r'[\u0900-\u097F]').hasMatch(second);

    if (language == AppLanguage.hindi) {
      if (hasDevanagariFirst) return first;
      if (hasDevanagariSecond) return second;
      return first.isNotEmpty ? first : trimmed;
    } else {
      if (!hasDevanagariFirst && first.isNotEmpty) return first;
      if (!hasDevanagariSecond && second.isNotEmpty) return second;
      return first.isNotEmpty ? first : trimmed;
    }
  }

  // ==========================================
  // Owner Onboarding
  // ==========================================
  String get ownerStep1Label => switch (language) {
        AppLanguage.hindi => 'व्यवसाय श्रेणी',
        AppLanguage.hinglish => 'Business Category',
        AppLanguage.english => 'Business Category',
      };

  String get ownerStep2Label => switch (language) {
        AppLanguage.hindi => 'व्यापार विवरण',
        AppLanguage.hinglish => 'Business Details',
        AppLanguage.english => 'Business Details',
      };

  String get ownerStep3Label => switch (language) {
        AppLanguage.hindi => 'स्थान व पता',
        AppLanguage.hinglish => 'Location & Address',
        AppLanguage.english => 'Location & Address',
      };

  String get ownerStep4Label => switch (language) {
        AppLanguage.hindi => 'दस्तावेज़ सत्यापन',
        AppLanguage.hinglish => 'Document Verification',
        AppLanguage.english => 'Document Verification',
      };

  String get ownerStep5Label => switch (language) {
        AppLanguage.hindi => 'समीक्षा व सबमिशन',
        AppLanguage.hinglish => 'Review & Submit',
        AppLanguage.english => 'Review & Submit',
      };

  String get ownerCategoryTitle => switch (language) {
        AppLanguage.hindi => 'व्यापार श्रेणी चुनें',
        AppLanguage.hinglish => 'Select Business Category',
        AppLanguage.english => 'Select Business Category',
      };

  String get ownerCategorySubtitle => switch (language) {
        AppLanguage.hindi => 'गाजीपुर में आपका मुख्य व्यापार किस प्रकार का है?',
        AppLanguage.hinglish => 'Ghazipur me aapka main business kis category ka hai?',
        AppLanguage.english => 'What is the primary category of your business in Ghazipur?',
      };

  String get selectCategoryError => switch (language) {
        AppLanguage.hindi => 'कृपया व्यापार श्रेणी चुनें।',
        AppLanguage.hinglish => 'Kripya business category select karein.',
        AppLanguage.english => 'Please select a business category.',
      };

  String get businessDetailsTitle => switch (language) {
        AppLanguage.hindi => 'व्यापार का विवरण',
        AppLanguage.hinglish => 'Business Details',
        AppLanguage.english => 'Business Details',
      };

  String get businessDetailsSubtitle => switch (language) {
        AppLanguage.hindi => 'अपने प्रतिष्ठान की बुनियादी जानकारी दर्ज करें:',
        AppLanguage.hinglish => 'Apne business ki basic details dalein:',
        AppLanguage.english => 'Enter basic details about your business:',
      };

  String get businessNameHint => switch (language) {
        AppLanguage.hindi => 'उदा. राजवाड़ा बैंक्वेट लॉन',
        AppLanguage.hinglish => 'E.g. Rajwada Banquet Lawn',
        AppLanguage.english => 'E.g. Rajwada Banquet Lawn',
      };

  String get contactPersonLabel => switch (language) {
        AppLanguage.hindi => 'मालिक / प्रबंधक का नाम*',
        AppLanguage.hinglish => 'Owner / Manager Name*',
        AppLanguage.english => 'Owner / Manager Name*',
      };

  String get contactPersonHint => switch (language) {
        AppLanguage.hindi => 'उदा. सुरेश राय',
        AppLanguage.hinglish => 'E.g. Suresh Rai',
        AppLanguage.english => 'E.g. Suresh Rai',
      };

  String get businessPhoneLabel => switch (language) {
        AppLanguage.hindi => 'व्यापार फोन नंबर*',
        AppLanguage.hinglish => 'Business Phone*',
        AppLanguage.english => 'Business Phone*',
      };

  String get businessDescriptionLabel => switch (language) {
        AppLanguage.hindi => 'व्यापार परिचय (वैकल्पिक)',
        AppLanguage.hinglish => 'Business Description (Optional)',
        AppLanguage.english => 'Business Description (Optional)',
      };

  String get businessDescriptionHint => switch (language) {
        AppLanguage.hindi => 'उदा. 1500 व्यक्तियों की क्षमता, एसी हॉल...',
        AppLanguage.hinglish => 'E.g. 1500 capacity, AC banquet hall...',
        AppLanguage.english => 'E.g. 1500 capacity, AC banquet hall...',
      };

  String get gstNumberLabel => switch (language) {
        AppLanguage.hindi => 'GSTIN (वैकल्पिक)',
        AppLanguage.hinglish => 'GSTIN (Optional)',
        AppLanguage.english => 'GSTIN (Optional)',
      };

  String get enterBusinessNameError => switch (language) {
        AppLanguage.hindi => 'कृपया व्यापार का नाम दर्ज करें।',
        AppLanguage.hinglish => 'Kripya business name dalein.',
        AppLanguage.english => 'Please enter business name.',
      };

  String get enterContactPersonError => switch (language) {
        AppLanguage.hindi => 'कृपया संपर्क व्यक्ति का नाम दर्ज करें।',
        AppLanguage.hinglish => 'Kripya contact person ka naam dalein.',
        AppLanguage.english => 'Please enter contact person name.',
      };

  String get businessLocationTitle => switch (language) {
        AppLanguage.hindi => 'व्यापार का पता व स्थान',
        AppLanguage.hinglish => 'Business Location',
        AppLanguage.english => 'Business Location',
      };

  String get businessLocationSubtitle => switch (language) {
        AppLanguage.hindi => 'गाजीपुर में आपका हॉल, कार्यालय या गोदाम कहाँ स्थित है?',
        AppLanguage.hinglish => 'Ghazipur me aapka venue ya office kahan hai?',
        AppLanguage.english => 'Where is your hall, office, or warehouse located in Ghazipur?',
      };

  String get venueAddressHint => switch (language) {
        AppLanguage.hindi => 'उदा. निकट लंका चौराहा, मेन रोड, गाजीपुर',
        AppLanguage.hinglish => 'E.g. Near Lanka Chauraha, Ghazipur',
        AppLanguage.english => 'E.g. Near Lanka Chauraha, Ghazipur',
      };

  String get businessLocalityLabel => switch (language) {
        AppLanguage.hindi => 'क्षेत्र / मोहल्ला / तहसील*',
        AppLanguage.hinglish => 'Locality / Tehsil*',
        AppLanguage.english => 'Locality / Tehsil*',
      };

  String get businessPincodeLabel => switch (language) {
        AppLanguage.hindi => 'पिन कोड*',
        AppLanguage.hinglish => 'PIN Code*',
        AppLanguage.english => 'PIN Code*',
      };

  String get enterFullAddressError => switch (language) {
        AppLanguage.hindi => 'कृपया व्यापार का पूर्ण पता दर्ज करें।',
        AppLanguage.hinglish => 'Kripya business ka full address dalein.',
        AppLanguage.english => 'Please enter full business address.',
      };

  String get enterValidPincodeError => switch (language) {
        AppLanguage.hindi => 'कृपया 6 अंकों का सही पिन कोड दर्ज करें।',
        AppLanguage.hinglish => 'Kripya valid 6 digit pincode dalein.',
        AppLanguage.english => 'Please enter a valid 6-digit PIN code.',
      };

  String get documentUploadTitle => switch (language) {
        AppLanguage.hindi => 'दस्तावेज़ सत्यापन',
        AppLanguage.hinglish => 'Document Verification',
        AppLanguage.english => 'Document Verification',
      };

  String get documentUploadSubtitle => switch (language) {
        AppLanguage.hindi => 'व्यापार की प्रामाणिकता और सुरक्षा के लिए कम से कम 1 दस्तावेज़ अपलोड करें:',
        AppLanguage.hinglish => 'Business verify karne ke liye kam se kam 1 document upload karein:',
        AppLanguage.english => 'Upload at least 1 document for business verification and trust:',
      };

  String get uploadDocumentButton => switch (language) {
        AppLanguage.hindi => 'दस्तावेज़ अपलोड करें',
        AppLanguage.hinglish => 'Upload Document',
        AppLanguage.english => 'Upload Document',
      };

  String get deleteDocumentTooltip => switch (language) {
        AppLanguage.hindi => 'हटाएं',
        AppLanguage.hinglish => 'Remove',
        AppLanguage.english => 'Remove',
      };

  String get atLeastOneDocRequiredError => switch (language) {
        AppLanguage.hindi => 'कृपया कम से कम 1 दस्तावेज़ अपलोड करें।',
        AppLanguage.hinglish => 'Kripya kam se kam 1 document upload karein.',
        AppLanguage.english => 'Please upload at least 1 document.',
      };

  String get reviewSubmissionTitle => switch (language) {
        AppLanguage.hindi => 'आवेदन की समीक्षा',
        AppLanguage.hinglish => 'Review Application',
        AppLanguage.english => 'Review Application',
      };

  String get reviewSubmissionSubtitle => switch (language) {
        AppLanguage.hindi => 'कृपया विवरण जांचें और सत्यापन के लिए सबमिट करें:',
        AppLanguage.hinglish => 'Kripya sabhi details check karein aur submit karein:',
        AppLanguage.english => 'Please review all details and submit for verification:',
      };

  String get ownerDeclaration => switch (language) {
        AppLanguage.hindi => 'मैं प्रमाणित करता हूँ कि उपरोक्त सभी जानकारी सत्य है और यह व्यापार मेरा अधिकृत प्रतिष्ठान है।',
        AppLanguage.hinglish => 'Main certify karta hoon ki ye details sahi hain aur business mera hai.',
        AppLanguage.english => 'I certify that the information provided is accurate and I am authorized to represent this business.',
      };

  String get submitOwnerApplication => switch (language) {
        AppLanguage.hindi => 'सत्यापन के लिए सबमिट करें',
        AppLanguage.hinglish => 'Submit for Verification',
        AppLanguage.english => 'Submit for Verification',
      };

  String get applicationSubmittedTitle => switch (language) {
        AppLanguage.hindi => 'आवेदन सफलतापूर्वक सबमिट हुआ!',
        AppLanguage.hinglish => 'Application successfully submit hua!',
        AppLanguage.english => 'Application Submitted Successfully!',
      };

  String get applicationSubmittedDesc => switch (language) {
        AppLanguage.hindi => 'LaganStaff व्यवस्थापक 24-48 घंटों के भीतर आपके दस्तावेजों की पुष्टि करेगा। सत्यापन के बाद आप तुरंत कार्यकर्ता बुक कर सकेंगे।',
        AppLanguage.hinglish => 'Admin 24-48 ghante me documents check karega. Verification ke baad aap workers book kar sakenge.',
        AppLanguage.english => 'LaganStaff administration will verify your documents within 24-48 hours. Once verified, you can immediately post jobs and book workers.',
      };

  // ==========================================
  // Post Job Wizard Steps
  // ==========================================
  String get jobInfoTitle => switch (language) {
        AppLanguage.hindi => 'कार्य की जानकारी दर्ज करें',
        AppLanguage.hinglish => 'Enter Job Information',
        AppLanguage.english => 'Job Information',
      };

  String get jobInfoSubtitle => switch (language) {
        AppLanguage.hindi => 'चरण 1/6 — कार्य का शीर्षक, श्रेणी और आवश्यक कार्यकर्ताओं की संख्या',
        AppLanguage.hinglish => 'Step 1/6 — Title, category & workers needed',
        AppLanguage.english => 'Step 1/6 — Title, category & workers needed',
      };

  String get jobTitleFieldLabel => switch (language) {
        AppLanguage.hindi => 'कार्य का शीर्षक*',
        AppLanguage.hinglish => 'Job Title*',
        AppLanguage.english => 'Job Title*',
      };

  String get jobTitleFieldHint => switch (language) {
        AppLanguage.hindi => 'उदा. शादी समारोह के लिए 10 अनुभवी वेटर',
        AppLanguage.hinglish => 'E.g. 10 experienced banquet waiters',
        AppLanguage.english => 'E.g. 10 experienced banquet waiters',
      };

  String get workerCategoryLabel => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ता की श्रेणी*',
        AppLanguage.hinglish => 'Worker Category*',
        AppLanguage.english => 'Worker Category*',
      };

  String get loadingCategories => switch (language) {
        AppLanguage.hindi => 'श्रेणियाँ लोड हो रही हैं...',
        AppLanguage.hinglish => 'Categories load ho rahi hain...',
        AppLanguage.english => 'Loading categories...',
      };

  String get categoryLoadError => switch (language) {
        AppLanguage.hindi => 'श्रेणी लोड करने में त्रुटि: ',
        AppLanguage.hinglish => 'Categories load karne me error: ',
        AppLanguage.english => 'Error loading categories: ',
      };

  String get requiredSkillsLabel => switch (language) {
        AppLanguage.hindi => 'आवश्यक हुनर / कौशल',
        AppLanguage.hinglish => 'Required Skills',
        AppLanguage.english => 'Required Skills',
      };

  String get noSpecificSkills => switch (language) {
        AppLanguage.hindi => 'इस श्रेणी में कोई विशिष्ट कौशल नहीं है।',
        AppLanguage.hinglish => 'Is category me koi specific skill nahi hai.',
        AppLanguage.english => 'No specific skills in this category.',
      };

  String get workersNeededLabel => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ताओं की संख्या*',
        AppLanguage.hinglish => 'Workers Needed*',
        AppLanguage.english => 'Workers Needed*',
      };

  String get workersNeededSubtitle => switch (language) {
        AppLanguage.hindi => 'कितने लोगों की जरूरत है',
        AppLanguage.hinglish => 'Kitne workers ki zaroorat hai',
        AppLanguage.english => 'How many workers required',
      };

  String get jobDescriptionFieldLabel => switch (language) {
        AppLanguage.hindi => 'कार्य का विवरण',
        AppLanguage.hinglish => 'Job Description',
        AppLanguage.english => 'Job Description',
      };

  String get jobDescriptionFieldHint => switch (language) {
        AppLanguage.hindi => 'कार्य की जिम्मेदारियां, पोशाक या कोई विशेष निर्देश दर्ज करें...',
        AppLanguage.hinglish => 'Kaam ki details, dress code ya special instructions dalein...',
        AppLanguage.english => 'Enter shift responsibilities, dress code, or special instructions...',
      };

  String get selectDateAction => switch (language) {
        AppLanguage.hindi => 'तारीख चुनें',
        AppLanguage.hinglish => 'Select Date',
        AppLanguage.english => 'Select Date',
      };

  String get dateShiftTitle => switch (language) {
        AppLanguage.hindi => 'तारीख और शिफ्ट का समय',
        AppLanguage.hinglish => 'Date & Shift Timing',
        AppLanguage.english => 'Date & Shift Timing',
      };

  String get dateShiftSubtitle => switch (language) {
        AppLanguage.hindi => 'चरण 2/6 — कार्य की तिथि, प्रारंभ/समाप्ति समय और रात की शिफ्ट की स्थिति',
        AppLanguage.hinglish => 'Step 2/6 — Date, timings & overnight shift',
        AppLanguage.english => 'Step 2/6 — Date, timings & overnight shift',
      };

  String get selectDateHelp => switch (language) {
        AppLanguage.hindi => 'कार्य की तिथि चुनें (गाजीपुर समय)',
        AppLanguage.hinglish => 'Shift Date Chunein',
        AppLanguage.english => 'Select Shift Date (Ghazipur Timezone)',
      };

  String get workDateFieldLabel => switch (language) {
        AppLanguage.hindi => 'कार्य की तिथि*',
        AppLanguage.hinglish => 'Work Date*',
        AppLanguage.english => 'Work Date*',
      };

  String get startTimeHelp => switch (language) {
        AppLanguage.hindi => 'प्रारंभ समय',
        AppLanguage.hinglish => 'Start Time',
        AppLanguage.english => 'Start Time',
      };

  String get startTimeLabel => switch (language) {
        AppLanguage.hindi => 'प्रारंभ समय*',
        AppLanguage.hinglish => 'Start Time*',
        AppLanguage.english => 'Start Time*',
      };

  String get endTimeHelp => switch (language) {
        AppLanguage.hindi => 'समाप्ति समय',
        AppLanguage.hinglish => 'End Time',
        AppLanguage.english => 'End Time',
      };

  String get endTimeLabel => switch (language) {
        AppLanguage.hindi => 'समाप्ति समय*',
        AppLanguage.hinglish => 'End Time*',
        AppLanguage.english => 'End Time*',
      };

  String get overnightShiftTitle => switch (language) {
        AppLanguage.hindi => 'रात भर की शिफ्ट (Overnight Shift)?',
        AppLanguage.hinglish => 'Overnight Shift?',
        AppLanguage.english => 'Overnight Shift?',
      };

  String get overnightShiftSubtitle => switch (language) {
        AppLanguage.hindi => 'यदि काम मध्यरात्रि के बाद (अगली सुबह) तक चलता है (जैसे शादी का खाना या विदाई)।',
        AppLanguage.hinglish => 'Agar kaam midnight ke baad agle din tak chale (jaise wedding dinner ya vidai).',
        AppLanguage.english => 'If the shift extends past midnight into next morning (e.g., wedding dinner or sendoff).',
      };

  String get paymentTitle => switch (language) {
        AppLanguage.hindi => 'मानदेय और भुगतान विवरण',
        AppLanguage.hinglish => 'Wage & Payment Details',
        AppLanguage.english => 'Wage & Payment Details',
      };

  String get wageTitle => paymentTitle;

  String get mobileNumberHint => switch (language) {
        AppLanguage.hindi => '10 अंकों का मोबाइल नंबर',
        AppLanguage.hinglish => '10-digit mobile number',
        AppLanguage.english => '10-digit mobile number',
      };

  String get cameraOption => switch (language) {
        AppLanguage.hindi => 'कैमरा',
        AppLanguage.hinglish => 'Camera',
        AppLanguage.english => 'Camera',
      };

  String get galleryOption => switch (language) {
        AppLanguage.hindi => 'गैलरी',
        AppLanguage.hinglish => 'Gallery',
        AppLanguage.english => 'Gallery',
      };

  String get paymentSubtitle => switch (language) {
        AppLanguage.hindi => 'चरण 3/6 — प्रति कार्यकर्ता मानदेय (भारतीय रुपया ₹) और भुगतान नियम',
        AppLanguage.hinglish => 'Step 3/6 — Wage per worker & payment terms',
        AppLanguage.english => 'Step 3/6 — Wage per worker & payment terms',
      };

  String get wagePerWorkerLabel => switch (language) {
        AppLanguage.hindi => 'प्रति कार्यकर्ता मानदेय*',
        AppLanguage.hinglish => 'Payment per Worker*',
        AppLanguage.english => 'Payment per Worker*',
      };

  String get perShiftSuffix => switch (language) {
        AppLanguage.hindi => '/ प्रति शिफ्ट',
        AppLanguage.hinglish => '/ per shift',
        AppLanguage.english => '/ per shift',
      };

  String get customWageLabel => switch (language) {
        AppLanguage.hindi => 'कस्टम मानदेय दर्ज करें (₹)',
        AppLanguage.hinglish => 'Custom Amount (₹)',
        AppLanguage.english => 'Custom Amount (₹)',
      };

  String get customWageHint => switch (language) {
        AppLanguage.hindi => 'उदा. 650',
        AppLanguage.hinglish => 'E.g. 650',
        AppLanguage.english => 'E.g. 650',
      };

  String get paymentNotesLabel => switch (language) {
        AppLanguage.hindi => 'भुगतान निर्देश / शर्तें (वैकल्पिक)',
        AppLanguage.hinglish => 'Payment Instructions (Optional)',
        AppLanguage.english => 'Payment Instructions (Optional)',
      };

  String get paymentNotesHint => switch (language) {
        AppLanguage.hindi => 'उदा. शिफ्ट समाप्त होते ही नकद भुगतान किया जाएगा',
        AppLanguage.hinglish => 'E.g. Cash payment immediately after shift',
        AppLanguage.english => 'E.g. Cash payment immediately after shift',
      };

  String get venueLocationTitle => switch (language) {
        AppLanguage.hindi => 'कार्य स्थल और पता',
        AppLanguage.hinglish => 'Venue & Location',
        AppLanguage.english => 'Venue & Location',
      };

  String get venueLocationSubtitle => switch (language) {
        AppLanguage.hindi => 'चरण 4/6 — स्थल का नाम (Venue), पूर्ण पता और गाजीपुर का क्षेत्र',
        AppLanguage.hinglish => 'Step 4/6 — Venue name, address & locality',
        AppLanguage.english => 'Step 4/6 — Venue name, address & locality',
      };

  String get venueNameFieldLabel => switch (language) {
        AppLanguage.hindi => 'स्थल / लॉन का नाम',
        AppLanguage.hinglish => 'Venue / Lawn Name',
        AppLanguage.english => 'Venue / Lawn Name',
      };

  String get venueNameFieldHint => switch (language) {
        AppLanguage.hindi => 'उदा. राजवाड़ा बैंक्वेट लॉन',
        AppLanguage.hinglish => 'E.g. Rajwada Banquet Lawn',
        AppLanguage.english => 'E.g. Rajwada Banquet Lawn',
      };

  String get reportingAddressFieldLabel => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ताओं के रिपोर्टिंग का पूर्ण पता*',
        AppLanguage.hinglish => 'Reporting Address*',
        AppLanguage.english => 'Reporting Full Address*',
      };

  String get reportingAddressFieldHint => switch (language) {
        AppLanguage.hindi => 'उदा. पीजी कॉलेज के पास, लंका मेन रोड, गाजीपुर',
        AppLanguage.hinglish => 'E.g. Near PG College, Lanka Main Road, Ghazipur',
        AppLanguage.english => 'E.g. Near PG College, Lanka Main Road, Ghazipur',
      };

  String get jobLocalityFieldLabel => switch (language) {
        AppLanguage.hindi => 'क्षेत्र / मोहल्ला (गाजीपुर)*',
        AppLanguage.hinglish => 'Locality in Ghazipur*',
        AppLanguage.english => 'Locality in Ghazipur*',
      };

  String get otherLocalityLabel => switch (language) {
        AppLanguage.hindi => 'या अन्य क्षेत्र का नाम दर्ज करें',
        AppLanguage.hinglish => 'Or enter custom locality',
        AppLanguage.english => 'Or enter custom locality',
      };

  String get otherLocalityHint => switch (language) {
        AppLanguage.hindi => 'उदा. मरदह या बिरनो',
        AppLanguage.hinglish => 'E.g. Mardah or Birno',
        AppLanguage.english => 'E.g. Mardah or Birno',
      };

  String get jobPincodeFieldLabel => switch (language) {
        AppLanguage.hindi => 'पिन कोड*',
        AppLanguage.hinglish => 'PIN Code*',
        AppLanguage.english => 'PIN Code*',
      };

  String get perksRequirementsTitle => switch (language) {
        AppLanguage.hindi => 'सुविधाएं और अन्य आवश्यकताएं',
        AppLanguage.hinglish => 'Perks & Requirements',
        AppLanguage.english => 'Perks & Requirements',
      };

  String get perksRequirementsSubtitle => switch (language) {
        AppLanguage.hindi => 'चरण 5/6 — भोजन, वाहन सुविधा और कार्यकर्ताओं के लिए ड्रेस/नियम',
        AppLanguage.hinglish => 'Step 5/6 — Food, transport & dress rules',
        AppLanguage.english => 'Step 5/6 — Food, transport & dress rules',
      };

  String get foodProvidedTitle => switch (language) {
        AppLanguage.hindi => 'भोजन उपलब्ध है?',
        AppLanguage.hinglish => 'Food Provided?',
        AppLanguage.english => 'Food Provided?',
      };

  String get foodProvidedSubtitle => switch (language) {
        AppLanguage.hindi => 'शिफ्ट के दौरान कार्यकर्ताओं को भोजन या चाय-नाश्ता दिया जाएगा।',
        AppLanguage.hinglish => 'Shift ke dauran workers ko food ya tea-snacks milega.',
        AppLanguage.english => 'Workers will receive meals, snacks, or refreshments during shift.',
      };

  String get foodDetailsFieldLabel => switch (language) {
        AppLanguage.hindi => 'भोजन का विवरण',
        AppLanguage.hinglish => 'Food Details',
        AppLanguage.english => 'Food Details',
      };

  String get foodDetailsFieldHint => switch (language) {
        AppLanguage.hindi => 'उदा. रात का खाना और शाम की चाय',
        AppLanguage.hinglish => 'E.g. Dinner and evening tea',
        AppLanguage.english => 'E.g. Dinner and evening tea',
      };

  String get transportProvidedTitle => switch (language) {
        AppLanguage.hindi => 'आने-जाने की सुविधा?',
        AppLanguage.hinglish => 'Transport Provided?',
        AppLanguage.english => 'Transport Provided?',
      };

  String get transportProvidedSubtitle => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ताओं को लाने और ले जाने का साधन उपलब्ध कराया जाएगा।',
        AppLanguage.hinglish => 'Workers ko pickup & drop ki facility di jayegi.',
        AppLanguage.english => 'Pickup and drop facility provided to workers.',
      };

  String get transportDetailsFieldLabel => switch (language) {
        AppLanguage.hindi => 'वाहन सुविधा का विवरण',
        AppLanguage.hinglish => 'Transport Details',
        AppLanguage.english => 'Transport Details',
      };

  String get transportDetailsFieldHint => switch (language) {
        AppLanguage.hindi => 'उदा. लंका चौराहे से पिकअप और ड्रॉप उपलब्ध है',
        AppLanguage.hinglish => 'E.g. Pickup & drop available from Lanka',
        AppLanguage.english => 'E.g. Pickup & drop available from Lanka',
      };

  String get specialRequirementsFieldLabel => switch (language) {
        AppLanguage.hindi => 'विशेष निर्देश / ड्रेस कोड',
        AppLanguage.hinglish => 'Special Instructions / Dress Code',
        AppLanguage.english => 'Special Instructions / Dress Code',
      };

  String get specialRequirementsFieldHint => switch (language) {
        AppLanguage.hindi => 'उदा. सफेद शर्ट, काली पैंट, काले जूते अनिवार्य हैं।',
        AppLanguage.hinglish => 'E.g. White shirt, black pants, black shoes mandatory.',
        AppLanguage.english => 'E.g. White shirt, black pants, black shoes mandatory.',
      };

  String get reviewJobTitle => switch (language) {
        AppLanguage.hindi => 'कार्य विवरण की समीक्षा करें',
        AppLanguage.hinglish => 'Review Job Details',
        AppLanguage.english => 'Review Job Details',
      };

  String get reviewJobSubtitle => switch (language) {
        AppLanguage.hindi => 'चरण 6/6 — कृपया सबमिट करने से पहले सभी विवरणों की पुष्टि करें',
        AppLanguage.hinglish => 'Step 6/6 — Verify details before submitting',
        AppLanguage.english => 'Step 6/6 — Verify details before submitting',
      };

  String get platformPolicyTitle => switch (language) {
        AppLanguage.hindi => 'प्लेटफ़ॉर्म सुरक्षा और अनुमोदन नीति',
        AppLanguage.hinglish => 'Platform Safety & Approval Policy',
        AppLanguage.english => 'Platform Safety & Approval Policy',
      };

  String get firstJobApprovalNotice => switch (language) {
        AppLanguage.hindi => 'यदि यह आपके व्यापार का पहला कार्य है, तो यह एडमिन समीक्षा के बाद ही प्रकाशित होगा। प्रथम कार्य स्वीकृत होने के उपरांत आगामी कार्य स्वतः तत्काल प्रकाशित होंगे।',
        AppLanguage.hinglish => 'Agar ye aapka pehla job hai, to ye admin review ke baad publish hoga. Uske baad sabhi jobs automatically publish honge.',
        AppLanguage.english => 'If this is your first job post, it will be published after admin review. Subsequent jobs will publish instantly.',
      };

  String get dateAndShiftLabel => switch (language) {
        AppLanguage.hindi => 'तारीख व शिफ्ट',
        AppLanguage.hinglish => 'Date & Shift',
        AppLanguage.english => 'Date & Shift',
      };

  String get workersNeededSummaryLabel => switch (language) {
        AppLanguage.hindi => 'आवश्यक कार्यकर्ता',
        AppLanguage.hinglish => 'Workers Needed',
        AppLanguage.english => 'Workers Needed',
      };

  String workersCountSummary(int count) => switch (language) {
        AppLanguage.hindi => '$count कार्यकर्ता',
        AppLanguage.hinglish => '$count workers',
        AppLanguage.english => '$count workers',
      };

  String get wageSummaryLabel => switch (language) {
        AppLanguage.hindi => 'मानदेय',
        AppLanguage.hinglish => 'Wage',
        AppLanguage.english => 'Wage',
      };

  String wageAmountFormatted(double amount) => switch (language) {
        AppLanguage.hindi => '₹${amount.toStringAsFixed(0)} / प्रति शिफ्ट',
        AppLanguage.hinglish => '₹${amount.toStringAsFixed(0)} / shift',
        AppLanguage.english => '₹${amount.toStringAsFixed(0)} / shift',
      };

  String get venueAddressSummaryLabel => switch (language) {
        AppLanguage.hindi => 'स्थल व पता',
        AppLanguage.hinglish => 'Venue & Address',
        AppLanguage.english => 'Venue & Address',
      };

  String get foodSummaryLabel => switch (language) {
        AppLanguage.hindi => 'भोजन सुविधा',
        AppLanguage.hinglish => 'Food Provided',
        AppLanguage.english => 'Food Provided',
      };

  String get transportSummaryLabel => switch (language) {
        AppLanguage.hindi => 'वाहन सुविधा',
        AppLanguage.hinglish => 'Transport Provided',
        AppLanguage.english => 'Transport Provided',
      };

  String get specialInstructionsSummaryLabel => switch (language) {
        AppLanguage.hindi => 'विशेष निर्देश',
        AppLanguage.hinglish => 'Special Instructions',
        AppLanguage.english => 'Special Instructions',
      };

  String get savingDraft => switch (language) {
        AppLanguage.hindi => 'सहेज रहे हैं...',
        AppLanguage.hinglish => 'Saving draft...',
        AppLanguage.english => 'Saving draft...',
      };

  String get saveDraftButton => switch (language) {
        AppLanguage.hindi => 'ड्राफ्ट सहेजें',
        AppLanguage.hinglish => 'Save Draft',
        AppLanguage.english => 'Save Draft',
      };

  String get submittingJob => switch (language) {
        AppLanguage.hindi => 'सबमिट हो रहा है...',
        AppLanguage.hinglish => 'Submitting...',
        AppLanguage.english => 'Submitting...',
      };

  String get submitJobButton => switch (language) {
        AppLanguage.hindi => 'कार्य सबमिट करें',
        AppLanguage.hinglish => 'Submit Job',
        AppLanguage.english => 'Submit Job',
      };

  // ==========================================
  // Owner Job Detail
  // ==========================================
  String get cancelJobTitle => switch (language) {
        AppLanguage.hindi => 'कार्य रद्द करें?',
        AppLanguage.hinglish => 'Cancel Job?',
        AppLanguage.english => 'Cancel Job?',
      };

  String get cancelJobConfirmationDesc => switch (language) {
        AppLanguage.hindi => 'क्या आप वाकई इस कार्य को रद्द करना चाहते हैं? रद्द करने के बाद यह कार्य कार्यकर्ताओं की सूची से तुरंत हटा दिया जाएगा।',
        AppLanguage.hinglish => 'Kya aap sach me is job ko cancel karna chahte hain? Cancel hone ke baad ye workers ki list se hat jayega.',
        AppLanguage.english => 'Are you sure you want to cancel this job? Once cancelled, it will be immediately removed from the active worker feed.',
      };

  String get updateJobDetailsTitle => switch (language) {
        AppLanguage.hindi => 'प्रकाशित कार्य विवरण अपडेट करें',
        AppLanguage.hinglish => 'Update Job Details',
        AppLanguage.english => 'Update Published Job Details',
      };

  String get updateJobDetailsDesc => switch (language) {
        AppLanguage.hindi => 'लाइव कार्य के स्थल, पता व निर्देशों में सुरक्षित संशोधन करें। मानदेय व दिनांक बदलने हेतु नया कार्य पोस्ट करें।',
        AppLanguage.hinglish => 'Live job ke venue, address aur instructions update karein. Wage aur date badalne ke liye naya job post karein.',
        AppLanguage.english => 'Update venue, address, and notes for this active job. To change date or wage, please post a new job.',
      };

  String get saveUpdatesButton => switch (language) {
        AppLanguage.hindi => 'विवरण सुरक्षित करें',
        AppLanguage.hinglish => 'Save Updates',
        AppLanguage.english => 'Save Updates',
      };

  String get updatingButton => switch (language) {
        AppLanguage.hindi => 'अपडेट हो रहा है...',
        AppLanguage.hinglish => 'Updating...',
        AppLanguage.english => 'Updating...',
      };

  String get addressAndLocalityRequired => switch (language) {
        AppLanguage.hindi => 'पता और क्षेत्र अनिवार्य हैं।',
        AppLanguage.hinglish => 'Address aur locality zaroori hain.',
        AppLanguage.english => 'Address and locality are required.',
      };

  String get jobDetailsUpdatedSuccess => switch (language) {
        AppLanguage.hindi => 'कार्य विवरण सफलतापूर्वक अपडेट कर दिया गया।',
        AppLanguage.hinglish => 'Job details successfully update ho gayi.',
        AppLanguage.english => 'Job details updated successfully.',
      };

  String get updateFailedPrefix => switch (language) {
        AppLanguage.hindi => 'अपडेट विफल: ',
        AppLanguage.hinglish => 'Update failed: ',
        AppLanguage.english => 'Update failed: ',
      };

  String get firstJobUnderReviewTitle => switch (language) {
        AppLanguage.hindi => 'प्रथम कार्य समीक्षाधीन है',
        AppLanguage.hinglish => 'First job under review',
        AppLanguage.english => 'First Job Under Review',
      };

  String get firstJobUnderReviewDesc => switch (language) {
        AppLanguage.hindi => 'LaganStaff व्यवस्थापक द्वारा समीक्षा के बाद यह कार्य प्रकाशित किया जाएगा।',
        AppLanguage.hinglish => 'Admin review ke baad ye job publish ho jayega.',
        AppLanguage.english => 'This job will be published after review by LaganStaff administration.',
      };

  String jobRejectedTitle(String reason) => switch (language) {
        AppLanguage.hindi => 'कार्य अस्वीकृत: $reason',
        AppLanguage.hinglish => 'Job Rejected: $reason',
        AppLanguage.english => 'Job Rejected: $reason',
      };

  String get shiftExpiredTitle => switch (language) {
        AppLanguage.hindi => 'शिफ्ट तिथि समाप्त',
        AppLanguage.hinglish => 'Shift Expired',
        AppLanguage.english => 'Shift Expired',
      };

  String get shiftExpiredDesc => switch (language) {
        AppLanguage.hindi => 'इस कार्य की निर्धारित तिथि बीत चुकी है। यह कार्यकर्ताओं को उपलब्ध सूची में नहीं दिख रहा है।',
        AppLanguage.hinglish => 'Is job ki date nikal chuki hai. Ye workers ko nahi dikh raha.',
        AppLanguage.english => 'The scheduled date for this shift has passed. It is no longer visible to workers.',
      };

  String get jobIsLiveTitle => switch (language) {
        AppLanguage.hindi => 'कार्य लाइव है',
        AppLanguage.hinglish => 'Job is Live',
        AppLanguage.english => 'Job is Live',
      };

  String get jobIsLiveDesc => switch (language) {
        AppLanguage.hindi => 'यह कार्य गाजीपुर के सभी सक्रिय कार्यकर्ताओं को दिख रहा है।',
        AppLanguage.hinglish => 'Ye job sabhi active workers ko dikh raha hai.',
        AppLanguage.english => 'This job is currently active and visible to all registered workers in Ghazipur.',
      };

  String get jobCancelledTitle => switch (language) {
        AppLanguage.hindi => 'कार्य रद्द कर दिया गया है',
        AppLanguage.hinglish => 'Job Cancelled',
        AppLanguage.english => 'Job Cancelled',
      };

  String get viewAttendanceRosterButton => switch (language) {
        AppLanguage.hindi => 'उपस्थिति रोस्टर देखें',
        AppLanguage.hinglish => 'View Attendance Roster',
        AppLanguage.english => 'View Attendance Roster',
      };

  String get updateJobDetailsButton => switch (language) {
        AppLanguage.hindi => 'कार्य विवरण अपडेट करें',
        AppLanguage.hinglish => 'Update Details',
        AppLanguage.english => 'Update Details',
      };

  String get cancelJobButton => switch (language) {
        AppLanguage.hindi => 'कार्य रद्द करें',
        AppLanguage.hinglish => 'Cancel Job',
        AppLanguage.english => 'Cancel Job',
      };

  String get cancellingButton => switch (language) {
        AppLanguage.hindi => 'रद्द हो रहा है...',
        AppLanguage.hinglish => 'Cancelling...',
        AppLanguage.english => 'Cancelling...',
      };

  // ==========================================
  // Owner Attendance Roster
  // ==========================================
  String get reasonOrNoteLabel => switch (language) {
        AppLanguage.hindi => 'कारण / टिप्पणी*',
        AppLanguage.hinglish => 'Reason / Note*',
        AppLanguage.english => 'Reason / Note*',
      };

  String get reasonOrNoteHint => switch (language) {
        AppLanguage.hindi => 'उदा. कार्यकर्ता समय पर उपस्थित, फोन डिस्चार्ज',
        AppLanguage.hinglish => 'E.g. Worker arrived on time',
        AppLanguage.english => 'E.g. Worker arrived on time, phone discharged',
      };

  String get reasonRequiredError => switch (language) {
        AppLanguage.hindi => 'कारण लिखना आवश्यक है।',
        AppLanguage.hinglish => 'Reason likhna zaroori hai.',
        AppLanguage.english => 'Please enter a reason or note.',
      };

  String get attendanceSummary => switch (language) {
        AppLanguage.hindi => 'उपस्थिति सारांश',
        AppLanguage.hinglish => 'Attendance Summary',
        AppLanguage.english => 'Attendance Summary',
      };

  String get confirmedWorkers => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ता सूची',
        AppLanguage.hinglish => 'Confirmed Workers',
        AppLanguage.english => 'Confirmed Workers',
      };

  String get noConfirmedWorkersTitle => switch (language) {
        AppLanguage.hindi => 'कोई पुष्ट कार्यकर्ता नहीं',
        AppLanguage.hinglish => 'Koi confirmed worker nahi',
        AppLanguage.english => 'No Confirmed Workers',
      };

  String get noConfirmedWorkersDesc => switch (language) {
        AppLanguage.hindi => 'इस कार्य के लिए फिलहाल कोई कार्यकर्ता पुष्ट नहीं है।',
        AppLanguage.hinglish => 'Is job ke liye abhi koi worker confirm nahi hai.',
        AppLanguage.english => 'No workers have been confirmed for this job yet.',
      };

  String get checkInTimePrefix => switch (language) {
        AppLanguage.hindi => 'चेक-इन समय: ',
        AppLanguage.hinglish => 'Check-in Time: ',
        AppLanguage.english => 'Check-in Time: ',
      };

  String get notePrefix => switch (language) {
        AppLanguage.hindi => 'टिप्पणी: ',
        AppLanguage.hinglish => 'Note: ',
        AppLanguage.english => 'Note: ',
      };

  String get workCompletedSuccess => switch (language) {
        AppLanguage.hindi => 'कार्य सफलतापूर्वक संपन्न हो चुका है।',
        AppLanguage.hinglish => 'Kaam successfully complete ho chuka hai.',
        AppLanguage.english => 'Work completed successfully.',
      };

  // ==========================================
  // Worker Home Screen & Job Cards
  // ==========================================
  String spotsRemainingCount(int remaining, int needed) => switch (language) {
        AppLanguage.hindi => '$remaining स्थान रिक्त ($needed आवश्यक)',
        AppLanguage.hinglish => '$remaining spots left ($needed needed)',
        AppLanguage.english => '$remaining spots left ($needed needed)',
      };

  String get shiftIsOpen => switch (language) {
        AppLanguage.hindi => 'शिफ्ट खुली है',
        AppLanguage.hinglish => 'Shift Open Hai',
        AppLanguage.english => 'Shift Open',
      };

  String get statusVerified => switch (language) {
        AppLanguage.hindi => 'सत्यापित',
        AppLanguage.hinglish => 'Verified',
        AppLanguage.english => 'Verified',
      };

  String get sessionExpired => switch (language) {
        AppLanguage.hindi => 'सत्र समाप्त हो गया है। कृपया पुनः लॉगिन करें।',
        AppLanguage.hinglish => 'Session expire ho gaya hai. Dobara login karein.',
        AppLanguage.english => 'Session expired. Please log in again.',
      };

  String get defaultErrorTitle => switch (language) {
        AppLanguage.hindi => 'कुछ गड़बड़ हुई',
        AppLanguage.hinglish => 'Kuch gadbad hui',
        AppLanguage.english => 'Something went wrong',
      };

  String get tryAgainButton => switch (language) {
        AppLanguage.hindi => 'पुनः प्रयास करें',
        AppLanguage.hinglish => 'Try Again',
        AppLanguage.english => 'Try Again',
      };

  String get notEntered => switch (language) {
        AppLanguage.hindi => 'दर्ज नहीं',
        AppLanguage.hinglish => 'Not entered',
        AppLanguage.english => 'Not entered',
      };

  String get selfieStatusLabel => switch (language) {
        AppLanguage.hindi => 'सेल्फी स्थिति',
        AppLanguage.hinglish => 'Selfie Status',
        AppLanguage.english => 'Selfie Status',
      };

  String get selfieVerifiedAndUploaded => switch (language) {
        AppLanguage.hindi => 'सत्यापित एवं अपलोड पूर्ण',
        AppLanguage.hinglish => 'Verified & Uploaded',
        AppLanguage.english => 'Verified & Uploaded',
      };

  String get selfiePendingUpload => switch (language) {
        AppLanguage.hindi => 'अपलोड प्रतीक्षित',
        AppLanguage.hinglish => 'Upload Pending',
        AppLanguage.english => 'Pending Upload',
      };

  String get ghazipurWorkerNetwork => switch (language) {
        AppLanguage.hindi => 'गाजीपुर नेटवर्क',
        AppLanguage.hinglish => 'Ghazipur Network',
        AppLanguage.english => 'Ghazipur Network',
      };

  String get workerFallbackName => switch (language) {
        AppLanguage.hindi => 'कार्यकर्ता साथी',
        AppLanguage.hinglish => 'Worker Partner',
        AppLanguage.english => 'Worker Partner',
      };

  String get confirmedLabel => switch (language) {
        AppLanguage.hindi => 'पुष्ट',
        AppLanguage.hinglish => 'Confirmed',
        AppLanguage.english => 'confirmed',
      };
}
