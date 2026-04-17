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
}
