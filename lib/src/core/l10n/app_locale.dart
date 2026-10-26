import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart'
    show WidgetsBinding, basicLocaleListResolution;
import 'package:jplayer/generated/l10n.dart';

Locale resolveAppLocale(Locale? override) {
  if (override != null && S.delegate.isSupported(override)) return override;
  return basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales,
    S.delegate.supportedLocales,
  );
}

Future<void> reloadAppLocale(Locale? override) =>
    S.load(resolveAppLocale(override));
