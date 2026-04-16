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
}
