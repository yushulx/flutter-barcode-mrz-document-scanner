# Flutter Barcode Scanner

A Flutter project that demonstrates how to use [Dynamsoft Barcode Reader](https://www.dynamsoft.com/barcode-reader/overview/) to scan 1D and 2D barcodes on Android, iOS, Windows, Linux, macOS and web.

## Cross-platform Barcode Scanner for Web, Windows, macOS, Linux, iOS, and Android
https://github.com/user-attachments/assets/e9447f4a-c042-419f-a6f2-e193a85b9218

## Supported Platforms
- **Web**
- **Android**
- **iOS**
- **Windows**
- **Linux** 
- **macOS**

## Getting Started
1. Apply for a [30-day trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform) and replace the license key in the `global.dart` file with your own:

    ```dart
    Future<int> initBarcodeSDK() async {
        int ret = await barcodeReader.setLicense(
            'LICENSE-KEY');
        await barcodeReader.init();
        return ret;
    }
    ```

2. Run the project:

    ```
    flutter run
    # flutter run -d windows
    # flutter run -d edge
    # flutter run -d linux
    # flutter run -d macos
    ```
    
## Try Online Demo
[https://yushulx.me/flutter-barcode-mrz-document-scanner/](https://yushulx.me/flutter-barcode-mrz-document-scanner/)

## Blog
[How to Build a Barcode Scanner App with Flutter Step by Step](https://www.dynamsoft.com/codepool/flutter-barcode-scanner-app-guide.html)
