import Flutter
import UIKit
import Defaultify

public class DefaultifyPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "defaultify_plugin", binaryMessenger: registrar.messenger())
    let instance = DefaultifyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
            case "getPlatformVersion":
                result("iOS " + UIDevice.current.systemVersion)
            case "launch":
                if #available(iOS 13.0, *) {
                    if let args = call.arguments as? [String: Any],
                       let code = args["token"] as? String {
                        DFTFY.launch(token: code)
                        result("Launch successful")
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument for 'code'", details: nil))
                    }
                } else {
                    result(FlutterError(code: "UNAVAILABLE", message: "iOS 13.0 or newer is required", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
  }
}
