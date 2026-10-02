// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// This Package.swift enables Swift Package Manager (SPM) support for the flutter_chrome_cast plugin.
// The plugin maintains dual support for both CocoaPods (via flutter_chrome_cast.podspec) and SPM.
//
// The Google Cast SDK dependency is provided by the SRGSSR community wrapper since Google does not
// officially provide an SPM-compatible distribution.
//
// Note: SPM support includes only Swift sources. The Objective-C bridging code (GoogleCastPlugin.m/h)
// is used by CocoaPods and Flutter's build system handles plugin registration automatically.

import PackageDescription

let package = Package(
    name: "flutter_chrome_cast",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "flutter-chrome-cast",
            targets: ["flutter_chrome_cast"]
        )
    ],
    dependencies: [
        // Google Cast SDK wrapper maintained by SRGSSR (Swiss Radio and Television)
        // This is a community-maintained wrapper that provides SPM support for the official Google Cast SDK.
        // Check https://github.com/SRGSSR/google-cast-sdk for the latest version tag and release notes.
        // 4.8.4+ XCFramework includes arm64 + x86_64 simulator slices (Apple Silicon / iOS 26+).
        .package(url: "https://github.com/SRGSSR/google-cast-sdk.git", from: "4.8.4")
    ],
    targets: [
        .target(
            name: "flutter_chrome_cast",
            dependencies: [
                .product(name: "GoogleCast", package: "google-cast-sdk")
            ],
            path: "Classes",
            exclude: [
                // Exclude Objective-C files - they are used by CocoaPods only
                // Flutter's build system generates plugin registration code separately
                "GoogleCastPlugin.m",
                "GoogleCastPlugin.h"
            ],
            sources: [
                "SwiftGoogleCastPlugin.swift",
                "DiscoveryManagerMethodChannel.swift",
                "SessionManagerMethodChannel.swift",
                "SessionMethodChannel.swift",
                "RemoteMediaClienteMethodChannel.swift",
                "Extensions/CastDeviceExtensions.swift",
                "Extensions/CastImageExtensions.swift",
                "Extensions/CastOptionsExtensions.swift",
                "Extensions/MediaInfoExtensions.swift",
                "Extensions/MediaMetatadaExtensions.swift",
                "Extensions/MediaStatusExtensions.swift",
                "Extensions/MediaTrack.swift",
                "Extensions/QueuLoadOptions.swift",
                "Extensions/QueueItemsExtensions.swift",
                "Extensions/RequestExtensions.swift",
                "Extensions/SeekOptionsExtensions.swift",
                "Extensions/SessionExtensions.swift"
            ]
        )
    ]
)
