import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';

Widget createTestApp({
  required Widget home,
  List<Override> providesOverrides = const [],
  List<ProviderObserver>? providesObservers,
}) {
  return ProviderScope(
    overrides: providesOverrides,
    observers: providesObservers,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        S.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: Themes.red,
      home: home,
    ),
  );
}
