import Flutter
import ImageIO
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
    case "artwork":
      guard
        let source = args?["source"] as? String,
        let target = args?["target"] as? String,
        let size = args?["size"] as? Int
      else {
        result(nil)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let pixels = Self.artwork(source: source, target: target, size: size)
        DispatchQueue.main.async { result(pixels) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static let colorSampleSize = 112

  private static func artwork(source: String, target: String, size: Int) -> FlutterStandardTypedData? {
    guard
      let input = CGImageSourceCreateWithURL(URL(fileURLWithPath: source) as CFURL, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(
        input,
        0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: size,
        ] as CFDictionary
      ),
      let output = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: target) as CFURL,
        "public.png" as CFString,
        1,
        nil
      )
    else { return nil }
    CGImageDestinationAddImage(output, image, nil)
    guard CGImageDestinationFinalize(output) else { return nil }

    let scale = min(1, Double(colorSampleSize) / Double(max(image.width, image.height)))
    let width = max(1, Int(Double(image.width) * scale))
    let height = max(1, Int(Double(image.height) * scale))
    var pixels = [UInt32](repeating: 0, count: width * height)
    let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: width * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            | CGBitmapInfo.byteOrder32Little.rawValue
        )
      else { return false }
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard drawn else { return nil }
    return FlutterStandardTypedData(int32: pixels.withUnsafeBytes { Data($0) })
  }
}
