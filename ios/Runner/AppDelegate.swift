import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  static let engine = FlutterEngine(name: "main", project: nil, allowHeadlessExecution: true)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    Self.engine.run()
    GeneratedPluginRegistrant.register(with: Self.engine)
    CarPlayBridge.shared.setup(messenger: Self.engine.binaryMessenger)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
