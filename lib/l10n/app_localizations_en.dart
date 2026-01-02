// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Drawing Archive Assistant';

  @override
  String get scanTitle => 'Archive';

  @override
  String get searchTitle => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get drawingScanSystem => 'Drawing Scan System';

  @override
  String get statusWaiting => 'Waiting for upload...';

  @override
  String get statusAnalyzing => 'AI analyzing...';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusStandby => 'Standby';

  @override
  String get tapToUpload => 'Tap button below to upload drawing';

  @override
  String get supportedFormats => 'Supports JPG, PNG formats';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get searchArchived => 'Search Archived Drawings';

  @override
  String get drawingNumber => 'Drawing Number';

  @override
  String get aiRecognized => 'AI Recognized';

  @override
  String get placeholderNumber => 'e.g., 1.0101-1100';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved successfully';

  @override
  String get saving => 'Saving...';

  @override
  String get analyzing => 'Analyzing';

  @override
  String get archiving => 'Archiving...';

  @override
  String get analyzingHint => 'Recognizing drawing number...';

  @override
  String get archivingHint => 'Archiving...';

  @override
  String get searchPlaceholder => 'Enter drawing number to search...';

  @override
  String get dateRange => 'Date Range';

  @override
  String get orderAscending => 'Ascending';

  @override
  String get orderDescending => 'Descending';

  @override
  String get status => 'Status';

  @override
  String get statusArchived => 'Archived';

  @override
  String get languageSetting => 'Language';

  @override
  String get languageHint => 'Switch app display language';

  @override
  String get themeSetting => 'Dark Mode';

  @override
  String get themeEnabled => 'Enabled';

  @override
  String get themeDisabled => 'Disabled';

  @override
  String get about => 'About';

  @override
  String get aboutApp => 'Drawing Archive Assistant';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get cloudSyncHint => 'Sync drawings to cloud';

  @override
  String get storage => 'Storage';

  @override
  String get storageHint => 'Manage local cache';

  @override
  String get help => 'Help & Feedback';

  @override
  String get helpHint => 'View user guide';

  @override
  String get aiApiConfig => 'AI API Config';

  @override
  String get aiApiConfigHint => 'Configure third-party LLM API';

  @override
  String get aiApiConfigDescription => 'Configure third-party LLM API for drawing number recognition. Recommended: Gemini 3 Flash or Gemini 3 Pro for higher accuracy.';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiKeyHint => 'Enter API Key';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get baseUrlHint => 'Enter API base URL';

  @override
  String get modelName => 'Model Name';

  @override
  String get modelNameHint => 'Enter model name';

  @override
  String get errorApiKeyRequired => 'Please enter API Key';

  @override
  String get errorBaseUrlRequired => 'Please enter Base URL';

  @override
  String get errorModelNameRequired => 'Please enter model name';

  @override
  String get saveConfig => 'Save Config';

  @override
  String get configSaved => 'Configuration saved';

  @override
  String get settingsFunction => 'Settings function coming soon';

  @override
  String get pickImageFailed => 'Failed to pick image';

  @override
  String get selectImageFirst => 'Please select an image first';

  @override
  String get enterNumber => 'Please enter or confirm drawing number';

  @override
  String get recognizeFailed => 'AI recognition failed';

  @override
  String get saveFailed => 'Save failed';

  @override
  String saveSuccess(Object count) {
    return 'Saved $count image(s)';
  }

  @override
  String get searchCompleted => 'Search completed';

  @override
  String get currentFeatureNotImplemented => 'Feature not implemented';

  @override
  String get currentDateRange => 'Current Date Range';

  @override
  String totalResults(Object count) {
    return 'Total $count results';
  }

  @override
  String get clear => 'Clear';

  @override
  String get modify => 'Modify';

  @override
  String get noResultsFound => 'No drawings found';

  @override
  String get drawingDetails => 'Drawing Details';

  @override
  String get viewDrawing => 'View Drawing';
}
