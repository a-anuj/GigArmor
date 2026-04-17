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
}
