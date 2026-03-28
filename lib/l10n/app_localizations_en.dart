// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AndroBlight';

  @override
  String get tagline => 'Malware Detection';

  @override
  String get homeWelcomeTitle => 'What would you like\nto scan today?';

  @override
  String get homeWelcomeSubtitle =>
      'Choose a scan method to analyze for malware';

  @override
  String get scanApkTitle => 'Scan APK File';

  @override
  String get scanApkDescription => 'Upload and analyze a local APK file';

  @override
  String get scanPlayStoreTitle => 'Scan Play Store App';

  @override
  String get scanPlayStoreDescription =>
      'Analyze using Play Store URL or package name';

  @override
  String get scanMyPhoneTitle => 'Scan My Phone';

  @override
  String get scanMyPhoneDescription => 'Check all installed apps for malware';

  @override
  String get deviceStatusRooted => 'Rooted';

  @override
  String get deviceStatusSecure => 'Secure';

  @override
  String get recCritical =>
      '⚠️ DO NOT INSTALL - High malware probability detected';

  @override
  String get recHigh =>
      '⚠️ Exercise extreme caution - Multiple risk indicators found';

  @override
  String get recMedium => '⚠️ Review permissions carefully before installing';

  @override
  String get recLow => '✅ This application appears safe to install';

  @override
  String get resultLabelMalware => 'MALWARE';

  @override
  String get resultLabelBenign => 'BENIGN';

  @override
  String get multiEngineVerdicts => 'Multi-Engine Verdicts';

  @override
  String get technicalMetadata => 'Technical Metadata';

  @override
  String get footerPoweredBy => 'Powered by AndroBlight Group - 47';
}
