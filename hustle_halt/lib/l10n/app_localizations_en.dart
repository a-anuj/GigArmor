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
}
