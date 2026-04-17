// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'HustleHalt';

  @override
  String get appDescription => 'आधुनिक डिलिव्हरी पार्टनरसाठी उत्पन्न संरक्षण.';

  @override
  String get emailOrPhoneHint => 'ईमेल किंवा मोबाईल नंबर';

  @override
  String get passwordHint => 'पासवर्ड';

  @override
  String get loginButton => 'लॉग इन करा';

  @override
  String get invalidCredentials => 'अवैध प्रमाणपत्रे.';

  @override
  String get registerPrompt => 'खाते नाही? नोंदणी करा';

  @override
  String get completeProfile => 'प्रोफाइल पूर्ण करा';

  @override
  String get registerDescription =>
      'असे दिसते की तुम्ही नवीन आहात! तुमचा प्रीमियम पाहण्यासाठी नोंदणी करा.';

  @override
  String get fullNameHint => 'पूर्ण नाव';

  @override
  String get phoneHint => 'फोन नंबर';

  @override
  String get emailHint => 'ईमेल पत्ता';

  @override
  String get upiIdHint => 'UPI आयडी';

  @override
  String get registerButton => 'नोंदणी करा आणि जोखीम मोजा';

  @override
  String coverageEstimatedFor(String name) {
    return '$name साठी अंदाजित कव्हरेज';
  }

  @override
  String perWeek(String amount) {
    return '₹$amount / आठवडा';
  }

  @override
  String get startCoverageButton => 'कव्हरेज सुरू करा';

  @override
  String get maybeLaterButton => 'कदाचित नंतर';

  @override
  String get dashboardTitle => 'डॅशबोर्ड';

  @override
  String get activeCoverage => 'सक्रिय कव्हरेज';

  @override
  String get coverageStatusActive =>
      'तुम्ही सध्या उत्पन्न गमावण्यापासून संरक्षित आहात.';

  @override
  String get coverageStatusInactive => 'तुम्ही सध्या कव्हर केलेले नाही.';

  @override
  String get fileClaimButton => 'दावा दाखल करा';

  @override
  String get recentActivity => 'अलीकडील क्रियाकलाप';

  @override
  String get viewProfile => 'प्रोफाइल पहा';

  @override
  String get logout => 'लॉग आउट';

  @override
  String staySafe(String name) {
    return 'सुरक्षित राहा, $name';
  }

  @override
  String get assignedZone => 'नियुक्त क्षेत्र';

  @override
  String get platform => 'प्लॅटफॉर्म';

  @override
  String get liveEnvironment => 'लाइव्ह वातावरण';

  @override
  String get loyaltyShieldCredits => 'लॉयल्टी आणि शील्ड क्रेडिट्स';

  @override
  String get rainfall => 'पाऊस';

  @override
  String get aqi => 'हवा गुणवत्ता निर्देशांक';

  @override
  String get temp => 'तापमान';

  @override
  String get weeklyPremium => 'साप्ताहिक प्रीमियम:';

  @override
  String perWeekLabel(String amount) {
    return '₹$amount / आठवडा';
  }

  @override
  String risk(String level) {
    return '$level जोखीम';
  }

  @override
  String get failedToLoadPolicy =>
      'सक्रिय पॉलिसी लोड करण्यात अयशस्वी. तुम्ही नोंदणी केली का?';

  @override
  String get errorLoadingEnvironment => 'वातावरण डेटा लोड करण्यात त्रुटी';

  @override
  String get errorLoadingPayout => 'पेआउट इतिहास लोड करण्यात त्रुटी.';

  @override
  String get noPayoutsYet => 'अद्याप कोणतेही पेमेंट जमा झाले नाही.';

  @override
  String get payoutCredited => 'पेमेंट जमा झाले';

  @override
  String get shieldCreditsStatus => 'शील्ड क्रेडिट स्थिती';

  @override
  String get eligibleForDiscount => 'पुढील प्रीमियमवर 50% सूट मिळण्यास पात्र!';

  @override
  String weeksUntilDiscount(String weeks, String remaining) {
    return '$weeks आठवडे राखले. सूटीसाठी $remaining आणखी बाकी.';
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
