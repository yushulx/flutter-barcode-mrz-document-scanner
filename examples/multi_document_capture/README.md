# DocScan — Flutter Mobile Document Scanner

A Flutter document scanner app powered by the [Dynamsoft Capture Vision SDK](https://www.dynamsoft.com/capture-vision/docs/introduction/). Point your camera at any document — receipts, ID cards, contracts, forms — and get a clean, deskewed, perspective-corrected image in seconds.

https://github.com/user-attachments/assets/8d832b58-cf8c-4d60-85cf-00df405ec189

## Features

| Feature | Description |
|---|---|
| **Real-time document detection** | Dynamsoft DDN engine detects document edges in every camera frame |
| **Auto-capture with quad stabilization** | IoU + area-delta stabilizer triggers capture when the detected quad is stable for N consecutive frames (configurable thresholds) |
| **Manual capture with fallback** | Tap the shutter button; if no document is detected within 500 ms the raw camera frame is captured instead |
| **Gallery import with fallback** | Pick an image from the gallery; if no document is detected the original image is added as-is |
| **Manual crop adjustment** | Drag corner handles on the edit page to fine-tune the crop region |
| **Colour-mode switching** | Toggle between full colour, grayscale, and binary (B/W) on the result page |
| **Rotation** | Rotate any page 90° clockwise; rotation is baked into the exported bytes |
| **Multi-page support** | Capture multiple pages, reorder them with drag-and-drop, and delete individual pages |
| **Export as images** | Save all pages as PNG images to the device **system gallery** (via MediaStore on Android) |
| **Export as PDF** | Generate a multi-page PDF (A4) and save it to the app's **documents directory** |


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
git clone https://github.com/yushulx/android-camera-barcode-mrz-document-scanner.git
cd examples/multi_document_capture
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

> **Note:** Before publishing to the Google Play Store you must configure a proper signing key. See the [Flutter deployment guide](https://docs.flutter.dev/deployment/android) for details.


## Architecture

```
lib/
├── main.dart             # App entry point, MaterialApp setup
├── constants.dart        # License key, app name, export prefix
├── app_theme.dart        # Dark theme colours and ThemeData
├── scan_page.dart        # Camera view with capture, gallery, settings
├── quad_stabilizer.dart  # IoU + area-delta auto-capture stabilizer
├── result_page.dart      # Page viewer, toolbar, filters, export
├── edit_page.dart        # Quad corner adjustment overlay
├── sort_pages_page.dart  # Drag-to-reorder multi-page list
└── document_page.dart    # Page model (ImageData, rotation, colour mode)
```

### Key workflows

| Workflow | Description |
|---|---|
| **Auto-capture** | `CapturedResultReceiver` feeds every cross-verified quad to `QuadStabilizer`. After `stableFrameCount` consecutive frames with IoU ≥ `iouThreshold` and area delta ≤ `areaDeltaThreshold`, the stabilizer fires `onStable` and the current frame is captured. |
| **Manual capture** | On shutter press, `_isBtnClicked` is set and a 500 ms timer starts. If the receiver delivers a detection within that window, it is used immediately. Otherwise `_captureRawFrame()` grabs the current `CameraEnhancer.getImage()` frame as a fallback page. |
| **Gallery import** | `image_picker` selects a file → `CaptureVisionRouter.captureFile()` processes it. If `deskewedImageResultItems` is empty, the original image is added directly. |
| **Save images** | `image_gallery_saver_plus` writes each page's PNG bytes to the system gallery (MediaStore on Android). |
| **Save PDF** | The `pdf` package generates a multi-page A4 PDF; pages are written to `getApplicationDocumentsDirectory()/documents/`. |


## Dependencies

| Package | Purpose |
|---|---|
| [dynamsoft_capture_vision_flutter](https://pub.dev/packages/dynamsoft_capture_vision_flutter) | Document detection, deskew, and image processing |
| [image_picker](https://pub.dev/packages/image_picker) | Gallery image selection |
| [image_gallery_saver_plus](https://pub.dev/packages/image_gallery_saver_plus) | Save images to system gallery |
| [pdf](https://pub.dev/packages/pdf) | PDF generation |
| [path_provider](https://pub.dev/packages/path_provider) | App directory paths |
| [permission_handler](https://pub.dev/packages/permission_handler) | Runtime permissions |


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
<key>NSPhotoLibraryAddUsageDescription</key>
<string>DocScan saves scanned documents to your photo library.</string>
```


## Stabilization Settings

Open the settings dialog from the camera page (gear icon, top-right) to adjust:

| Setting | Default | Range | Description |
|---|---|---|---|
| Auto Capture | On | On / Off | Enable or disable auto-capture |
| IoU Threshold | 0.85 | 0.50 – 1.00 | Minimum bounding-box Intersection over Union between consecutive frames |
| Area Delta Threshold | 0.15 | 0.01 – 0.50 | Maximum relative change in quad area between consecutive frames |
| Stable Frame Count | 3 | 1 – 10 | Number of consecutive stable frames before auto-capture fires |
