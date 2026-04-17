// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'HustleHalt';

  @override
  String get appDescription => 'ఆధునిక డెలివరీ పార్ట్‌నర్ కోసం ఆదాయ రక్షణ.';

  @override
  String get emailOrPhoneHint => 'ఇమెయిల్ లేదా మొబైల్ నంబర్';

  @override
  String get passwordHint => 'పాస్‌వర్డ్';

  @override
  String get loginButton => 'లాగిన్';

  @override
  String get invalidCredentials => 'చెల్లని ఆధారాలు.';

  @override
  String get registerPrompt => 'ఖాతా లేదా? నమోదు చేయండి';

  @override
  String get completeProfile => 'ప్రొఫైల్ పూర్తి చేయండి';

  @override
  String get registerDescription =>
      'మీరు కొత్తవారు అనిపిస్తోంది! మీ ప్రీమియం చూడటానికి నమోదు చేయండి.';

  @override
  String get fullNameHint => 'పూర్తి పేరు';

  @override
  String get phoneHint => 'ఫోన్ నంబర్';

  @override
  String get emailHint => 'ఇమెయిల్ చిరునామా';

  @override
  String get upiIdHint => 'UPI ID';

  @override
  String get registerButton => 'నమోదు చేసి రిస్క్ లెక్కించండి';

  @override
  String coverageEstimatedFor(String name) {
    return '$name కోసం అంచనా వేయబడిన కవరేజ్';
  }

  @override
  String perWeek(String amount) {
    return '₹$amount / వారానికి';
  }

  @override
  String get startCoverageButton => 'కవరేజ్ ప్రారంభించండి';

  @override
  String get maybeLaterButton => 'తర్వాత చూద్దాం';

  @override
  String get dashboardTitle => 'డ్యాష్‌బోర్డ్';

  @override
  String get activeCoverage => 'యాక్టివ్ కవరేజ్';

  @override
  String get coverageStatusActive =>
      'మీరు ప్రస్తుతం ఆదాయ నష్టం నుండి రక్షించబడ్డారు.';

  @override
  String get coverageStatusInactive => 'మీరు ప్రస్తుతం కవర్ చేయబడలేదు.';

  @override
  String get fileClaimButton => 'క్లెయిమ్ దాఖలు చేయండి';

  @override
  String get recentActivity => 'ఇటీవలి కార్యకలాపం';

  @override
  String get viewProfile => 'ప్రొఫైల్ చూడండి';

  @override
  String get logout => 'లాగ్అవుట్';

  @override
  String staySafe(String name) {
    return 'సురక్షితంగా ఉండండి, $name';
  }

  @override
  String get assignedZone => 'నిర్ణయించబడిన జోన్';

  @override
  String get platform => 'ప్లాట్‌ఫారమ్';

  @override
  String get liveEnvironment => 'లైవ్ వాతావరణం';

  @override
  String get loyaltyShieldCredits => 'లాయల్టీ & షీల్డ్ క్రెడిట్లు';

  @override
  String get rainfall => 'వర్షపాతం';

  @override
  String get aqi => 'వాయు నాణ్యత సూచిక';

  @override
  String get temp => 'ఉష్ణోగ్రత';

  @override
  String get weeklyPremium => 'వారపు ప్రీమియం:';

  @override
  String perWeekLabel(String amount) {
    return '₹$amount / వారానికి';
  }

  @override
  String risk(String level) {
    return '$level రిస్క్';
  }

  @override
  String get failedToLoadPolicy =>
      'యాక్టివ్ పాలసీ లోడ్ చేయడం విఫలమైంది. మీరు నమోదు చేశారా?';

  @override
  String get errorLoadingEnvironment => 'వాతావరణ డేటా లోడ్ చేయడంలో లోపం';

  @override
  String get errorLoadingPayout => 'పేఅవుట్ చరిత్ర లోడ్ చేయడంలో లోపం.';

  @override
  String get noPayoutsYet => 'ఇంకా పేమెంట్లు జమ కాలేదు.';

  @override
  String get payoutCredited => 'పేమెంట్ జమ చేయబడింది';

  @override
  String get shieldCreditsStatus => 'షీల్డ్ క్రెడిట్ స్థితి';

  @override
  String get eligibleForDiscount => 'తదుపరి ప్రీమియంపై 50% తగ్గింపుకు అర్హులు!';

  @override
  String weeksUntilDiscount(String weeks, String remaining) {
    return '$weeks వారాలు నిర్వహించారు. తగ్గింపుకు $remaining మరిన్ని అవసరం.';
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
