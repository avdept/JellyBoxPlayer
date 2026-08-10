import Flutter
import Foundation

final class CarPlayBridge {
  static let shared = CarPlayBridge()

  private var channel: FlutterMethodChannel?
  var onContentChanged: (() -> Void)?
  var onPlaybackStateChanged: (() -> Void)?
  var onSearchChanged: ((String) -> Void)?
  private(set) var playingSetId: String?
  private(set) var playingSongId: String?
  private(set) var isPlaying = false

  private init() {}

  var isReady: Bool { channel != nil }

  func setup(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.prodigytech.jellybox/carplay",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "contentChanged":
        self?.onContentChanged?()
        result(nil)
      case "searchChanged":
        let args = call.arguments as? [String: Any]
        self?.onSearchChanged?(args?["query"] as? String ?? "")
        result(nil)
      case "playbackState":
        let args = call.arguments as? [String: Any]
        self?.playingSetId = args?["setId"] as? String
        self?.playingSongId = args?["songId"] as? String
        self?.isPlaying = args?["playing"] as? Bool ?? false
        self?.onPlaybackStateChanged?()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  func fetch(
    _ method: String,
    arguments: Any? = nil,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    guard let channel else {
      completion(nil)
      return
    }
    DispatchQueue.main.async {
      channel.invokeMethod(method, arguments: arguments) { (response: Any?) in
        completion(response as? [String: Any])
      }
    }
  }

  func play(type: String, id: String) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("play", arguments: ["type": type, "id": id])
    }
  }

  func setSort(field: String) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("setSort", arguments: ["field": field])
    }
  }

  func playQueueItem(index: Int) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("playQueueItem", arguments: ["index": index])
    }
  }
}
