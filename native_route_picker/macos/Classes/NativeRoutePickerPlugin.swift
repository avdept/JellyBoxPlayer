import AVKit
import Cocoa
import FlutterMacOS

public class NativeRoutePickerPlugin: NSObject, FlutterPlugin {
  static let viewType = "native_route_picker/view"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "native_route_picker",
      binaryMessenger: registrar.messenger)
    let instance = NativeRoutePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let factory = RoutePickerViewFactory()
    registrar.register(factory, withId: NativeRoutePickerPlugin.viewType)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showOutputSwitcher":
      result(false)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

class RoutePickerViewFactory: NSObject, FlutterPlatformViewFactory {
  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    let picker = AVRoutePickerView()
    picker.isRoutePickerButtonBordered = false

    if let params = args as? [String: Any] {
      if let normal = params["tintColor"] as? NSNumber {
        picker.setRoutePickerButtonColor(NSColor(argb: normal.intValue), for: .normal)
      }
      if let active = params["activeTintColor"] as? NSNumber {
        picker.setRoutePickerButtonColor(NSColor(argb: active.intValue), for: .active)
      }
    }

    return picker
  }
}

private extension NSColor {
  convenience init(argb: Int) {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    self.init(srgbRed: r, green: g, blue: b, alpha: a)
  }
}
