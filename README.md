<div align="center">

<img src="./docs/logo.png" width="120" alt="JellyBox logo">

# JellyBox

**The best native music player for your Jellyfin server - on macOS, Windows, Linux, iOS(including CarPlay) and Android.**

[![Build Status](https://github.com/avdept/JellyBoxPlayer/actions/workflows/tests.yaml/badge.svg)](https://github.com/avdept/JellyBoxPlayer/actions)
[![Latest release](https://img.shields.io/github/v/release/avdept/JellyBoxPlayer)](https://github.com/avdept/JellyBoxPlayer/releases/latest)
[![License: AGPL v3](https://img.shields.io/badge/license-AGPL--3.0-blue)](./LICENSE)
[![Stars](https://img.shields.io/github/stars/avdept/JellyBoxPlayer?style=flat)](https://github.com/avdept/JellyBoxPlayer/stargazers)
[![Follow @_avdept](https://img.shields.io/badge/@__avdept-000000?logo=x&logoColor=white)](https://x.com/_avdept)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/avdept)

[Download](#download) · [Features](#features) · [Screenshots](#screenshots) · [Development](#development)

</div>

---

JellyBox is an unofficial, audio-only client for [Jellyfin](https://jellyfin.org). It focuses on doing one thing well: making your own music library feel like a modern streaming app - fast browsing, offline downloads, lyrics, and artwork-driven theming - with a UI built for each platform rather than a single stretched layout.

> [!IMPORTANT]
> JellyBox is a client, not a server. You need access to a running Jellyfin server with a music library on it.

## Download

| Platform | Format | |
|---|---|---|
| **iOS / iPadOS / macOS**  | App Store | [![App Store](https://img.shields.io/badge/App_Store-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/us/app/jellybox-player/id6469732117) |
| **macOS** | `.dmg` (signed & notarized) | [Latest release](https://github.com/avdept/JellyBoxPlayer/releases/latest) |
| **Windows** | Installer `.exe` or portable `.zip` | [Latest release](https://github.com/avdept/JellyBoxPlayer/releases/latest) |
| **Linux** | `.tar.gz` bundle (x64) | [Latest release](https://github.com/avdept/JellyBoxPlayer/releases/latest) |
| **Android** | `.apk` | [Latest release](https://github.com/avdept/JellyBoxPlayer/releases/latest) |

Google Play distribution is on the way, need to wait 2 weeks during closed beta period.

## Features

**Library & browsing**
- [x] Browse albums, artists, genres, playlists and songs across multiple music libraries
- [x] Search everything at once, or filter to playlists, albums, artists or songs
- [x] Artist pages with biography and full discography
- [x] Favourite tracks, synced back to your Jellyfin server
- [x] Create playlists and add tracks to them from anywhere in the app
- [ ] Home page - in development

**Playback**
- [x] Playback memory - app remembers your queue and playback position between restarts
- [x] Time-synced lyrics overlay
- [x] Queue management with shuffle, repeat and a randomised "surprise me" queue
- [x] Per-connection streaming profiles with automatic transcoding when a codec isn't supported natively
- [x] Audio quality badge, so you always know whether you're getting the original file

**Offline**
- [x] Download albums and tracks for offline listening
- [x] Full offline mode - access to your downloaded tracks even if you're on plane.

**Look & feel**
- [x] Colour scheme generated from the current album artwork
- [x] Studio Mode - a full screen animated mode for aesthetic feel(see screenshots)

**Desktop & system integration**
- [x] Media keys and global keyboard shortcuts
- [x] MPRIS support on Linux (works with GNOME/KDE media widgets and `playerctl`)
- [x] AirPlay and system output routing on macOS and iOS
- [x] Lock screen and notification controls on iOS and Android
- [x] In-app changelog, so you can see what landed in each release
- [x] Apple CarPlay - currently in beta stage.
- [ ] Android auto - in development

## Screenshots

### Desktop

<div align="center">
  <img src="./docs/screenshots/studio-mode.png" width="90%" alt="Studio Mode - full-screen playback with an animated backdrop">
  <p><b>Studio Mode</b> - full-screen animated mode made for aesthetic</p>
</div>

<table>
  <tr>
    <td width="50%"><img src="./docs/screenshots/lyrics.png" alt="Time-synced lyrics"></td>
    <td width="50%"><img src="./docs/screenshots/songs.png" alt="Songs view"></td>
  </tr>
  <tr>
    <td align="center"><b>Time-synced lyrics</b></td>
    <td align="center"><b>Songs</b></td>
  </tr>
</table>

<details>
<summary><b>More screenshots</b> - search, albums, artists, downloads</summary>
<br>

<table>
  <tr>
    <td width="50%"><img src="./docs/screenshots/search.png" alt="Search across albums, artists, songs and playlists"></td>
    <td width="50%"><img src="./docs/screenshots/album.png" alt="Album view"></td>
  </tr>
  <tr>
    <td align="center"><b>Search</b></td>
    <td align="center"><b>Album</b></td>
  </tr>
  <tr>
    <td width="50%"><img src="./docs/screenshots/artist.png" alt="Artist view with biography and discography"></td>
    <td width="50%"><img src="./docs/screenshots/downloads.png" alt="Downloaded albums available offline"></td>
  </tr>
  <tr>
    <td align="center"><b>Artist</b></td>
    <td align="center"><b>Downloads</b></td>
  </tr>
</table>

</details>

### Mobile

<table>
  <tr>
    <td width="20%"><img src="./docs/screenshots/mobile-player.jpg" alt="Now playing on iPhone"></td>
    <td width="20%"><img src="./docs/screenshots/mobile-lyrics.jpg" alt="Time-synced lyrics on iPhone"></td>
    <td width="20%"><img src="./docs/screenshots/mobile-albums.jpg" alt="Albums grid on iPhone"></td>
    <td width="20%"><img src="./docs/screenshots/mobile-artist.jpg" alt="Artist view on iPhone"></td>
    <td width="20%"><img src="./docs/screenshots/mobile-downloads.jpg" alt="Downloads on iPhone"></td>
  </tr>
  <tr>
    <td align="center"><b>Now playing</b></td>
    <td align="center"><b>Lyrics</b></td>
    <td align="center"><b>Albums</b></td>
    <td align="center"><b>Artist</b></td>
    <td align="center"><b>Downloads</b></td>
  </tr>
</table>

## Platform notes

### macOS - media keys

macOS does not let an app read media keys without permission. On first use JellyBox will point you at **System Settings → Privacy & Security → Accessibility**; enable **JellyBox** there. If it isn't in the list, add it with the **+** button.

### Windows

The installer is unsigned, so SmartScreen will warn on first run - choose **More info → Run anyway**. The portable zip has no installer and can be run from anywhere.

### Android

Builds are distributed as APKs from the [releases page](https://github.com/avdept/JellyBoxPlayer/releases). You'll need to allow installs from your browser or file manager.

### Linux

The release bundle expects a few shared libraries. On Debian/Ubuntu:

```bash
sudo apt-get install libmpv-dev mpv libsecret-1-dev libsqlite3-dev libjsoncpp-dev libcurl4-openssl-dev libdbus-1-dev
```

## Development

**Prerequisites** - [Flutter](https://docs.flutter.dev/get-started/install) with Dart SDK 3.8 or newer, plus the toolchain for whichever platform you're targeting (Xcode, Android Studio, or the Linux packages above).

```bash
git clone https://github.com/avdept/JellyBoxPlayer.git
cd JellyBoxPlayer

flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed, json_serializable, retrofit
flutter run                                                # then pick a target device
```

Run the tests with `flutter test`, and the analyzer with `flutter analyze` - CI runs both on every push.

Codegen is needed whenever you touch a model, DTO or API client; those `*.g.dart` and `*.freezed.dart` files are generated, not hand-edited.


## Contributing

Bug reports, feature requests and pull requests are all welcome - see [CONTRIBUTING.md](./CONTRIBUTING.md) for the workflow.

## License

[GNU AGPL-3.0](./LICENSE) © ProdigyTech Inc.
