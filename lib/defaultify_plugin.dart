import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'exception_handler.dart';
import 'callbacks.dart';
import 'launch_option.dart';
import 'network.dart';
import 'network_modal.dart';
import 'route_observer.dart';

class Defaultify with WidgetsBindingObserver {
  static final Defaultify _instance = Defaultify._internal();
  static const MethodChannel methodChannel = MethodChannel('defaultify_plugin');
  static ExceptionHandler? _exceptionHandler;
  static final CustomRouteObserver customRouteObserver = CustomRouteObserver();

  static Callbacks? _callbacks;

  static void initialize() {
    WidgetsFlutterBinding.ensureInitialized();
    // Add the WidgetsBinding observer
    WidgetsBinding.instance.addObserver(_instance);
    _exceptionHandler = ExceptionHandler(methodChannel);

    _callbacks = Callbacks();
    _callbacks?.setNetworkFilter((NetworkEvent event) async {
      return event;
    });
    // Override the default HTTP client
    HttpOverrides.global = NetworkLoggerHttpOverrides();
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'handleShakeEvent') {
        await handleShakeEvent();
      }
    });
  }

  factory Defaultify() {
    return _instance;
  }

  Defaultify._internal();

  // Method to get the screen list from the route observer
  List<Map<String, String>> getScreenList() {
    return customRouteObserver.screenList.map((screenInfo) {
      String screenName =
          screenInfo.screenName == '/' ? 'Initial' : screenInfo.screenName;
      return {
        'screenName': screenName,
        'startTime': screenInfo.startTime.toString(),
      };
    }).toList();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    methodChannel
        .invokeMethod('onLifecycleChange', {'state': state.toString()});
  }

  static Future<bool> launch(String appToken,
      {LaunchOptions? launchOptions}) async {
    bool launched = false;

    Future<void> launchCallback() async {
      launched = await _initAndLaunch(appToken, launchOptions: launchOptions);
      _exceptionHandler?.installGlobalErrorHandler();
    }

    await runZonedGuarded<FutureOr<void>>(() async {
      await launchCallback();
    }, (error, stackTrace) async {
      await Defaultify.logHandledException(error, stackTrace);
    });

    return Future.value(launched);
  }

  static Future<bool> _initAndLaunch(String appToken,
      {LaunchOptions? launchOptions}) async {
    initialize();
    // either use provided options, or fallback to explicit defaults
    setLaunchOptions(launchOptions ?? getDefaultLaunchOptions());
    var params = <String, dynamic>{'token': appToken};
    var launched =
        ((await methodChannel.invokeMethod('launch', params)) ?? 0) != 0;
    if (launched) {
      _exceptionHandler?.syncWithOptions(getLaunchOptions());
    } else {
      // launch failed -> deactivate exceptions handler
      _exceptionHandler?.deactivateUnhandledInterception();
    }
    return Future.value(launched);
  }

  static void registerNetworkEvent(Map<String, dynamic> eventData) {
    _callbacks?.networkFilterCallback(eventData).then((filteredEvent) {
      if (filteredEvent != null) {
        methodChannel.invokeMethod('registerNetworkEvent', filteredEvent);
      }
    });
  }

  static Future<void> logHandledException(dynamic exception,
      [dynamic stackTrace]) async {
    await _exceptionHandler?.logException(exception, true, stackTrace);
  }

  static Future<void> handleShakeEvent() async {
    try {
      RenderRepaintBoundary? boundary = _findRepaintBoundary();
      var screenList = _instance.getScreenList();

      if (boundary == null) {
        await methodChannel.invokeMethod(
            'handleShakeEvent', {'uri': '', 'screenList': screenList});
        return;
      }
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      String filePath = await _saveImageToFile(pngBytes);
      String uri = Uri.file(filePath).toString();
      await methodChannel.invokeMethod(
          'handleShakeEvent', {'uri': uri, 'screenList': screenList});
    } catch (e) {
      if (kDebugMode) {
        print("Failed to handle shake event: $e");
      }
    }
  }

  static RenderRepaintBoundary? _findRepaintBoundary() {
    // Use the context of the root widget to find the RenderRepaintBoundary
    BuildContext? context = WidgetsBinding.instance.rootElement;
    if (context == null) {
      return null;
    }

    // Traverse the widget tree to find the first RenderRepaintBoundary
    RenderRepaintBoundary? boundary;
    context.visitChildElements((element) {
      if (element.renderObject is RenderRepaintBoundary) {
        boundary = element.renderObject as RenderRepaintBoundary;
      } else {
        boundary = _findRepaintBoundaryInChild(element);
      }
    });
    return boundary;
  }

  static RenderRepaintBoundary? _findRepaintBoundaryInChild(Element element) {
    RenderRepaintBoundary? boundary;
    element.visitChildElements((child) {
      if (child.renderObject is RenderRepaintBoundary) {
        boundary = child.renderObject as RenderRepaintBoundary;
      } else {
        boundary = _findRepaintBoundaryInChild(child);
      }
    });
    return boundary;
  }

  static Future<String> _saveImageToFile(Uint8List imageBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/snapshot.png';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath;
  }
}
