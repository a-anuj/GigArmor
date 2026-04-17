// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'HustleHalt';

  @override
  String get appDescription => 'நவீன டெலிவரி பார்ட்னருக்கான வருமான பாதுகாப்பு.';

  @override
  String get emailOrPhoneHint => 'மின்னஞ்சல் அல்லது மொபைல் எண்';

  @override
  String get passwordHint => 'கடவுச்சொல்';

  @override
  String get loginButton => 'உள்நுழைக';

  @override
  String get invalidCredentials => 'தவறான நற்சான்றிதழ்கள்.';

  @override
  String get registerPrompt => 'கணக்கு இல்லையா? பதிவு செய்க';

  @override
  String get completeProfile => 'சுயவிவரத்தை நிறைவு செய்க';

  @override
  String get registerDescription =>
      'நீங்கள் புதியவர் போல் தெரிகிறது! உங்கள் பிரீமியம் பார்க்க பதிவு செய்க.';

  @override
  String get fullNameHint => 'முழு பெயர்';

  @override
  String get phoneHint => 'தொலைபேசி எண்';

  @override
  String get emailHint => 'மின்னஞ்சல் முகவரி';

  @override
  String get upiIdHint => 'UPI ஐடி';

  @override
  String get registerButton => 'பதிவு செய்து ஆபத்தை கணக்கிடுக';

  @override
  String coverageEstimatedFor(String name) {
    return '$name க்கான மதிப்பிடப்பட்ட கவரேஜ்';
  }

  @override
  String perWeek(String amount) {
    return '₹$amount / வாரம்';
  }

  @override
  String get startCoverageButton => 'கவரேஜ் தொடங்குக';

  @override
  String get maybeLaterButton => 'பிறகு பார்க்கலாம்';

  @override
  String get dashboardTitle => 'டாஷ்போர்டு';

  @override
  String get activeCoverage => 'செயலில் உள்ள கவரேஜ்';

  @override
  String get coverageStatusActive =>
      'தற்போது உங்கள் வருமான இழப்பிலிருந்து பாதுகாக்கப்படுகிறீர்கள்.';

  @override
  String get coverageStatusInactive => 'தற்போது நீங்கள் கவர் செய்யப்படவில்லை.';

  @override
  String get fileClaimButton => 'கோரிக்கை தாக்கல் செய்க';

  @override
  String get recentActivity => 'சமீபத்திய செயல்பாடு';

  @override
  String get viewProfile => 'சுயவிவரம் காண்க';

  @override
  String get logout => 'வெளியேறு';

  @override
  String staySafe(String name) {
    return 'பாதுகாப்பாக இருங்கள், $name';
  }

  @override
  String get assignedZone => 'நியமிக்கப்பட்ட மண்டலம்';

  @override
  String get platform => 'தளம்';

  @override
  String get liveEnvironment => 'நேரடி சூழல்';

  @override
  String get loyaltyShieldCredits => 'லாயல்டி & ஷீல்ட் கிரெடிட்கள்';

  @override
  String get rainfall => 'மழை';

  @override
  String get aqi => 'காற்று தர குறியீடு';

  @override
  String get temp => 'வெப்பநிலை';

  @override
  String get weeklyPremium => 'வாராந்திர பிரீமியம்:';

  @override
  String perWeekLabel(String amount) {
    return '₹$amount / வாரம்';
  }

  @override
  String risk(String level) {
    return '$level ஆபத்து';
  }

  @override
  String get failedToLoadPolicy =>
      'செயலில் உள்ள பாலிசி ஏற்ற முடியவில்லை. பதிவு செய்தீர்களா?';

  @override
  String get errorLoadingEnvironment => 'சூழல் தரவை ஏற்றுவதில் பிழை';

  @override
  String get errorLoadingPayout => 'பேஅவுட் வரலாற்றை ஏற்றுவதில் பிழை.';

  @override
  String get noPayoutsYet => 'இன்னும் பேமெண்ட் வரவு வைக்கப்படவில்லை.';

  @override
  String get payoutCredited => 'பேமெண்ட் வரவு வைக்கப்பட்டது';

  @override
  String get shieldCreditsStatus => 'ஷீல்ட் கிரெடிட் நிலை';

  @override
  String get eligibleForDiscount =>
      'அடுத்த பிரீமியத்தில் 50% தள்ளுபடிக்கு தகுதியானவர்!';

  @override
  String weeksUntilDiscount(String weeks, String remaining) {
    return '$weeks வாரங்கள் பராமரிக்கப்பட்டது. தள்ளுபடிக்கு $remaining மேலும் தேவை.';
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
