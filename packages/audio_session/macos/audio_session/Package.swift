// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(
    name: "audio_session",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "audio-session", targets: ["audio_session"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "audio_session",
            dependencies: [],
            cSettings: [
                .headerSearchPath("include/audio_session"),
                .define("AUDIO_SESSION_MICROPHONE", to: ProcessInfo.processInfo.environment["AUDIO_SESSION_MICROPHONE"] ?? "1")
            ]
        )
    ]
)
