import Flutter
import WidgetKit

public class HomeScreenWidgetsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "home_screen_widgets",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(HomeScreenWidgetsPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "directory":
      guard
        let group = args?["appGroup"] as? String,
        let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: group)
      else {
        result(nil)
        return
      }
      result(container.appendingPathComponent("home_screen_widgets").path)
    case "reload":
      if let kind = args?["iosKind"] as? String {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
