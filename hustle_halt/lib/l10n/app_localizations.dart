import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HustleHalt'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Income protection for the modern delivery partner.'**
  String get appDescription;

  /// No description provided for @emailOrPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Email or Mobile Number'**
  String get emailOrPhoneHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials.'**
  String get invalidCredentials;

  /// No description provided for @registerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get registerPrompt;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @registerDescription.
  ///
  /// In en, this message translates to:
  /// **'Looks like you are new! Register to see your premium.'**
  String get registerDescription;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameHint;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailHint;

  /// No description provided for @upiIdHint.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiIdHint;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register & Calculate Risk'**
  String get registerButton;

  /// No description provided for @coverageEstimatedFor.
  ///
  /// In en, this message translates to:
  /// **'Coverage Estimated for {name}'**
  String coverageEstimatedFor(String name);

  /// No description provided for @perWeek.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} / week'**
  String perWeek(String amount);

  /// No description provided for @startCoverageButton.
  ///
  /// In en, this message translates to:
  /// **'Start Coverage'**
  String get startCoverageButton;

  /// No description provided for @maybeLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLaterButton;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @activeCoverage.
  ///
  /// In en, this message translates to:
  /// **'Active Coverage'**
  String get activeCoverage;

  /// No description provided for @coverageStatusActive.
  ///
  /// In en, this message translates to:
  /// **'You are currently protected against loss of income.'**
  String get coverageStatusActive;

  /// No description provided for @coverageStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'You are currently not covered.'**
  String get coverageStatusInactive;

  /// No description provided for @fileClaimButton.
  ///
  /// In en, this message translates to:
  /// **'File a Claim'**
  String get fileClaimButton;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @staySafe.
  ///
  /// In en, this message translates to:
  /// **'Stay Safe, {name}'**
  String staySafe(String name);

  /// No description provided for @assignedZone.
  ///
  /// In en, this message translates to:
  /// **'Assigned Zone'**
  String get assignedZone;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @liveEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Live Environment'**
  String get liveEnvironment;

  /// No description provided for @loyaltyShieldCredits.
  ///
  /// In en, this message translates to:
  /// **'Loyalty & Shield Credits'**
  String get loyaltyShieldCredits;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfall;

  /// No description provided for @aqi.
  ///
  /// In en, this message translates to:
  /// **'AQI'**
  String get aqi;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temp;

  /// No description provided for @weeklyPremium.
  ///
  /// In en, this message translates to:
  /// **'Weekly Premium:'**
  String get weeklyPremium;

  /// No description provided for @perWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} / week'**
  String perWeekLabel(String amount);

  /// No description provided for @risk.
  ///
  /// In en, this message translates to:
  /// **'{level} RISK'**
  String risk(String level);

  /// No description provided for @failedToLoadPolicy.
  ///
  /// In en, this message translates to:
  /// **'Failed to load active policy. Have you registered?'**
  String get failedToLoadPolicy;

  /// No description provided for @errorLoadingEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Error loading environment data'**
  String get errorLoadingEnvironment;

  /// No description provided for @errorLoadingPayout.
  ///
  /// In en, this message translates to:
  /// **'Error loading payout history.'**
  String get errorLoadingPayout;

  /// No description provided for @noPayoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No payouts credited yet.'**
  String get noPayoutsYet;

  /// No description provided for @payoutCredited.
  ///
  /// In en, this message translates to:
  /// **'Payout Credited'**
  String get payoutCredited;

  /// No description provided for @shieldCreditsStatus.
  ///
  /// In en, this message translates to:
  /// **'Shield Credits Status'**
  String get shieldCreditsStatus;

  /// No description provided for @eligibleForDiscount.
  ///
  /// In en, this message translates to:
  /// **'Eligible for 50% discount on next premium!'**
  String get eligibleForDiscount;

  /// No description provided for @weeksUntilDiscount.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks maintained. {remaining} more until discount.'**
  String weeksUntilDiscount(String weeks, String remaining);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navClaims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get navClaims;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @claimsTitle.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get claimsTitle;

  /// No description provided for @failedToLoadClaims.
  ///
  /// In en, this message translates to:
  /// **'Failed to load claims: {error}'**
  String failedToLoadClaims(String error);

  /// No description provided for @noClaimsFound.
  ///
  /// In en, this message translates to:
  /// **'No claims found.'**
  String get noClaimsFound;

  /// No description provided for @statusAutoApproved.
  ///
  /// In en, this message translates to:
  /// **'Auto-Approved'**
  String get statusAutoApproved;

  /// No description provided for @statusProcessingSoftHold.
  ///
  /// In en, this message translates to:
  /// **'Processing Soft Hold'**
  String get statusProcessingSoftHold;

  /// No description provided for @systemEvent.
  ///
  /// In en, this message translates to:
  /// **'System Event'**
  String get systemEvent;

  /// No description provided for @autoProcessedNote.
  ///
  /// In en, this message translates to:
  /// **'Auto-processed based on zonal risk data.'**
  String get autoProcessedNote;

  /// No description provided for @expectedCreditUPI.
  ///
  /// In en, this message translates to:
  /// **'Expected to credit via UPI soon.'**
  String get expectedCreditUPI;

  /// No description provided for @resolutionPending.
  ///
  /// In en, this message translates to:
  /// **'Resolution pending.'**
  String get resolutionPending;

  /// No description provided for @policyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Policy History'**
  String get policyHistoryTitle;

  /// No description provided for @failedToLoadPolicies.
  ///
  /// In en, this message translates to:
  /// **'Failed to load policies: {error}'**
  String failedToLoadPolicies(String error);

  /// No description provided for @noPoliciesFound.
  ///
  /// In en, this message translates to:
  /// **'You have no active or past policies.'**
  String get noPoliciesFound;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(String date);

  /// No description provided for @validThrough.
  ///
  /// In en, this message translates to:
  /// **'Valid through {date}'**
  String validThrough(String date);

  /// No description provided for @coverageAmount.
  ///
  /// In en, this message translates to:
  /// **'Coverage Amount'**
  String get coverageAmount;

  /// No description provided for @coverageAmountValue.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} / day max limit'**
  String coverageAmountValue(String amount);

  /// No description provided for @policyType.
  ///
  /// In en, this message translates to:
  /// **'Policy Type'**
  String get policyType;

  /// No description provided for @parametricIncomeProtection.
  ///
  /// In en, this message translates to:
  /// **'Parametric Income Protection'**
  String get parametricIncomeProtection;

  /// No description provided for @claimsCount.
  ///
  /// In en, this message translates to:
  /// **'Claims Count'**
  String get claimsCount;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @downloadPolicyDocument.
  ///
  /// In en, this message translates to:
  /// **'Download Policy Document'**
  String get downloadPolicyDocument;

  /// No description provided for @baseRiskMultiplier.
  ///
  /// In en, this message translates to:
  /// **'{multiplier}x Base Risk'**
  String baseRiskMultiplier(String multiplier);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @workZone.
  ///
  /// In en, this message translates to:
  /// **'Work Zone ({zone})'**
  String workZone(String zone);

  /// No description provided for @languageMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageMenuItem;

  /// No description provided for @payoutsBilling.
  ///
  /// In en, this message translates to:
  /// **'Payouts & Billing'**
  String get payoutsBilling;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods (UPI)'**
  String get paymentMethods;

  /// No description provided for @taxDetails.
  ///
  /// In en, this message translates to:
  /// **'Tax Details'**
  String get taxDetails;

  /// No description provided for @developerTools.
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get developerTools;

  /// No description provided for @triggerMockSimulation.
  ///
  /// In en, this message translates to:
  /// **'Trigger Mock Simulation'**
  String get triggerMockSimulation;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @workerStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String workerStatus(String status);

  /// No description provided for @identityNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity Not Verified'**
  String get identityNotVerified;

  /// No description provided for @guestWorker.
  ///
  /// In en, this message translates to:
  /// **'Guest Worker'**
  String get guestWorker;

  /// No description provided for @switchWorkZone.
  ///
  /// In en, this message translates to:
  /// **'Switch Work Zone'**
  String get switchWorkZone;

  /// No description provided for @errorLoadingZones.
  ///
  /// In en, this message translates to:
  /// **'Error loading zones: {error}'**
  String errorLoadingZones(String error);

  /// No description provided for @zoneSwitched.
  ///
  /// In en, this message translates to:
  /// **'Zone switched to {zone}'**
  String zoneSwitched(String zone);

  /// No description provided for @failedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedGeneric(String error);

  /// No description provided for @runSimulation.
  ///
  /// In en, this message translates to:
  /// **'Run Simulation'**
  String get runSimulation;

  /// No description provided for @simulationDescription.
  ///
  /// In en, this message translates to:
  /// **'This will trigger a mock heavy rainfall event. The dashboard environmental stats will update and an auto-payout notification will appear.'**
  String get simulationDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @triggerEvent.
  ///
  /// In en, this message translates to:
  /// **'Trigger Event'**
  String get triggerEvent;

  /// No description provided for @failedSimulation.
  ///
  /// In en, this message translates to:
  /// **'Failed simulation: {error}'**
  String failedSimulation(String error);

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @qCommercePlatform.
  ///
  /// In en, this message translates to:
  /// **'Q-Commerce Platform'**
  String get qCommercePlatform;

  /// No description provided for @upiIdLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiIdLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String failedToUpdate(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
