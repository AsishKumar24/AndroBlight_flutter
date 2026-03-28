// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'एंड्रोब्लाइट';

  @override
  String get tagline => 'मैलवेयर डिटेक्शन';

  @override
  String get homeWelcomeTitle => 'आज आप क्या\nस्कैन करना चाहेंगे?';

  @override
  String get homeWelcomeSubtitle =>
      'मैलवेयर के लिए विश्लेषण करने हेतु स्कैन विधि चुनें';

  @override
  String get scanApkTitle => 'APK फ़ाइल स्कैन करें';

  @override
  String get scanApkDescription =>
      'स्थानीय APK फ़ाइल अपलोड करें और विश्लेषण करें';

  @override
  String get scanPlayStoreTitle => 'Play Store ऐप स्कैन करें';

  @override
  String get scanPlayStoreDescription =>
      'Play Store URL या पैकेज नाम से विश्लेषण करें';

  @override
  String get scanMyPhoneTitle => 'मेरा फ़ोन स्कैन करें';

  @override
  String get scanMyPhoneDescription =>
      'सभी इंस्टॉल किए गए ऐप्स को मैलवेयर के लिए जाँचें';

  @override
  String get deviceStatusRooted => 'रूटेड';

  @override
  String get deviceStatusSecure => 'सुरक्षित';

  @override
  String get recCritical => '⚠️ इंस्टॉल न करें - उच्च मैलवेयर संभावना पाई गई';

  @override
  String get recHigh => '⚠️ अत्यंत सावधानी बरतें - कई जोखिम संकेतक मिले';

  @override
  String get recMedium =>
      '⚠️ इंस्टॉल करने से पहले अनुमतियों की सावधानीपूर्वक समीक्षा करें';

  @override
  String get recLow => '✅ यह एप्लिकेशन सुरक्षित प्रतीत होती है';

  @override
  String get resultLabelMalware => 'मैलवेयर';

  @override
  String get resultLabelBenign => 'सुरक्षित';

  @override
  String get multiEngineVerdicts => 'मल्टी-इंजन निर्णय';

  @override
  String get technicalMetadata => 'तकनीकी विवरण';

  @override
  String get footerPoweredBy => 'AndroBlight ग्रुप - 47 द्वारा संचालित';
}
