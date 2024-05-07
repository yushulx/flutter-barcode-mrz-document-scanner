# Implementing Flutter Camera Preview without Plugins
The Flutter project demonstrates how to implement a camera preview using native code and Dart.

## Prerequisites
- [Dynamsoft Barcode Reader Trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dbr) 
    
    **Android**    

    Update the license key in the `MainActivity.kt` file:

    ```dart
    fun setLicense(license: String?) {
        BarcodeReader.initLicense(license) { isSuccessful, e ->
            if (isSuccessful) {
            } else {
            }
        }
    }
    ```

    **iOS**
    
    Update the license key in the `AppDelegate.swift` file:

    ```swift
    DynamsoftBarcodeReader.initLicense("LICENSE-KEY", verificationDelegate: self)
    ```

## Why Not Use a Flutter Plugin?
Memory consumption and performance are the main reasons for not using a plugin, especially when you want to process camera frames in real-time. The communication between Dart and native code is expensive and can cause performance issues.

## Usage
The sample shows how to scan barcodes live using the Dynamsoft Barcode Reader SDK. You can replace the barcode reader with your own image processing algorithms.

Here are the steps:

**Android**

1. Open the `MainActivity.kt` file.
2. Find the method `override fun analyze(image: ImageProxy)` and replace the code with your own image processing algorithms.
3. Find the line `channel.invokeMethod("onBarcodeDetected", results)` to send the results to Dart.
4. Update the `CameraPreviewScreen.dart` file to handle the results.

**iOS**
1. Open the `AppDelegate.swift` file.
2. Find the method `func processImage(_ sampleBuffer: CMSampleBuffer)` and replace the code with your own image processing algorithms.
3. Find the line `self.channel?.invokeMethod("onBarcodeDetected", arguments: self.wrapResults(results: results))` to send the results to Dart.
4. Update the `CameraPreviewScreen.dart` file to handle the results.

## Screenshots

![Flutter iOS QR code scanner](https://www.dynamsoft.com/codepool/img/2024/05/ios-camera-flutter-qr-code-scanner.png)