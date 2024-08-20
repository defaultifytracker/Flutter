import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'defaultify_plugin_method_channel.dart';

abstract class DefaultifyPluginPlatform extends PlatformInterface {
  /// Constructs a DefaultifyPluginPlatform.
  DefaultifyPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static DefaultifyPluginPlatform _instance = MethodChannelDefaultifyPlugin();

  /// The default instance of [DefaultifyPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelDefaultifyPlugin].
  static DefaultifyPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DefaultifyPluginPlatform] when
  /// they register themselves.
  static set instance(DefaultifyPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
