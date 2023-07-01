# Flutter Barcode Scanner

A Flutter project that demonstrates how to use [Dynamsoft Barcode Reader](https://www.dynamsoft.com/barcode-reader/overview/) to scan 1D and 2D barcodes on Android, iOS, Windows, Linux, and web.

## Supported Platforms
- **Web**
- **Android**
- **iOS**
- **Windows**
- **Linux** (Without camera support)

## Getting Started
1. Apply for a [30-day trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dbr) and replace the license key in the `global.dart` file with your own:

    ```dart
    Future<int> initBarcodeSDK() async {
        int ret = await barcodeReader.setLicense(
            'LICENSE-KEY');
        await barcodeReader.init();
        await barcodeReader.setBarcodeFormats(BarcodeFormat.ALL);
        return ret;
    }
    ```

2. Run the project:

    ```
    flutter run
    # flutter run -d windows
    # flutter run -d edge
    # flutter run -d linux
    ```
    
## Try Online Demo
[https://yushulx.me/flutter-barcode-scanner/](https://yushulx.me/flutter-barcode-scanner/)