# JellyBox - Music player for Jellyfin

<a href="https://github.com/avdept/jplayer/actions"><img src="https://github.com/avdept/jplayer/workflows/jellybox/badge.svg" alt="Build Status"></a>

<a href="https://x.com/_avdept">
  <img src="https://img.shields.io/badge/Twitter-blue?style=for-the-badge&logo=twitter&logoColor=white" alt="Twitter Badge"/>
</a>
<a href="https://www.buymeacoffee.com/avdept" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

[![Jellybox on the App Store](./appstore.svg)](https://apps.apple.com/us/app/jellybox-player/id6469732117)


### Description
This is unofficial **audio** client for jellyfin app. Currently it supports macOS, iOS and android via APK file. I'm also working on adding Linux(deb) support and windows. 

## IOS/Macos

### Media keys - Play/Pause, Next/Prev
By default apple restricts app from reading what user presses on keyboard. In order to allow it - Jellybox would prompt you to open Settings -> Privacy -> Accessibility. Make sure you toggle on JellyBox player. If for some reason app isnt there - you can add it using +(plus) button at the bottom of list.

## Android

While it can already be built and launched, I haven't uploaded it to google play yet. This is something I plan to do soon. Meanwhile you can download APKs from the [Releases](https://github.com/avdept/JellyBoxPlayer/releases) section.

## Windows

The app is currently available in the [Releases](https://github.com/avdept/JellyBoxPlayer/releases) section as a binary file.

## Linux

The app is currently available in the [Releases](https://github.com/avdept/JellyBoxPlayer/releases) section as a binary file. Flatpak releases are coming soon.

### Build

On Linux, the build depends on `mpv` being installed on your host machine. Make sure it is, by running e.g. `mpv -h`.
To then build the app yourself, clone the repository and run:

```bash
flutter build linux --release
```

## Screenshots
<img align="right" width="380" src="./docs/4.PNG">
<img align="left" width="380" src="./docs/5.PNG">

<img src="./docs/1.png">
<img src="./docs/2.png">
<img src="./docs/3.png">


## Development

To run the app you need to have flutter cli installed + simulator(if you intend top run it on mobile).

* Install dependencies `flutter pub get`
* Run the app `flutter run` and then select target
* Once you're happy with your code submit a PR
