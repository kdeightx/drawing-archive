import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Drawing Archive Assistant'**
  String get appTitle;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get scanTitle;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @drawingScanSystem.
  ///
  /// In en, this message translates to:
  /// **'Drawing Scan System'**
  String get drawingScanSystem;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for upload...'**
  String get statusWaiting;

  /// No description provided for @statusAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI analyzing...'**
  String get statusAnalyzing;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusStandby.
  ///
  /// In en, this message translates to:
  /// **'Standby'**
  String get statusStandby;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap button below to upload drawing'**
  String get tapToUpload;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supports JPG, PNG formats'**
  String get supportedFormats;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @searchArchived.
  ///
  /// In en, this message translates to:
  /// **'Search Archived Drawings'**
  String get searchArchived;

  /// No description provided for @drawingNumber.
  ///
  /// In en, this message translates to:
  /// **'Drawing Number'**
  String get drawingNumber;

  /// No description provided for @aiRecognized.
  ///
  /// In en, this message translates to:
  /// **'AI Recognized'**
  String get aiRecognized;

  /// No description provided for @placeholderNumber.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1.0101-1100'**
  String get placeholderNumber;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saved;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get analyzing;

  /// No description provided for @archiving.
  ///
  /// In en, this message translates to:
  /// **'Archiving...'**
  String get archiving;

  /// No description provided for @analyzingHint.
  ///
  /// In en, this message translates to:
  /// **'Recognizing drawing number...'**
  String get analyzingHint;

  /// No description provided for @archivingHint.
  ///
  /// In en, this message translates to:
  /// **'Archiving...'**
  String get archivingHint;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter drawing number to search...'**
  String get searchPlaceholder;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @orderAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get orderAscending;

  /// No description provided for @orderDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get orderDescending;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Switch app display language'**
  String get languageHint;

  /// No description provided for @themeSetting.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeSetting;

  /// No description provided for @themeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get themeEnabled;

  /// No description provided for @themeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get themeDisabled;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'Drawing Archive Assistant'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Sync drawings to cloud'**
  String get cloudSyncHint;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageHint.
  ///
  /// In en, this message translates to:
  /// **'Manage local cache'**
  String get storageHint;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get help;

  /// No description provided for @helpHint.
  ///
  /// In en, this message translates to:
  /// **'View user guide'**
  String get helpHint;

  /// No description provided for @aiApiConfig.
  ///
  /// In en, this message translates to:
  /// **'AI API Config'**
  String get aiApiConfig;

  /// No description provided for @aiApiConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Configure third-party LLM API'**
  String get aiApiConfigHint;

  /// No description provided for @aiApiConfigDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure third-party LLM API for drawing number recognition. Recommended: Gemini 3 Flash or Gemini 3 Pro for higher accuracy.'**
  String get aiApiConfigDescription;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get apiKeyHint;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @baseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API base URL'**
  String get baseUrlHint;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get modelName;

  /// No description provided for @modelNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter model name'**
  String get modelNameHint;

  /// No description provided for @errorApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter API Key'**
  String get errorApiKeyRequired;

  /// No description provided for @errorBaseUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter Base URL'**
  String get errorBaseUrlRequired;

  /// No description provided for @errorModelNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter model name'**
  String get errorModelNameRequired;

  /// No description provided for @saveConfig.
  ///
  /// In en, this message translates to:
  /// **'Save Config'**
  String get saveConfig;

  /// No description provided for @configSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configSaved;

  /// No description provided for @settingsFunction.
  ///
  /// In en, this message translates to:
  /// **'Settings function coming soon'**
  String get settingsFunction;

  /// No description provided for @pickImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get pickImageFailed;

  /// No description provided for @selectImageFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first'**
  String get selectImageFirst;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter or confirm drawing number'**
  String get enterNumber;

  /// No description provided for @recognizeFailed.
  ///
  /// In en, this message translates to:
  /// **'AI recognition failed'**
  String get recognizeFailed;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @searchCompleted.
  ///
  /// In en, this message translates to:
  /// **'Search completed'**
  String get searchCompleted;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
