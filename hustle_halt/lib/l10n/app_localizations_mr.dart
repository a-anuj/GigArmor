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
}
