import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ColorTheme> themeAfterLaunch(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    await AppSettingsNotifier.pinColorTheme(prefs);
    return ColorTheme.values.byName(
      AppSettingsNotifier.valueIn(prefs, AppSetting.colorTheme),
    );
  }

  test('- a fresh install starts on Oxblood', () async {
    expect(await themeAfterLaunch({}), ColorTheme.oxblood);
  });

  test('- an upgrade with saved settings keeps the original look', () async {
    final theme = await themeAfterLaunch({
      'app_settings': jsonEncode({'sidebar_collapsed': false}),
    });

    expect(theme, ColorTheme.original);
  });

  test('- an upgrade with a chosen library keeps the original look', () async {
    expect(
      await themeAfterLaunch({'library_id': 'music'}),
      ColorTheme.original,
    );
  });

  test('- the other saved settings survive the upgrade', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings': jsonEncode({'sidebar_collapsed': false}),
    });
    final prefs = await SharedPreferences.getInstance();
    await AppSettingsNotifier.pinColorTheme(prefs);

    expect(
      AppSettingsNotifier.isEnabledIn(prefs, AppSetting.sidebarCollapsed),
      isFalse,
    );
  });

  test('- a theme the user already picked is never replaced', () async {
    final theme = await themeAfterLaunch({
      'app_settings': jsonEncode({'color_theme': 'leica'}),
      'library_id': 'music',
    });

    expect(theme, ColorTheme.leica);
  });

  test('- a fresh install stays on Oxblood after signing in', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await AppSettingsNotifier.pinColorTheme(prefs);
    await prefs.setString('library_id', 'music');
    await AppSettingsNotifier.pinColorTheme(prefs);

    expect(
      AppSettingsNotifier.valueIn(prefs, AppSetting.colorTheme),
      ColorTheme.oxblood.name,
    );
  });
}
