import 'package:flutter/services.dart';
import 'defaultify_plugin_platform_interface.dart';

class DefaultifyPlugin {
  static const MethodChannel methodChannel = MethodChannel('defaultify_plugin');

  Future<String?> getPlatformVersion() {
    return DefaultifyPluginPlatform.instance.getPlatformVersion();
  }

  static Future<bool> launch(String appToken) async {

    var params = <String, dynamic>{
      'token': appToken
    };
    var launched =
        ((await methodChannel.invokeMethod('launch', params)) ?? 0) != 0;

    // bool launched = false;
    //
    // Future<void> launchCallback() async {
    //   launched = await _initAndLaunch(appToken, launchOptions: launchOptions);
    //   _exceptionHandler?.installGlobalErrorHandler();
    // }
    //
    // await runZonedGuarded<FutureOr<void>>(() async {
    //   await launchCallback();
    // }, (error, stackTrace) async {
    //   await Defaultify.logHandledException(error, stackTrace);
    // });

    return Future.value(launched);
  }
}
