import 'dart:io';

import 'package:flutter/material.dart';

class CustomScrollbar extends StatelessWidget {
  const CustomScrollbar({
    required this.child,
    this.controller,
    super.key,
  });

  final ScrollController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
        ? child // Desktop platforms have scrollbars by default
        : Scrollbar(
            controller: controller,
            child: child,
          );
  }
}
