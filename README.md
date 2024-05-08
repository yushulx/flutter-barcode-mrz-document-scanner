# Flutter Barcode and QR Scanner Examples

This repository contains various Flutter barcode scanner projects implemented using different methods.

## Examples
- [Flutter Camera](examples/flutter_camera) (**Dart**)
    - Use the [camera](https://pub.dev/packages/camera) plugin to display camera preview and retrieve the camera frames. 
    - Use the [flutter_barcode_sdk](https://pub.dev/packages/flutter_barcode_sdk) plugin to decode barcodes from the camera frames.
    
    https://github.com/yushulx/flutter-barcode-scanner/assets/2202306/c49620d8-34e2-42f0-bd68-f674c5ef9778    

- [Native Camera](examples/native_camera) (**Dart** and **Kotlin/Swift** for best performance)
    - Implement the camera preview logic in native code. 
    - Render the app UI in **Dart**.
 
        <img src="https://www.dynamsoft.com/codepool/img/2024/04/flutter-qr-code-scanner-android-camera.jpg" width="240">

- [Dynamsoft Camera](examples/dynamsoft_camera) (**Dart**)
    - Use the [dynamsoft_capture_vision_flutter](https://pub.dev/packages/dynamsoft_capture_vision_flutter) plugin to display camera preview and decode barcodes.
        
    https://github.com/yushulx/multiple-barcode-qrcode-datamatrix-scan/assets/2202306/ed7eaec3-048b-4243-9910-3409e2d4672d
    
## Try Online Demo
[https://yushulx.me/flutter-barcode-scanner/](https://yushulx.me/flutter-barcode-scanner/)
