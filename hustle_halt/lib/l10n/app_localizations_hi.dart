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
}
