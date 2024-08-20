#include "include/defaultify_plugin/defaultify_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "defaultify_plugin.h"

void DefaultifyPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  defaultify_plugin::DefaultifyPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
