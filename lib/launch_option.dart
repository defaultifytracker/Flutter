import 'dart:io';
import 'cast_common.dart';
import 'constants.dart';

/// Base launch options class
abstract class LaunchOptions {
  final Map<String, dynamic> _optionsMap = <String, dynamic>{};

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(_optionsMap);
  }

  dynamic operator [](String index) => _optionsMap[index];
  void operator []=(String index, dynamic value) {
    _optionsMap[index] = value;
  }

  void setDefaults() {
    // set wrapper info
    _optionsMap['wrapper_info'] = {
      'type': 'flutter',
      'version': 1.0,
      'build': '0'
    };

    crashReport = true;
    maxNetworkBodySize = constOptionMaxNetworkBodySize;
    captureDeviceAndNetworkNames = constOptionCaptureDeviceAndNetworkNames;

  }

  /// Catch and report application crashes
  bool get crashReport => tryCast(this["CrashReport"], constOptionCrashReport);
  set crashReport(bool value) {
    this["CrashReport"] = value;
  }



  /// The maximal size of network request/response body.
  int get maxNetworkBodySize =>
      tryCast(this["bodySizeLimit"], constOptionMaxNetworkBodySize);
  set maxNetworkBodySize(int value) {
    this["bodySizeLimit"] = value;
  }

  bool get captureDeviceAndNetworkNames => tryCast(
      this["CaptureDeviceAndNetworkNames"],
      constOptionCaptureDeviceAndNetworkNames);
  set captureDeviceAndNetworkNames(bool value) {
    this["CaptureDeviceAndNetworkNames"] = value;
  }
}

// launch options for iOS
class IOSLaunchOptions extends LaunchOptions {
  IOSLaunchOptions() : super() {
    setDefaults();
  }
}

class AndroidLaunchOptions extends LaunchOptions {
  AndroidLaunchOptions() : super() {
    setDefaults();
  }

  @override
  void setDefaults() {
    super.setDefaults();

    notificationBarTrigger = constOptionNotificationBarTrigger;
    serviceMode = constOptionServiceMode;
    this["forceVideoModeV3"] = constOptionForceVideoModeV3;
  }
  bool get serviceMode => tryCast(this["ServiceMode"], constOptionServiceMode);
  set serviceMode(bool value) {
    this["ServiceMode"] = value;
  }

  ///
  bool get notificationBarTrigger => tryCast(
      this["NotificationBarTrigger"], constOptionNotificationBarTrigger);
  set notificationBarTrigger(bool value) {
    this["NotificationBarTrigger"] = value;
  }
}

LaunchOptions? getDefaultLaunchOptions() {
  if (Platform.isIOS) {
    return IOSLaunchOptions();
  }

  if (Platform.isAndroid) {
    return AndroidLaunchOptions();
  }

  return null;
}

LaunchOptions? _lastLaunchOptions;

void setLaunchOptions(LaunchOptions? launchOptions) {
  _lastLaunchOptions = launchOptions;
}

LaunchOptions? getLaunchOptions() {
  return _lastLaunchOptions;
}
