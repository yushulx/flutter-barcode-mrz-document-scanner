//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <camera_windows/camera_windows.h>
#include <flutter_barcode_sdk/flutter_barcode_sdk_plugin.h>
#include <flutter_document_scan_sdk/flutter_document_scan_sdk_plugin_c_api.h>
#include <flutter_ocr_sdk/flutter_ocr_sdk_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  CameraWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CameraWindows"));
  FlutterBarcodeSdkPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterBarcodeSdkPlugin"));
  FlutterDocumentScanSdkPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterDocumentScanSdkPluginCApi"));
  FlutterOcrSdkPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterOcrSdkPluginCApi"));
}
