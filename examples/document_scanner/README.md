# Flutter Document Scanner

A Flutter project that demonstrates how to use [Dynamsoft Document Normalizer](https://www.dynamsoft.com/document-normalizer/docs/introduction/?ver=latest) to scan and rectify documents on Windows, Android, iOS and web.

https://github.com/yushulx/flutter_document_scan_sdk/assets/2202306/6ef5e1e0-b3c3-4767-a495-f76ceaa66f91

## Supported Platforms
- Flutter Web
    ```bash
    flutter run -d chrome
    ```
- Flutter Android or iOS
    ```bash
    flutter run
    ```
- Flutter Windows
    ```bash
    flutter run -d windows
    ```

## Getting Started
1. Apply for a [30-day trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform) and replace the license key in the `main.dart` file with your own:

    ```dart
    await flutterDocumentScanSdkPlugin.init(
          "DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==");
    ```

2. Run the project:

    ![Flutter document scanner](https://www.dynamsoft.com/codepool/img/2023/05/flutter-camera-document-scanner.png)

    ![Flutter document editor](https://www.dynamsoft.com/codepool/img/2023/05/flutter-document-edge-editor.png)
    
## Try Online Demo
https://yushulx.me/flutter-camera-document-scanner

## Blog
[Scan Documents Using Camera on Multiple Platforms: A Flutter Guide for Windows, Android, iOS, and Web](https://www.dynamsoft.com/codepool/flutter-camera-document-scanner.html)

