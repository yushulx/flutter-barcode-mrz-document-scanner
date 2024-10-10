# App Prototype: Last Mile Delivery 

A Flutter project demonstrating how to implement a prototype for a last-mile delivery app using [Dynamsoft Barcode Reader](https://www.dynamsoft.com/barcode-reader/overview/), [Dyanmsoft Label Recognizer](https://www.dynamsoft.com/label-recognition/overview/) and [Dynamsoft Document Normalizer](https://www.dynamsoft.com/document-normalizer/docs/introduction/?ver=latest).

https://github.com/yushulx/flutter-last-mile-delivery/assets/2202306/78af0028-7620-4c30-a91e-bc67c9c22c5a

## Supported Platforms
- Windows
- Android
- iOS
- Web

## Dependencies
- [flutter_barcode_sdk](https://pub.dev/packages/flutter_barcode_sdk)
- [flutter_ocr_sdk](https://pub.dev/packages/flutter_ocr_sdk)
- [flutter_document_scan_sdk](https://pub.dev/packages/flutter_document_scan_sdk)

## License Key
Apply for a [license key](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform) and update the following lines in `global.dart`:

```dart
Future<void> initBarcodeSDK() async {
  await barcodeReader.setLicense(
      'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
  await barcodeReader.init();
  await barcodeReader.setBarcodeFormats(BarcodeFormat.ALL);
}

Future<void> initMRZSDK() async {
  await mrzDetector.init(
      "DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==");
  await mrzDetector.loadModel();
}

Future<void> initDocumentSDK() async {
  await docScanner.init(
      'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
  await docScanner.setParameters(Template.color);
}
```


## Try Online Demo
https://yushulx.me/flutter-last-mile-delivery/
