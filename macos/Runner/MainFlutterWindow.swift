import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var titleBarToolbarStyle: NSWindow.ToolbarStyle?
  private var trafficLightLeadingInset: CGFloat?
  private var trafficLightSpacing: CGFloat = 8

  private var chromeChannel: FlutterMethodChannel?
  private var layoutObservers: [NSObjectProtocol] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    installChromeChannel(messenger: flutterViewController.engine.binaryMessenger)
    observeTitleBarLayout()
  }

  deinit {
    layoutObservers.forEach(NotificationCenter.default.removeObserver)
  }

  private func installChromeChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "jellybox/window_chrome", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "setTitleBar":
        let args = call.arguments as? [String: Any] ?? [:]
        self.applyTitleBar(
          toolbar: args["toolbar"] as? String ?? "none",
          inset: (args["inset"] as? NSNumber).map { CGFloat(truncating: $0) },
          spacing: (args["spacing"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 8
        )
        result(nil)
      case "getWindowCornerRadius":
        result(Double(self.windowCornerRadius()))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    chromeChannel = channel
  }

  private func windowCornerRadius() -> CGFloat {
    if let override = UserDefaults.standard.object(forKey: "NSConvolutionOverride1") as? NSNumber {
      return CGFloat(truncating: override)
    }
    switch ProcessInfo.processInfo.operatingSystemVersion.majorVersion {
    case ..<26: return 10
    case 26: return 26
    default: return 20
    }
  }

  private func applyTitleBar(toolbar: String, inset: CGFloat?, spacing: CGFloat) {
    let style: NSWindow.ToolbarStyle? = switch toolbar {
    case "unified": .unified
    case "compact": .unifiedCompact
    default: nil
    }
    titleBarToolbarStyle = style
    trafficLightLeadingInset = inset
    trafficLightSpacing = spacing

    if let style {
      if self.toolbar == nil {
        let toolbar = NSToolbar(identifier: "MainFlutterWindowToolbar")
        toolbar.showsBaselineSeparator = false
        self.toolbar = toolbar
      }
      self.toolbarStyle = style
      self.titlebarSeparatorStyle = .none
    } else {
      self.toolbar = nil
    }

    if inset == nil, let titleBarView = standardWindowButton(.closeButton)?.superview {
      titleBarView.needsLayout = true
      titleBarView.layoutSubtreeIfNeeded()
    }
    placeTrafficLights()
  }

  private func observeTitleBarLayout() {
    let names: [Notification.Name] = [
      NSWindow.didResizeNotification,
      NSWindow.didBecomeKeyNotification,
      NSWindow.didBecomeMainNotification,
      NSWindow.didResignMainNotification,
      NSWindow.didExitFullScreenNotification,
    ]
    for name in names {
      let observer = NotificationCenter.default.addObserver(
        forName: name, object: self, queue: .main
      ) { [weak self] _ in
        self?.placeTrafficLights()
      }
      layoutObservers.append(observer)
    }
  }

  override func setFrame(_ frameRect: NSRect, display flag: Bool) {
    super.setFrame(frameRect, display: flag)
    placeTrafficLights()
  }

  private func placeTrafficLights() {
    guard let inset = trafficLightLeadingInset, !styleMask.contains(.fullScreen) else { return }
    let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
    var x = inset
    for type in types {
      guard let button = standardWindowButton(type) else { continue }
      if abs(button.frame.minX - x) > 0.5 {
        button.setFrameOrigin(NSPoint(x: x, y: button.frame.minY))
      }
      x += button.frame.width + trafficLightSpacing
    }
  }
}
