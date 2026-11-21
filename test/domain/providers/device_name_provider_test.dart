import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/cloud/cloud_host_adapter.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';

import '../../provider_container.dart';

void main() {
  group('deviceNameProvider', () {
    test('- uses the platform name until the user picks one', () {
      final container = createProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith((_) => AppSettingsNotifier(null)),
        ],
      );

      expect(container.read(deviceNameProvider), continuityDeviceName());
    });

    test('- shows the name the user typed, trimmed', () {
      final container = createProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith((_) => AppSettingsNotifier(null)),
        ],
      );

      container
          .read(appSettingsProvider.notifier)
          .setValue(AppSetting.deviceName, '  Kitchen ATV ');

      expect(container.read(deviceNameProvider), 'Kitchen ATV');
    });

    test('- falls back to the platform name when cleared', () {
      final container = createProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith((_) => AppSettingsNotifier(null)),
        ],
      );
      final settings = container.read(appSettingsProvider.notifier)
        ..setValue(AppSetting.deviceName, 'Library iPad');
      expect(container.read(deviceNameProvider), 'Library iPad');

      settings.setValue(AppSetting.deviceName, '   ');

      expect(container.read(deviceNameProvider), continuityDeviceName());
    });
  });
}
