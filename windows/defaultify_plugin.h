#ifndef FLUTTER_PLUGIN_DEFAULTIFY_PLUGIN_H_
#define FLUTTER_PLUGIN_DEFAULTIFY_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace defaultify_plugin {

class DefaultifyPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DefaultifyPlugin();

  virtual ~DefaultifyPlugin();

  // Disallow copy and assign.
  DefaultifyPlugin(const DefaultifyPlugin&) = delete;
  DefaultifyPlugin& operator=(const DefaultifyPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace defaultify_plugin

#endif  // FLUTTER_PLUGIN_DEFAULTIFY_PLUGIN_H_
