// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HustleHalt';

  @override
  String get appDescription =>
      'Income protection for the modern delivery partner.';

  @override
  String get emailOrPhoneHint => 'Email or Mobile Number';

  @override
  String get passwordHint => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get invalidCredentials => 'Invalid credentials.';

  @override
  String get registerPrompt => 'Don\'t have an account? Register';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get registerDescription =>
      'Looks like you are new! Register to see your premium.';

  @override
  String get fullNameHint => 'Full Name';

  @override
  String get phoneHint => 'Phone Number';

  @override
  String get emailHint => 'Email Address';

  @override
  String get upiIdHint => 'UPI ID';

  @override
  String get registerButton => 'Register & Calculate Risk';

  @override
  String coverageEstimatedFor(String name) {
    return 'Coverage Estimated for $name';
  }

  @override
  String perWeek(String amount) {
    return '₹$amount / week';
  }

  @override
  String get startCoverageButton => 'Start Coverage';

  @override
  String get maybeLaterButton => 'Maybe Later';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get activeCoverage => 'Active Coverage';

  @override
  String get coverageStatusActive =>
      'You are currently protected against loss of income.';

  @override
  String get coverageStatusInactive => 'You are currently not covered.';

  @override
  String get fileClaimButton => 'File a Claim';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get logout => 'Logout';

  @override
  String staySafe(String name) {
    return 'Stay Safe, $name';
  }

  @override
  String get assignedZone => 'Assigned Zone';

  @override
  String get platform => 'Platform';

  @override
  String get liveEnvironment => 'Live Environment';

  @override
  String get loyaltyShieldCredits => 'Loyalty & Shield Credits';

  @override
  String get rainfall => 'Rainfall';

  @override
  String get aqi => 'AQI';

  @override
  String get temp => 'Temp';

  @override
  String get weeklyPremium => 'Weekly Premium:';

  @override
  String perWeekLabel(String amount) {
    return '₹$amount / week';
  }

  @override
  String risk(String level) {
    return '$level RISK';
  }

  @override
  String get failedToLoadPolicy =>
      'Failed to load active policy. Have you registered?';

  @override
  String get errorLoadingEnvironment => 'Error loading environment data';

  @override
  String get errorLoadingPayout => 'Error loading payout history.';

  @override
  String get noPayoutsYet => 'No payouts credited yet.';

  @override
  String get payoutCredited => 'Payout Credited';

  @override
  String get shieldCreditsStatus => 'Shield Credits Status';

  @override
  String get eligibleForDiscount =>
      'Eligible for 50% discount on next premium!';

  @override
  String weeksUntilDiscount(String weeks, String remaining) {
    return '$weeks weeks maintained. $remaining more until discount.';
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
