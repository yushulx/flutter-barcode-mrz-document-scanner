//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_barcode_sdk/flutter_barcode_sdk_plugin.h>
#include <flutter_document_scan_sdk/flutter_document_scan_sdk_plugin.h>
#include <flutter_ocr_sdk/flutter_ocr_sdk_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_barcode_sdk_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterBarcodeSdkPlugin");
  flutter_barcode_sdk_plugin_register_with_registrar(flutter_barcode_sdk_registrar);
  g_autoptr(FlPluginRegistrar) flutter_document_scan_sdk_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterDocumentScanSdkPlugin");
  flutter_document_scan_sdk_plugin_register_with_registrar(flutter_document_scan_sdk_registrar);
  g_autoptr(FlPluginRegistrar) flutter_ocr_sdk_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterOcrSdkPlugin");
  flutter_ocr_sdk_plugin_register_with_registrar(flutter_ocr_sdk_registrar);
}
