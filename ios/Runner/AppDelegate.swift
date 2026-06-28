import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Use the FlutterPluginRegistrar to get a safe handle to the binary messenger
    // This resolves any timing conflict with window?.rootViewController initialization
    if let registrar = self.registrar(forPlugin: "com.flux.channel") {
      let methodChannel = FlutterMethodChannel(name: "com.flux.channel/methods",
                                                binaryMessenger: registrar.messenger())
      methodChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "initializeIndex":
          result(true)
        case "getDirectoryContents":
          result([])
        case "executeBatchDelete":
          result(true)
        case "restoreTombstones":
          result(true)
        case "getStorageStatistics":
          result([:])
        case "getAppStorageUsage":
          result([])
        default:
          result(FlutterMethodNotImplemented)
        }
      })

      // Set up EventChannel using the registrar's messenger
      let eventChannel = FlutterEventChannel(name: "com.flux.channel/search_stream",
                                              binaryMessenger: registrar.messenger())
      eventChannel.setStreamHandler(SearchStreamHandler())
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

class SearchStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    events(FlutterEndOfEventStream)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
