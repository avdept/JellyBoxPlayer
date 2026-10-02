#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_cast.podspec` to validate before publishing.
#
# This plugin supports both CocoaPods (this file) and Swift Package Manager (Package.swift).
# For SPM support, see flutter_chrome_cast/Package.swift.
#
# arm64 iOS Simulator:
# - Do NOT set EXCLUDED_ARCHS for iphonesimulator (required for Apple Silicon / iOS 26+ sims).
# - Depend on google-cast-sdk >= 4.8.4, which ships an XCFramework with ios-arm64 simulator slices.
# - Do NOT use google-cast-sdk-no-bluetooth; that pod excludes arm64 simulator architectures.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_chrome_cast'
  s.version          = '1.4.8'
  s.summary          = 'A comprehensive Flutter plugin for Google Cast SDK integration on iOS and Android.'
  s.description      = <<-DESC
FlutterGoogleCast provides seamless integration with the Google Cast SDK for Flutter applications.
Discover, connect to, and control Chromecast devices and other Google Cast-enabled receivers with
full support for media streaming, playback controls, queue management, and real-time status updates.

This plugin supports both CocoaPods and Swift Package Manager (SPM) for iOS dependency management.
                       DESC
  s.homepage         = 'https://github.com/felnanuke2/flutter_google_cast'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luiz Felipe Alves Lima' => 'https://github.com/felnanuke2' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_chrome_cast/Sources/flutter_chrome_cast/**/*.swift'
  s.exclude_files = 'flutter_chrome_cast/Sources/flutter_chrome_cast/GoogleCastPlugin.h', 'flutter_chrome_cast/Sources/flutter_chrome_cast/GoogleCastPlugin.m'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.ios.deployment_target  = '15.0'
  # 4.8.4+ XCFramework includes arm64 simulator; required for Apple Silicon iOS 26+ simulators.
  s.dependency 'google-cast-sdk', '~> 4.8.4'
  s.dependency 'Protobuf'
  s.static_framework = true

  # Intentionally no EXCLUDED_ARCHS — arm64 simulator must remain enabled.
  s.pod_target_xcconfig = {
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES',
    'DEFINES_MODULE' => 'YES',
    'ONLY_ACTIVE_ARCH[sdk=iphonesimulator*]' => 'YES'
  }
  s.user_target_xcconfig = {
    'ENABLE_TESTING_SEARCH_PATHS' => 'YES'
  }

  s.swift_version = '5.0'
end
