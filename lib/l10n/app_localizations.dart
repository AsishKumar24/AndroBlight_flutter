import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'AndroBlight'**
  String get appTitle;

  /// Subtitle on home screen
  ///
  /// In en, this message translates to:
  /// **'Malware Detection'**
  String get tagline;

  /// Home screen heading
  ///
  /// In en, this message translates to:
  /// **'What would you like\nto scan today?'**
  String get homeWelcomeTitle;

  /// Home screen subheading
  ///
  /// In en, this message translates to:
  /// **'Choose a scan method to analyze for malware'**
  String get homeWelcomeSubtitle;

  /// APK scan card title
  ///
  /// In en, this message translates to:
  /// **'Scan APK File'**
  String get scanApkTitle;

  /// APK scan card description
  ///
  /// In en, this message translates to:
  /// **'Upload and analyze a local APK file'**
  String get scanApkDescription;

  /// Play Store scan card title
  ///
  /// In en, this message translates to:
  /// **'Scan Play Store App'**
  String get scanPlayStoreTitle;

  /// Play Store scan card description
  ///
  /// In en, this message translates to:
  /// **'Analyze using Play Store URL or package name'**
  String get scanPlayStoreDescription;

  /// Installed apps scan card title
  ///
  /// In en, this message translates to:
  /// **'Scan My Phone'**
  String get scanMyPhoneTitle;

  /// Installed apps scan card description
  ///
  /// In en, this message translates to:
  /// **'Check all installed apps for malware'**
  String get scanMyPhoneDescription;

  /// Badge label for rooted device
  ///
  /// In en, this message translates to:
  /// **'Rooted'**
  String get deviceStatusRooted;

  /// Badge label for secure device
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get deviceStatusSecure;

  /// No description provided for @recCritical.
  ///
  /// In en, this message translates to:
  /// **'⚠️ DO NOT INSTALL - High malware probability detected'**
  String get recCritical;

  /// No description provided for @recHigh.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Exercise extreme caution - Multiple risk indicators found'**
  String get recHigh;

  /// No description provided for @recMedium.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Review permissions carefully before installing'**
  String get recMedium;

  /// No description provided for @recLow.
  ///
  /// In en, this message translates to:
  /// **'✅ This application appears safe to install'**
  String get recLow;

  /// No description provided for @resultLabelMalware.
  ///
  /// In en, this message translates to:
  /// **'MALWARE'**
  String get resultLabelMalware;

  /// No description provided for @resultLabelBenign.
  ///
  /// In en, this message translates to:
  /// **'BENIGN'**
  String get resultLabelBenign;

  /// No description provided for @multiEngineVerdicts.
  ///
  /// In en, this message translates to:
  /// **'Multi-Engine Verdicts'**
  String get multiEngineVerdicts;

  /// No description provided for @technicalMetadata.
  ///
  /// In en, this message translates to:
  /// **'Technical Metadata'**
  String get technicalMetadata;

  /// No description provided for @footerPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by AndroBlight Group - 47'**
  String get footerPoweredBy;
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
      <String>['en', 'hi'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
