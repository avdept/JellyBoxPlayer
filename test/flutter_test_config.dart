import 'dart:async';
import 'dart:ui';

import 'package:jplayer/generated/l10n.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await S.load(const Locale('en'));
  await testMain();
}
