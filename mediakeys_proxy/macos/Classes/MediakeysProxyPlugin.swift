import Cocoa
import FlutterMacOS
import MediaKeyTap
public class MediakeysProxyPlugin: NSObject, FlutterPlugin, NSApplicationDelegate, MediaKeyTapDelegate {
  private var eventMonitor: Any?
  var mediaKeyTap: MediaKeyTap?

  private var channel: FlutterMethodChannel?

    public init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mediakeys_proxy", binaryMessenger: registrar.messenger)
    let instance = MediakeysProxyPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.startMonitoring()
    requestAccessibilityIfNeeded()
  }

  private static let accessibilityPromptedKey = "mediakeys_proxy.accessibility_prompted"

  /// Shows the macOS accessibility prompt at most once. Once the user has been
  /// asked, we never prompt again, whatever they answered; they can still grant
  /// access later in System Settings.
  private static func requestAccessibilityIfNeeded() {
    if AXIsProcessTrusted() {
      return
    }

    let defaults = UserDefaults.standard
    if defaults.bool(forKey: accessibilityPromptedKey) {
      return
    }
    defaults.set(true, forKey: accessibilityPromptedKey)

    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    _ = AXIsProcessTrustedWithOptions(options)
  }

  public func handle(mediaKey: MediaKey, event: KeyEvent) {

    switch mediaKey {
    case .playPause:
        self.sendEventToFlutter(eventName: "playPause")
    case .previous, .rewind:
        self.sendEventToFlutter(eventName: "prev")
    case .next, .fastForward:
        self.sendEventToFlutter(eventName: "next")
    }
  }

    private func startMonitoring() {
        mediaKeyTap = MediaKeyTap(delegate: self)
        mediaKeyTap?.start()
    }



  private func sendEventToFlutter(eventName: String) {
    channel!.invokeMethod("mediaKeyPressed", arguments: eventName)
  }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
