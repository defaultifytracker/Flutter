import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'defaultify_plugin_platform_interface.dart';

/// An implementation of [DefaultifyPluginPlatform] that uses method channels.
class MethodChannelDefaultifyPlugin extends DefaultifyPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('defaultify_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
