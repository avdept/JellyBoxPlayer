import AppIntents

struct WidgetCommandIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Control Playback"
  static let isDiscoverable = false

  @Parameter(title: "Command")
  var command: String

  @Parameter(title: "Item")
  var item: String?

  init() {}

  init(_ command: String, item: String? = nil) {
    self.command = command
    self.item = item
  }

  func perform() async throws -> some IntentResult {
    await WidgetCommandRunner.run(command, item: item)
    return .result()
  }
}
