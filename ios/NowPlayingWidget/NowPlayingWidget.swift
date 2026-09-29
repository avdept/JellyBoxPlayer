import AppIntents
import SwiftUI
import UIKit
import WidgetKit

struct NowPlayingWidget: Widget {
  let kind = "NowPlayingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NowPlayingProvider()) { entry in
      NowPlayingView(snapshot: entry.snapshot)
        .containerBackground(for: .widget) { entry.snapshot.background }
    }
    .configurationDisplayName("Now Playing")
    .description("Control what's playing and jump back into recent albums.")
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

struct NowPlayingEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct NowPlayingProvider: TimelineProvider {
  func placeholder(in context: Context) -> NowPlayingEntry {
    NowPlayingEntry(date: .now, snapshot: .idle)
  }

  func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
    completion(NowPlayingEntry(date: .now, snapshot: WidgetSnapshot.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
    let entry = NowPlayingEntry(date: .now, snapshot: WidgetSnapshot.load())
    completion(Timeline(entries: [entry], policy: .never))
  }
}

struct RecentAlbum: Identifiable {
  let id: String
  let title: String
  let cover: UIImage?
}

struct WidgetSnapshot {
  enum State {
    case track
    case idle
    case signedOut
  }

  static let appGroup = "group.com.prodigytech.jellybox"
  static let recentCount = 4
  static let defaultBackground = Color(red: 0x2B / 255, green: 0x2B / 255, blue: 0x30 / 255)

  var state: State
  var title: String
  var artist: String
  var playing = false
  var cover: UIImage?
  var recent: [RecentAlbum] = []
  var background = defaultBackground
  var foreground = Color.white

  static let idle = WidgetSnapshot(state: .idle, title: "JellyBox", artist: "Nothing playing")

  static let signedOut = WidgetSnapshot(
    state: .signedOut,
    title: "JellyBox",
    artist: "Sign in to start listening"
  )

  static func load() -> WidgetSnapshot {
    guard
      let directory = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
        .appendingPathComponent("home_screen_widgets"),
      let data = try? Data(contentsOf: directory.appendingPathComponent("now_playing.json")),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return .idle }

    if json["signedOut"] as? Bool == true { return .signedOut }

    var snapshot = WidgetSnapshot.idle
    snapshot.recent = (json["recent"] as? [[String: Any]] ?? []).compactMap { entry in
      guard let id = entry["id"] as? String else { return nil }
      return RecentAlbum(
        id: id,
        title: entry["title"] as? String ?? "",
        cover: (entry["cover"] as? String).flatMap(UIImage.init(contentsOfFile:))
      )
    }

    guard let title = json["title"] as? String, !title.isEmpty else { return snapshot }
    snapshot.state = .track
    snapshot.title = title
    snapshot.artist = json["artist"] as? String ?? ""
    snapshot.playing = json["playing"] as? Bool ?? false
    snapshot.cover = (json["cover"] as? String).flatMap(UIImage.init(contentsOfFile:))
    if let background = (json["background"] as? NSNumber).map(color) {
      snapshot.background = background
    }
    if let foreground = (json["foreground"] as? NSNumber).map(color) {
      snapshot.foreground = foreground
    }
    return snapshot
  }

  private static func color(_ value: NSNumber) -> Color {
    let argb = value.uint32Value
    return Color(
      .sRGB,
      red: Double((argb >> 16) & 0xFF) / 255,
      green: Double((argb >> 8) & 0xFF) / 255,
      blue: Double(argb & 0xFF) / 255,
      opacity: Double((argb >> 24) & 0xFF) / 255
    )
  }
}

struct NowPlayingView: View {
  let snapshot: WidgetSnapshot

  private let padding: CGFloat = 14
  private let spacing: CGFloat = 8
  private let headerHeight: CGFloat = 44

  var body: some View {
    GeometryReader { geometry in
      let card = cardSize(in: geometry.size)
      VStack(alignment: .leading, spacing: 0) {
        header
          .frame(height: headerHeight)
        Spacer(minLength: spacing)
        if snapshot.state != .signedOut {
          HStack(spacing: spacing) {
            ForEach(0..<WidgetSnapshot.recentCount, id: \.self) { index in
              recentCard(
                snapshot.recent.indices.contains(index) ? snapshot.recent[index] : nil,
                size: card
              )
            }
          }
        }
      }
      .padding(padding)
      .foregroundStyle(snapshot.foreground)
    }
  }

  private func cardSize(in size: CGSize) -> CGFloat {
    let count = CGFloat(WidgetSnapshot.recentCount)
    let byWidth = (size.width - padding * 2 - spacing * (count - 1)) / count
    let byHeight = size.height - padding * 2 - spacing - headerHeight
    return max(0, min(byWidth, byHeight))
  }

  private var header: some View {
    HStack(spacing: 10) {
      Group {
        if let cover = snapshot.cover {
          Image(uiImage: cover).resizable().scaledToFill()
        } else {
          Image("Logo").resizable().scaledToFill()
        }
      }
      .frame(width: headerHeight, height: headerHeight)
      .clipShape(RoundedRectangle(cornerRadius: 6))

      VStack(alignment: .leading, spacing: 2) {
        Text(snapshot.title)
          .font(.system(size: 15, weight: .bold))
          .lineLimit(1)
        Text(snapshot.artist)
          .font(.system(size: 13))
          .opacity(0.7)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if snapshot.state == .track {
        Button(intent: WidgetCommandIntent("playPause")) {
          Image(systemName: snapshot.playing ? "pause.fill" : "play.fill")
            .font(.system(size: 24))
            .frame(width: headerHeight, height: headerHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private func recentCard(_ album: RecentAlbum?, size: CGFloat) -> some View {
    let shape = RoundedRectangle(cornerRadius: 8)
    if let album {
      Button(intent: WidgetCommandIntent("playAlbum", item: album.id)) {
        Group {
          if let cover = album.cover {
            Image(uiImage: cover).resizable().scaledToFill()
          } else {
            Image(systemName: "music.note")
              .font(.system(size: 20))
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(snapshot.foreground.opacity(0.12))
          }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .contentShape(shape)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(album.title)
    } else {
      shape
        .fill(snapshot.foreground.opacity(0.08))
        .frame(width: size, height: size)
    }
  }
}

#Preview(as: .systemMedium) {
  NowPlayingWidget()
} timeline: {
  NowPlayingEntry(date: .now, snapshot: .idle)
  NowPlayingEntry(date: .now, snapshot: .signedOut)
}
