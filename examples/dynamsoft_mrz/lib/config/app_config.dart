/// Central configuration for the MRZ Scanner application.
///
/// Replace [licenseKey] with your own Dynamsoft license key obtained from
/// https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform
class AppConfig {
  AppConfig._();

  /// Dynamsoft license key.
  /// The default key is a time-limited trial that requires network access.
  /// Request a 30-day full trial at:
  /// https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform
  static const String licenseKey =
      'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==';

  /// Application display name.
  static const String appName = 'MRZ Scanner';

  /// Minimum supported Android API level (matches flutter.minSdkVersion = 21).
  static const int androidMinSdk = 21;
}
