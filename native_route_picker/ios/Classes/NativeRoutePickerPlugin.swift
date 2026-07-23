import AVFoundation
import AVKit
import Flutter
import UIKit

public class NativeRoutePickerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "native_route_picker",
      binaryMessenger: registrar.messenger())
    let instance = NativeRoutePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let factory = RoutePickerViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: NativeRoutePickerPlugin.viewType)
  }

  static let viewType = "native_route_picker/view"

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
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return RoutePickerPlatformView(frame: frame, arguments: args)
  }
}

class RoutePickerPlatformView: NSObject, FlutterPlatformView {
  private let pickerView: AVRoutePickerView

  init(frame: CGRect, arguments args: Any?) {
    pickerView = AVRoutePickerView(frame: frame)
    super.init()

    pickerView.prioritizesVideoDevices = false
    pickerView.backgroundColor = .clear

    if let params = args as? [String: Any] {
      if let tint = params["tintColor"] as? NSNumber {
        pickerView.tintColor = UIColor(argb: tint.intValue)
      }
      if let active = params["activeTintColor"] as? NSNumber {
        pickerView.activeTintColor = UIColor(argb: active.intValue)
      }
    }
  }

  func view() -> UIView {
    return pickerView
  }
}

private extension UIColor {
  convenience init(argb: Int) {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b, alpha: a)
  }
}
