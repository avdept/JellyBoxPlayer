import 'package:flutter_chrome_cast/entities/discovery_criteria.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';

/// iOS-specific Google Cast options.
///
/// This class extends [GoogleCastOptions] to provide additional configuration
/// for iOS, such as specifying discovery criteria for Cast devices.
class IOSGoogleCastOptions extends GoogleCastOptions {
  /// The discovery criteria used to find Cast devices on iOS.
  final GoogleCastDiscoveryCriteriaInitialize _discoveryCriteria;

  /// Creates an instance of [IOSGoogleCastOptions] with the given [discoveryCriteria].
  ///
  /// All [GoogleCastOptions] fields are forwarded to the native iOS Cast SDK:
  ///
  /// [physicalVolumeButtonsWillControlDeviceVolume] controls whether hardware
  /// volume buttons adjust the Cast device volume. Defaults to true.
  ///
  /// [suspendSessionsWhenBackgrounded] when false, keeps the Cast session alive
  /// while the app is in the background. Defaults to true.
  ///
  /// [disableDiscoveryAutostart] when true, prevents automatic device discovery
  /// at startup. Defaults to false.
  ///
  /// [disableAnalyticsLogging] when true, disables Google Cast analytics.
  /// Defaults to false.
  ///
  /// [stopReceiverApplicationWhenEndingSession] when true, stops the receiver
  /// app when the session ends. Defaults to false.
  ///
  /// [startDiscoveryAfterFirstTapOnCastButton] controls when discovery starts.
  /// Defaults to true.
  ///
  /// [stopCastingOnAppTerminated] when true, automatically stops casting and
  /// ends the session when the app is killed/terminated. Defaults to false.
  IOSGoogleCastOptions(
    this._discoveryCriteria, {
    super.physicalVolumeButtonsWillControlDeviceVolume,
    super.suspendSessionsWhenBackgrounded,
    super.disableDiscoveryAutostart,
    super.disableAnalyticsLogging,
    super.stopReceiverApplicationWhenEndingSession,
    super.startDiscoveryAfterFirstTapOnCastButton,
    super.stopCastingOnAppTerminated,
  });

  /// Converts this iOS Cast options object to a map representation.
  ///
  /// The returned map includes all base options and the iOS-specific discovery criteria.
  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll(
        {
          'discoveryCriteria': _discoveryCriteria.toMap(),
        },
      );
  }
}
