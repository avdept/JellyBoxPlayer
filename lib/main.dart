import 'package:flutter/material.dart';
import 'package:jplayer/src/app.dart';
import 'package:jplayer/src/screen_factory.dart';

void main() {
  runApp(
    const App(
      screenFactory: ScreenFactory(),
    ),
  );
}
