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

    FlutterEventChannel(
      name: "native_route_picker/output_volume",
      binaryMessenger: registrar.messenger()
    ).setStreamHandler(OutputVolumeStream())

    FlutterEventChannel(
      name: "native_route_picker/output_route",
      binaryMessenger: registrar.messenger()
    ).setStreamHandler(OutputRouteStream())
  }

  static let viewType = "native_route_picker/view"

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
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    guard let window else { return false }

    presenter?.removeFromSuperview()
    let anchor = CGPoint(x: x ?? window.bounds.midX, y: y ?? window.bounds.maxY)
    let picker = AVRoutePickerView(frame: CGRect(origin: anchor, size: CGSize(width: 1, height: 1)))
    picker.prioritizesVideoDevices = false
    picker.isUserInteractionEnabled = false
    window.addSubview(picker)
    picker.layoutIfNeeded()
    presenter = picker

    guard let button = picker.subviews.lazy.compactMap({ $0 as? UIButton }).first else {
      return false
    }
    button.sendActions(for: .touchUpInside)
    return true
  }
}

class OutputVolumeStream: NSObject, FlutterStreamHandler {
  private var observation: NSKeyValueObservation?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    let session = AVAudioSession.sharedInstance()
    observation = session.observe(\.outputVolume, options: [.initial, .new]) { session, _ in
      events(Double(session.outputVolume))
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observation = nil
    return nil
  }
}

class OutputRouteStream: NSObject, FlutterStreamHandler {
  private var observer: NSObjectProtocol?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    let emit = { events(OutputRouteStream.describe(AVAudioSession.sharedInstance().currentRoute)) }
    emit()
    observer = NotificationCenter.default.addObserver(
      forName: AVAudioSession.routeChangeNotification,
      object: nil,
      queue: .main
    ) { _ in emit() }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer { NotificationCenter.default.removeObserver(observer) }
    observer = nil
    return nil
  }

  static func describe(_ route: AVAudioSessionRouteDescription) -> [String: String] {
    guard let port = route.outputs.first else { return ["kind": "builtIn", "name": ""] }
    let kind: String
    switch port.portType {
    case .airPlay: kind = "airPlay"
    case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP: kind = "bluetooth"
    case .headphones, .usbAudio, .lineOut, .HDMI: kind = "wired"
    case .carAudio: kind = "car"
    case .builtInSpeaker, .builtInReceiver: kind = "builtIn"
    default: kind = "other"
    }
    return ["kind": kind, "name": port.portName]
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
