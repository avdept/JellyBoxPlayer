import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/app.dart';
import 'package:jplayer/src/screen_factory.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

void main() {
  ResponsiveSizingConfig.instance.setCustomBreakpoints(
    const ScreenBreakpoints(desktop: 1025, tablet: 600, watch: 200),
    customRefinedBreakpoints: const RefinedBreakpoints(),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ImageProvider>(
          create: (context) => const AssetImage(Images.coverSample),
        ),
        Provider<Brightness>.value(value: Brightness.dark),
      ],
      child: const App(
        screenFactory: ScreenFactory(),
      ),
    ),
  );
}
