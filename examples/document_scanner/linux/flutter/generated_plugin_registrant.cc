//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <file_selector_linux/file_selector_plugin.h>
#include <flutter_document_scan_sdk/flutter_document_scan_sdk_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) file_selector_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FileSelectorPlugin");
  file_selector_plugin_register_with_registrar(file_selector_linux_registrar);
  g_autoptr(FlPluginRegistrar) flutter_document_scan_sdk_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterDocumentScanSdkPlugin");
  flutter_document_scan_sdk_plugin_register_with_registrar(flutter_document_scan_sdk_registrar);
}
