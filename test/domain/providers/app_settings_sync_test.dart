import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 11, 22, 10);

  Future<AppSettingsNotifier> notifierWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    return AppSettingsNotifier(
      await SharedPreferences.getInstance(),
      now: () => now,
    );
  }

  test('values set before stamps existed sync once, as the oldest', () async {
    final notifier = await notifierWith({
      'app_settings': jsonEncode({
        'letter_ruler': false,
        'stream_quality_wifi': 'low',
      }),
    });

    expect(notifier.syncedValues, {'letter_ruler': false});
    expect(notifier.syncStamps, {'letter_ruler': 1});
  });

  test('a local change is stamped with the clock', () async {
    final notifier = await notifierWith({});

    notifier.setEnabled(AppSetting.letterRuler, value: false);

    expect(notifier.syncStamps, {
      'letter_ruler': now.millisecondsSinceEpoch,
    });
    expect(notifier.syncedValues, {'letter_ruler': false});
  });

  test('a remote value keeps its own stamp and skips local keys', () async {
    final notifier = await notifierWith({});

    notifier.applyRemote(
      {'letter_ruler': false, 'stream_quality_wifi': 'low', 'unknown': 1},
      {'letter_ruler': 500, 'stream_quality_wifi': 500, 'unknown': 500},
    );

    expect(notifier.isEnabled(AppSetting.letterRuler), isFalse);
    expect(notifier.syncStamps, {'letter_ruler': 500});
    expect(notifier.valueOf(AppSetting.streamQualityWifi), 'original');
  });
}
