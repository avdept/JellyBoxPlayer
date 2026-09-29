import Flutter

enum WidgetCommandRunner {
  @MainActor
  static func run(_ command: String, item: String?) {
    FlutterMethodChannel(
      name: "com.prodigytech.jellybox/widget",
      binaryMessenger: AppDelegate.engine.binaryMessenger
    ).invokeMethod(command, arguments: item)
  }
}
