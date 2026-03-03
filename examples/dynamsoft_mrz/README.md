# MRZ Scanner – Flutter

A **production-ready** Flutter mobile app that reads Machine Readable Zone (MRZ) data from passports, ID cards, and other ICAO-compliant travel documents using the [Dynamsoft MRZ Scanner SDK](https://www.dynamsoft.com/use-cases/mrz-scanner/).


## Features

- Instant MRZ recognition via the device camera
- Supports **TD1** (3-line ID), **TD2** (2×36 char ID), and **TD3** (passport) formats
- Parses all ICAO fields: name, sex, age, document number, issuing state, nationality, date of birth, date of expiry
- Dedicated result screen with clean field-by-field display


## Requirements

### Development tools

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.8 |
| Dart SDK | ≥ 3.8 |
| Android Studio / VS Code | Latest |
| Xcode (iOS only) | Latest |

### Mobile platform support

| Platform | Minimum version |
|----------|----------------|
| Android | 5.0 (API 21) |
| iOS | 13.0 |


## Getting started

### 1 — Clone and fetch dependencies

```bash
git clone https://github.com/yushulx/flutter-barcode-mrz-document-scanner.git
cd flutter-barcode-mrz-document-scanner/examples/dynamsoft_mrz
flutter pub get
```

### 2 — Configure your license key

Open [`lib/config/app_config.dart`](lib/config/app_config.dart) and replace the value of `licenseKey` with your own key.

The bundled key is a **time-limited trial** that requires a network connection. Request a free 30-day full trial at:
<https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform>

### 3 — Run on Android

Connect a physical device (API 21+) and run:

```bash
flutter run -d <DEVICE_ID>
```

List connected devices with `flutter devices`.

### 4 — Run on iOS

```bash
cd ios/
pod install --repo-update
cd ..
```

Open `ios/Runner.xcworkspace` in Xcode, configure your *Team* under *Signing & Capabilities*, then build and run.


## Build for release

### Android

```bash
flutter build apk --release
# or for the Play Store:
flutter build appbundle --release
```

> **Note** Add your own signing config in `android/app/build.gradle.kts` before publishing.

### iOS

Build and archive via Xcode (`Product → Archive`) after setting your provisioning profile.




