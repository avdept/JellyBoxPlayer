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

  private var presenter: AVRoutePickerView?

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showOutputSwitcher":
      let args = call.arguments as? [String: Any]
      result(
        showOutputSwitcher(
          x: (args?["x"] as? NSNumber)?.doubleValue,
          y: (args?["y"] as? NSNumber)?.doubleValue))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func showOutputSwitcher(x: Double?, y: Double?) -> Bool {
    guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
      let content = window.contentView
    else { return false }

    presenter?.removeFromSuperview()
    let bounds = content.bounds
    let px = x ?? bounds.midX
    let py = y.map { content.isFlipped ? $0 : bounds.height - $0 } ?? bounds.midY
    let picker = AVRoutePickerView(frame: NSRect(x: px, y: py, width: 1, height: 1))
    picker.isRoutePickerButtonBordered = false
    content.addSubview(picker)
    picker.layoutSubtreeIfNeeded()
    presenter = picker

    guard let button = firstButton(in: picker) else { return false }
    button.performClick(nil)
    return true
  }

  private func firstButton(in view: NSView) -> NSButton? {
    for subview in view.subviews {
      if let button = subview as? NSButton { return button }
      if let button = firstButton(in: subview) { return button }
    }
    return nil
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
