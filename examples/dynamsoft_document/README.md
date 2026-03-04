# DocScan — Flutter Mobile Document Scanner

A Flutter document scanner app powered by the [Dynamsoft Capture Vision SDK](https://www.dynamsoft.com/capture-vision/docs/introduction/). Point your camera at any document — receipts, ID cards, contracts, forms — and get a clean, deskewed, perspective-corrected image in seconds.



https://github.com/user-attachments/assets/3d730b36-ca18-48b5-bb02-ea58dd2c5115



## Features

| Feature | Description |
|---|---|
| **Auto-detect boundaries** | The Dynamsoft DDN engine automatically finds the document edges in real time |
| **Manual crop adjustment** | Drag the four corner handles to fine-tune the crop region |
| **Colour-mode switching** | Toggle between full colour, grayscale, and binary (B&W) output |
| **Export to PNG** | Save the processed document to device storage with a single tap |


## Getting Started

### Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | 3.8 |
| Dart SDK | 3.8 |
| Android | API 21 (Android 5.0) |
| iOS | 13.0 |

### 1. Clone the repository

```bash
git clone https://github.com/yushulx/flutter-barcode-mrz-document-scanner.git
cd flutter-barcode-mrz-document-scanner/examples/dynamsoft_document
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure your Dynamsoft license key

Open [lib/constants.dart](lib/constants.dart) and replace the value of `licenseKey`:

```dart
static const String licenseKey = 'YOUR_LICENSE_KEY_HERE';
```

Get a **free 30-day trial key** from the [Dynamsoft Customer Portal](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform).

### 4. Run on Android

```bash
flutter run -d <device_id>
```

List connected devices with `flutter devices`.

### 5. Build a release APK

```bash
flutter build apk --release
```

> **Note:** Before publishing to the Google Play Store you must configure a proper signing key. See the [Flutter deployment guide](https://docs.flutter.dev/deployment/android) for instructions.


## Platform Configuration

### Android

The following permissions are declared in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

**Minimum SDK:** 21 (Android 5.0)

### iOS

Add the following entries to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>DocScan needs access to your camera to scan documents.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>DocScan saves scanned documents to your photo library.</string>
```

## Blog
[https://www.dynamsoft.com/codepool/flutter-document-scanner-app-android-ios.html](https://www.dynamsoft.com/codepool/flutter-document-scanner-app-android-ios.html)
