/// App-wide constants for the Dynamsoft Document Scanner app.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Dynamsoft License
  // ---------------------------------------------------------------------------
  /// Replace with your own Dynamsoft license key obtained from
  /// https://www.dynamsoft.com/customer/license/trialLicense
  static const String licenseKey = 'DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9';

  // ---------------------------------------------------------------------------
  // App Metadata
  // ---------------------------------------------------------------------------
  static const String appName = 'DocScan';
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  static const double defaultPadding = 16.0;
  static const double fabSize = 64.0;
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration captureDebounce = Duration(milliseconds: 500);

  // ---------------------------------------------------------------------------
  // File Export
  // ---------------------------------------------------------------------------
  static const String exportFilePrefix = 'docscan_';
  static const String exportFileExtension = '.png';
}
