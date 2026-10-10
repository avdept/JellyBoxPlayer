import 'dart:io';

import 'package:flutter/material.dart';

class CustomScrollbar extends StatelessWidget {
  const CustomScrollbar({
    required this.child,
    this.controller,
    this.enabled = true,
    super.key,
  });

  final ScrollController? controller;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return (!enabled ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)
        ? child // Desktop platforms have scrollbars by default
        : Scrollbar(
            controller: controller,
            child: child,
          );
  }
}
