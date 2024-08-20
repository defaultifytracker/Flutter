//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <defaultify_plugin/defaultify_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) defaultify_plugin_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DefaultifyPlugin");
  defaultify_plugin_register_with_registrar(defaultify_plugin_registrar);
}
