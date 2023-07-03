import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';

FlutterBarcodeSdk barcodeReader = FlutterBarcodeSdk();
bool isLicenseValid = false;
String readerTemplate = '';
String scannerTemplate = '''
{
    "FormatSpecification": {
        "AllModuleDeviation": 0,
        "AustralianPostEncodingTable": "C",
        "BarcodeAngleRangeArray": null,
        "BarcodeBytesLengthRangeArray": [
            {
                "MaxValue": 2147483647,
                "MinValue": 0
            }
        ],
        "BarcodeBytesRegExPattern": "",
        "BarcodeComplementModes": null,
        "BarcodeFormatIds": [
            "BF_ALL"
        ],
        "BarcodeFormatIds_2": [
            "BF2_ALL"
        ],
        "BarcodeHeightRangeArray": null,
        "BarcodeTextLengthRangeArray": [
            {
                "MaxValue": 2147483647,
                "MinValue": 0
            }
        ],
        "BarcodeTextRegExPattern": "",
        "BarcodeWidthRangeArray": null,
        "BarcodeZoneBarCountRangeArray": null,
        "BarcodeZoneMinDistanceToImageBorders": 0,
        "Code128Subset": "",
        "DeblurLevel": 9,
        "DeformationResistingModes": null,
        "EnableDataMatrixECC000-140": 0,
        "EnableQRCodeModel1": 0,
        "FindUnevenModuleBarcode": 1,
        "HeadModuleRatio": "",
        "MSICodeCheckDigitCalculation": "MSICCDC_MOD_10",
        "MinQuietZoneWidth": 4,
        "MinRatioOfBarcodeZoneWidthToHeight": 0,
        "MinResultConfidence": 30,
        "MirrorMode": "MM_NORMAL",
        "ModuleSizeRangeArray": null,
        "Name": "defaultFormatParameterForAllBarcodeFormat",
        "PartitionModes": [
            "PM_WHOLE_BARCODE",
            "PM_ALIGNMENT_PARTITION"
        ],
        "PatchCodeSearchingMargins": {
            "Bottom": 20,
            "Left": 20,
            "MeasuredByPercentage": 1,
            "Right": 20,
            "Top": 20
        },
        "RequireStartStopChars": 1,
        "ReturnPartialBarcodeValue": 1,
        "StandardFormat": "",
        "TailModuleRatio": "",
        "VerifyCheckDigit": 0
    },
    "ImageParameter": {
        "BarcodeColourModes": [
            {
                "LibraryFileName": "",
                "LibraryParameters": "",
                "LightReflection": 1,
                "Mode": "BICM_DARK_ON_LIGHT"
            }
        ],
        "BarcodeComplementModes": [
            {
                "Mode": "BCM_SKIP"
            }
        ],
        "BarcodeFormatIds": [
            "BF_ALL"
        ],
        "BarcodeFormatIds_2": [
            "BF2_NULL"
        ],
        "BinarizationModes": [
            {
                "BlockSizeX": 71,
                "BlockSizeY": 71,
                "EnableFillBinaryVacancy": 0,
                "ImagePreprocessingModesIndex": -1,
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "BM_LOCAL_BLOCK",
                "ThresholdCompensation": 10
            }
        ],
        "ColourClusteringModes": [
            {
                "Mode": "CCM_SKIP"
            }
        ],
        "ColourConversionModes": [
            {
                "BlueChannelWeight": -1,
                "GreenChannelWeight": -1,
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "CICM_GENERAL",
                "RedChannelWeight": -1
            }
        ],
        "DPMCodeReadingModes": [
            {
                "Mode": "DPMCRM_SKIP"
            }
        ],
        "DeblurLevel": 0,
        "DeblurModes": null,
        "DeformationResistingModes": [
            {
                "Mode": "DRM_SKIP"
            }
        ],
        "Description": "",
        "ExpectedBarcodesCount": 0,
        "FormatSpecificationNameArray": [
            "defaultFormatParameterForAllBarcodeFormat"
        ],
        "GrayscaleTransformationModes": [
            {
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "GTM_ORIGINAL"
            }
        ],
        "ImagePreprocessingModes": [
            {
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "IPM_GENERAL"
            }
        ],
        "IntermediateResultSavingMode": {
            "Mode": "IRSM_MEMORY"
        },
        "IntermediateResultTypes": [
            "IRT_NO_RESULT"
        ],
        "LocalizationModes": [
            {
                "IsOneDStacked": 0,
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "LM_SCAN_DIRECTLY",
                "ScanDirection": 2,
                "ScanStride": 0
            },
            {
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "LM_CONNECTED_BLOCKS"
            }
        ],
        "MaxAlgorithmThreadCount": 1,
        "Name": "default",
        "PDFRasterDPI": 300,
        "PDFReadingMode": {
            "Mode": "PDFRM_AUTO"
        },
        "Pages": "",
        "RegionDefinitionNameArray": null,
        "RegionPredetectionModes": [
            {
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "RPM_GENERAL"
            }
        ],
        "ResultCoordinateType": "RCT_PIXEL",
        "ReturnBarcodeZoneClarity": 0,
        "ScaleDownThreshold": 2300,
        "ScaleUpModes": [
            {
                "Mode": "SUM_AUTO"
            }
        ],
        "TerminatePhase": "TP_BARCODE_RECOGNIZED",
        "TextAssistedCorrectionMode": {
            "BottomTextPercentageSize": 0,
            "LeftTextPercentageSize": 0,
            "LibraryFileName": "",
            "LibraryParameters": "",
            "Mode": "TACM_VERIFYING",
            "RightTextPercentageSize": 0,
            "TopTextPercentageSize": 0
        },
        "TextFilterModes": [
            {
                "LibraryFileName": "",
                "LibraryParameters": "",
                "MinImageDimension": 65536,
                "Mode": "TFM_GENERAL_CONTOUR",
                "Sensitivity": 0
            }
        ],
        "TextResultOrderModes": [
            {
                "Mode": "TROM_CONFIDENCE"
            },
            {
                "Mode": "TROM_POSITION"
            },
            {
                "Mode": "TROM_FORMAT"
            }
        ],
        "TextureDetectionModes": [
            {
                "LibraryFileName": "",
                "LibraryParameters": "",
                "Mode": "TDM_GENERAL_WIDTH_CONCENTRATION",
                "Sensitivity": 5
            }
        ],
        "Timeout": 10000
    },
    "Version": "3.0"
}
''';

class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  })  : selectedOptions = expandedValue.toSet(),
        isAllSelected = true;

  List<String> expandedValue;
  String headerValue;
  bool isExpanded;
  Set<String> selectedOptions;
  bool isAllSelected;
}

Item format1D = Item(
  headerValue: '1D Barcodes',
  expandedValue: [
    'CODE_39',
    'CODE_128',
    'CODE_93',
    'CODABAR',
    'ITF',
    'EAN_13',
    'EAN_8',
    'UPC_A',
    'UPC_E',
    'INDUSTRIAL_25',
    'CODE_39_EXTENDED',
    'MSI_CODE'
  ],
);

Item format2D = Item(
  headerValue: '2D Barcodes',
  expandedValue: [
    'PATCHCODE',
    'PDF417',
    'QR_CODE',
    'DATAMATRIX',
    'AZTEC',
    'MAXICODE',
    'MICRO_QR',
    'MICRO_PDF417'
  ],
);

Item formatGS1 = Item(
  headerValue: 'GS1 Databar',
  expandedValue: [
    'GS1_DATABAR',
    'GS1_DATABAR_OMNIDIRECTIONAL',
    'GS1_DATABAR_TRUNCATED',
    'GS1_DATABAR_STACKED',
    'GS1_DATABAR_STACKED_OMNIDIRECTIONAL',
    'GS1_DATABAR_EXPANDED',
    'GS1_DATABAR_EXPANDED_STACKED',
    'GS1_DATABAR_LIMITED',
    'GS1_COMPOSITE'
  ],
);

int formatFromString(String format) {
  switch (format) {
    case 'CODE_39':
      return BarcodeFormat.CODE_39;
    case 'CODE_128':
      return BarcodeFormat.CODE_128;
    case 'CODE_93':
      return BarcodeFormat.CODE_93;
    case 'CODABAR':
      return BarcodeFormat.CODABAR;
    case 'ITF':
      return BarcodeFormat.ITF;
    case 'EAN_13':
      return BarcodeFormat.EAN_13;
    case 'EAN_8':
      return BarcodeFormat.EAN_8;
    case 'UPC_A':
      return BarcodeFormat.UPC_A;
    case 'UPC_E':
      return BarcodeFormat.UPC_E;
    case 'INDUSTRIAL_25':
      return BarcodeFormat.INDUSTRIAL_25;
    case 'CODE_39_EXTENDED':
      return BarcodeFormat.CODE_39_EXTENDED;
    case 'MSI_CODE':
      return BarcodeFormat.MSI_CODE;
    case 'PATCHCODE':
      return BarcodeFormat.PATCHCODE;
    case 'PDF417':
      return BarcodeFormat.PDF417;
    case 'QR_CODE':
      return BarcodeFormat.QR_CODE;
    case 'DATAMATRIX':
      return BarcodeFormat.DATAMATRIX;
    case 'AZTEC':
      return BarcodeFormat.AZTEC;
    case 'MAXICODE':
      return BarcodeFormat.MAXICODE;
    case 'MICRO_QR':
      return BarcodeFormat.MICRO_QR;
    case 'MICRO_PDF417':
      return BarcodeFormat.MICRO_PDF417;
    case 'GS1_DATABAR':
      return BarcodeFormat.GS1_DATABAR;
    case 'GS1_DATABAR_OMNIDIRECTIONAL':
      return BarcodeFormat.GS1_DATABAR_OMNIDIRECTIONAL;
    case 'GS1_DATABAR_TRUNCATED':
      return BarcodeFormat.GS1_DATABAR_TRUNCATED;
    case 'GS1_DATABAR_STACKED':
      return BarcodeFormat.GS1_DATABAR_STACKED;
    case 'GS1_DATABAR_STACKED_OMNIDIRECTIONAL':
      return BarcodeFormat.GS1_DATABAR_STACKED_OMNIDIRECTIONAL;
    case 'GS1_DATABAR_EXPANDED':
      return BarcodeFormat.GS1_DATABAR_EXPANDED;
    case 'GS1_DATABAR_EXPANDED_STACKED':
      return BarcodeFormat.GS1_DATABAR_EXPANDED_STACKED;
    case 'GS1_DATABAR_LIMITED':
      return BarcodeFormat.GS1_DATABAR_LIMITED;
    case 'GS1_COMPOSITE':
      return BarcodeFormat.GS1_COMPOSITE;
  }
  return 0;
}

final List<Item> allFormats = <Item>[
  format1D,
  format2D,
  formatGS1,
];

Future<void> updateFormats() async {
  int formats = BarcodeFormat.NULL;
  for (Item item in allFormats) {
    var options = item.selectedOptions;
    for (String option in options) {
      formats |= formatFromString(option);
    }
  }
  await barcodeReader.setBarcodeFormats(formats);
}

Future<int> initBarcodeSDK() async {
  int ret = await barcodeReader.setLicense(
      'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
  if (ret == 0) isLicenseValid = true;
  await barcodeReader.init();
  await barcodeReader.setBarcodeFormats(BarcodeFormat.ALL);
  readerTemplate = await barcodeReader.getParameters();
  return ret;
}

Color colorMainTheme = const Color(0xff1D1B20);
Color colorOrange = const Color(0xffFE8E14);
Color colorTitle = const Color(0xffF5F5F5);
Color colorSelect = const Color(0xff757575);
Color colorText = const Color(0xff888888);
Color colorBackground = const Color(0xFF323234);
Color colorSubtitle = const Color(0xffCCCCCC);
Color colorGreen = const Color(0xff6AC4BB);

Widget createOverlay(
  List<BarcodeResult>? barcodeResults,
) {
  return CustomPaint(
    painter: OverlayPainter(barcodeResults),
  );
}

class OverlayPainter extends CustomPainter {
  List<BarcodeResult>? barcodeResults;

  OverlayPainter(this.barcodeResults);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    if (barcodeResults != null) {
      for (var result in barcodeResults!) {
        double minX = result.x1.toDouble();
        double minY = result.y1.toDouble();
        if (result.x2 < minX) minX = result.x2.toDouble();
        if (result.x3 < minX) minX = result.x3.toDouble();
        if (result.x4 < minX) minX = result.x4.toDouble();
        if (result.y2 < minY) minY = result.y2.toDouble();
        if (result.y3 < minY) minY = result.y3.toDouble();
        if (result.y4 < minY) minY = result.y4.toDouble();

        canvas.drawLine(Offset(result.x1.toDouble(), result.y1.toDouble()),
            Offset(result.x2.toDouble(), result.y2.toDouble()), paint);
        canvas.drawLine(Offset(result.x2.toDouble(), result.y2.toDouble()),
            Offset(result.x3.toDouble(), result.y3.toDouble()), paint);
        canvas.drawLine(Offset(result.x3.toDouble(), result.y3.toDouble()),
            Offset(result.x4.toDouble(), result.y4.toDouble()), paint);
        canvas.drawLine(Offset(result.x4.toDouble(), result.y4.toDouble()),
            Offset(result.x1.toDouble(), result.y1.toDouble()), paint);

        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: result.text,
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 22.0,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: size.width);
        textPainter.paint(canvas, Offset(minX, minY));
      }
    }
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) => true;
}

List<BarcodeResult> rotate90barcode(List<BarcodeResult> input, int height) {
  List<BarcodeResult> output = [];
  for (BarcodeResult result in input) {
    int x1 = result.x1;
    int x2 = result.x2;
    int x3 = result.x3;
    int x4 = result.x4;
    int y1 = result.y1;
    int y2 = result.y2;
    int y3 = result.y3;
    int y4 = result.y4;

    BarcodeResult newResult = BarcodeResult(
        result.format,
        result.text,
        height - y1,
        x1,
        height - y2,
        x2,
        height - y3,
        x3,
        height - y4,
        x4,
        result.angle,
        result.barcodeBytes);

    output.add(newResult);
  }

  return output;
}
