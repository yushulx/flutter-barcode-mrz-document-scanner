# Pharma Lookup

**Pharma Lookup** is a Flutter application that enables users to scan 1D and 2D barcodes to retrieve detailed pharmaceutical information. Leveraging the power of barcode scanning and a comprehensive dataset, this app provides a seamless experience for verifying medication details.

https://github.com/yushulx/pharma-lookup/assets/2202306/21a5c49d-840e-418b-b293-cb206cbbd894

## Supported Platforms
Pharma Lookup is built to run smoothly across multiple platforms:
- **Web**
- **Android**
- **iOS**
- **Windows**

## Mockup Data for Testing
To effectively test the Pharma Lookup application, prepare barcodes encoded with `LotNumber`. You can modify the related information directly in the `lib/main.dart` file. Here's an example of how to structure your mockup data:
```dart
List<dynamic> list = [
      {
        "LotNumber": "000123457118",
        "MedicationName": "Medicorin",
        "ManufactureDate": "2023-01-09T16:00:00.000Z",
        "ExpirationDate": "2025-01-09T16:00:00.000Z",
        "BatchSize": 5000,
        "QualityCheckStatus": "Passed"
      },
    ];
```

**Note**: Ensure that each barcode corresponds to a unique LotNumber to accurately retrieve the associated pharmaceutical information.

## Getting Started
1. **Obtain a Trial License**
    
    Apply for a [30-day trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform) from Dynamsoft. Once you receive your license key, replace the placeholder in the `lib/global.dart` file with your own key:

    ```dart
    Future<int> initBarcodeSDK() async {
        int ret = await barcodeReader.setLicense(
            'LICENSE-KEY');
        await barcodeReader.init();
        await barcodeReader.setBarcodeFormats(BarcodeFormat.ALL);
        return ret;
    }
    ```

2. **Run the Project**:

    Ensure you have Flutter installed and set up on your machine. Then, execute the following commands to run the application on your desired platform:

    ```
    # Run on the default device
    flutter run

    # Run on Windows
    flutter run -d windows
    
    # Run on Microsoft Edge (Web)
    flutter run -d edge
    ```
 
    ![pharma-look-up](https://www.dynamsoft.com/codepool/img/2023/11/pharma-look-up.png)


