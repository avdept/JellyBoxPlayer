import Flutter
import Foundation

final class CarPlayBridge {
  static let shared = CarPlayBridge()

  private var channel: FlutterMethodChannel?
  var onContentChanged: (() -> Void)?
  var onHomeChanged: (() -> Void)?
  var onPlaybackStateChanged: (() -> Void)?
  var onModesChanged: (() -> Void)?
  var onSearchChanged: ((String) -> Void)?
  var onStringsChanged: (() -> Void)?
  private(set) var playingSetId: String?
  private(set) var playingSongId: String?
  private(set) var isPlaying = false
  private(set) var shuffleEnabled = false
  private(set) var repeatMode = "off"
  private(set) var likedCurrent = false

  private static let stringsKey = "carplay.localizedStrings"

  private var localizedStrings: [String: String]

  private init() {
    localizedStrings =
      UserDefaults.standard.dictionary(forKey: Self.stringsKey)
        as? [String: String] ?? [:]
  }

  var isReady: Bool { channel != nil }

  func string(_ key: String, _ fallback: String) -> String {
    localizedStrings[key] ?? fallback
  }

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
      case "homeChanged":
        self?.onHomeChanged?()
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
      case "localize":
        if let strings = call.arguments as? [String: String] {
          self?.localizedStrings = strings
          UserDefaults.standard.set(strings, forKey: Self.stringsKey)
          self?.onStringsChanged?()
        }
        result(nil)
      case "modesChanged":
        let args = call.arguments as? [String: Any]
        self?.shuffleEnabled = args?["shuffle"] as? Bool ?? false
        self?.repeatMode = args?["repeat"] as? String ?? "off"
        self?.likedCurrent = args?["liked"] as? Bool ?? false
        self?.onModesChanged?()
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

  func artworkFile(for url: String, completion: @escaping (String?) -> Void) {
    guard let channel else {
      completion(nil)
      return
    }
    DispatchQueue.main.async {
      channel.invokeMethod("artwork", arguments: ["url": url]) { (response: Any?) in
        completion(response as? String)
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

  func toggleShuffle() {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("toggleShuffle", arguments: nil)
    }
  }

  func toggleRepeat() {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("toggleRepeat", arguments: nil)
    }
  }

  func toggleLike() {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("toggleLike", arguments: nil)
    }
  }

  func playQueueItem(index: Int) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("playQueueItem", arguments: ["index": index])
    }
  }
}
