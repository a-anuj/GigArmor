// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'हसलहाल्ट';

  @override
  String get appDescription => 'आधुनिक डिलीवरी पार्टनर के लिए आय सुरक्षा।';

  @override
  String get emailOrPhoneHint => 'ईमेल या मोबाइल नंबर';

  @override
  String get passwordHint => 'पासवर्ड';

  @override
  String get loginButton => 'लॉग इन करें';

  @override
  String get invalidCredentials => 'अमान्य क्रेडेंशियल।';

  @override
  String get registerPrompt => 'अकाउंट नहीं है? रजिस्टर करें';

  @override
  String get completeProfile => 'प्रोफ़ाइल पूरी करें';

  @override
  String get registerDescription =>
      'लगता है आप नए हैं! अपना प्रीमियम देखने के लिए रजिस्टर करें।';

  @override
  String get fullNameHint => 'पूरा नाम';

  @override
  String get phoneHint => 'फोन नंबर';

  @override
  String get emailHint => 'ईमेल पता';

  @override
  String get upiIdHint => 'UPI आईडी';

  @override
  String get registerButton => 'रजिस्टर करें और जोखिम की गणना करें';

  @override
  String coverageEstimatedFor(String name) {
    return '$name के लिए अनुमानित कवरेज';
  }

  @override
  String perWeek(String amount) {
    return '₹$amount / सप्ताह';
  }

  @override
  String get startCoverageButton => 'कवरेज शुरू करें';

  @override
  String get maybeLaterButton => 'शायद बाद में';

  @override
  String get dashboardTitle => 'डैशबोर्ड';

  @override
  String get activeCoverage => 'सक्रिय कवरेज';

  @override
  String get coverageStatusActive => 'वर्तमान में आपकी आय हानि से सुरक्षित है।';

  @override
  String get coverageStatusInactive => 'वर्तमान में आप कवर नहीं हैं।';

  @override
  String get fileClaimButton => 'दावा दायर करें';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get viewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get logout => 'लॉग आउट';

  @override
  String staySafe(String name) {
    return 'सुरक्षित रहें, $name';
  }

  @override
  String get assignedZone => 'निर्धारित क्षेत्र';

  @override
  String get platform => 'प्लेटफ़ॉर्म';

  @override
  String get liveEnvironment => 'लाइव वातावरण';

  @override
  String get loyaltyShieldCredits => 'लॉयल्टी और शील्ड क्रेडिट';

  @override
  String get rainfall => 'वर्षा';

  @override
  String get aqi => 'वायु गुणवत्ता सूचकांक';

  @override
  String get temp => 'तापमान';

  @override
  String get weeklyPremium => 'साप्ताहिक प्रीमियम:';

  @override
  String perWeekLabel(String amount) {
    return '₹$amount / सप्ताह';
  }

  @override
  String risk(String level) {
    return '$level जोखिम';
  }

  @override
  String get failedToLoadPolicy =>
      'सक्रिय नीति लोड करने में विफल। क्या आपने पंजीकरण किया है?';

  @override
  String get errorLoadingEnvironment => 'वातावरण डेटा लोड करने में त्रुटि';

  @override
  String get errorLoadingPayout => 'भुगतान इतिहास लोड करने में त्रुटि।';

  @override
  String get noPayoutsYet => 'अभी तक कोई भुगतान नहीं।';

  @override
  String get payoutCredited => 'भुगतान जमा किया गया';

  @override
  String get shieldCreditsStatus => 'शील्ड क्रेडिट स्थिति';

  @override
  String get eligibleForDiscount => 'अगले प्रीमियम पर 50% छूट के लिए पात्र!';

  @override
  String weeksUntilDiscount(String weeks, String remaining) {
    return '$weeks सप्ताह बनाए रखे। छूट मिलने में $remaining और बाकी।';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navClaims => 'Claims';

  @override
  String get navProfile => 'Profile';

  @override
  String get claimsTitle => 'Claims';

  @override
  String failedToLoadClaims(String error) {
    return 'Failed to load claims: $error';
  }

  @override
  String get noClaimsFound => 'No claims found.';

  @override
  String get statusAutoApproved => 'Auto-Approved';

  @override
  String get statusProcessingSoftHold => 'Processing Soft Hold';

  @override
  String get systemEvent => 'System Event';

  @override
  String get autoProcessedNote => 'Auto-processed based on zonal risk data.';

  @override
  String get expectedCreditUPI => 'Expected to credit via UPI soon.';

  @override
  String get resolutionPending => 'Resolution pending.';

  @override
  String get policyHistoryTitle => 'Policy History';

  @override
  String failedToLoadPolicies(String error) {
    return 'Failed to load policies: $error';
  }

  @override
  String get noPoliciesFound => 'You have no active or past policies.';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String weekOf(String date) {
    return 'Week of $date';
  }

  @override
  String validThrough(String date) {
    return 'Valid through $date';
  }

  @override
  String get coverageAmount => 'Coverage Amount';

  @override
  String coverageAmountValue(String amount) {
    return '₹$amount / day max limit';
  }

  @override
  String get policyType => 'Policy Type';

  @override
  String get parametricIncomeProtection => 'Parametric Income Protection';

  @override
  String get claimsCount => 'Claims Count';

  @override
  String get notAvailable => 'Not available';

  @override
  String get downloadPolicyDocument => 'Download Policy Document';

  @override
  String baseRiskMultiplier(String multiplier) {
    return '${multiplier}x Base Risk';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String workZone(String zone) {
    return 'Work Zone ($zone)';
  }

  @override
  String get languageMenuItem => 'Language';

  @override
  String get payoutsBilling => 'Payouts & Billing';

  @override
  String get paymentMethods => 'Payment Methods (UPI)';

  @override
  String get taxDetails => 'Tax Details';

  @override
  String get developerTools => 'Developer Tools';

  @override
  String get triggerMockSimulation => 'Trigger Mock Simulation';

  @override
  String get logOut => 'Log Out';

  @override
  String get loading => 'Loading...';

  @override
  String workerStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get identityNotVerified => 'Identity Not Verified';

  @override
  String get guestWorker => 'Guest Worker';

  @override
  String get switchWorkZone => 'Switch Work Zone';

  @override
  String errorLoadingZones(String error) {
    return 'Error loading zones: $error';
  }

  @override
  String zoneSwitched(String zone) {
    return 'Zone switched to $zone';
  }

  @override
  String failedGeneric(String error) {
    return 'Failed: $error';
  }

  @override
  String get runSimulation => 'Run Simulation';

  @override
  String get simulationDescription =>
      'This will trigger a mock heavy rainfall event. The dashboard environmental stats will update and an auto-payout notification will appear.';

  @override
  String get cancel => 'Cancel';

  @override
  String get triggerEvent => 'Trigger Event';

  @override
  String failedSimulation(String error) {
    return 'Failed simulation: $error';
  }

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get notProvided => 'Not provided';

  @override
  String get qCommercePlatform => 'Q-Commerce Platform';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String failedToUpdate(String error) {
    return 'Failed to update: $error';
  }
}
