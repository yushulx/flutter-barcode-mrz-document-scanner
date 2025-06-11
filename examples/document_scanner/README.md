# Flutter Document Scanner

A Flutter project that demonstrates how to use [flutter_document_scan_sdk](https://pub.dev/packages/flutter_document_scan_sdk) to scan and rectify documents on Windows, Android, iOS and web.

https://github.com/user-attachments/assets/c6584bbe-0801-4379-a44f-ba982f432f34

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
    

## Blog
[Scan Documents Using Camera on Multiple Platforms: A Flutter Guide for Windows, Android, iOS, and Web](https://www.dynamsoft.com/codepool/flutter-camera-document-scanner.html)

