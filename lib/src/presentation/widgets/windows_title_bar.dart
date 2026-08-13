import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Window controls for Windows, where the native title bar is hidden
/// (TitleBarStyle.hidden in main.dart). Mirrors the bitsdojo_window title
/// bar used on Linux: a drag-to-move strip with minimize/maximize/close
/// buttons in the top right corner.
class WindowsTitleBar extends StatefulWidget {
  const WindowsTitleBar({super.key});

  @override
  State<WindowsTitleBar> createState() => _WindowsTitleBarState();
}

class _WindowsTitleBarState extends State<WindowsTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncMaximizedState());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncMaximizedState() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted && isMaximized != _isMaximized) {
      setState(() => _isMaximized = isMaximized);
    }
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: kWindowCaptionHeight,
      child: Row(
        children: [
          const Expanded(
            child: DragToMoveArea(child: SizedBox.expand()),
          ),
          WindowCaptionButton.minimize(
            brightness: brightness,
            onPressed: windowManager.minimize,
          ),
          if (_isMaximized)
            WindowCaptionButton.unmaximize(
              brightness: brightness,
              onPressed: windowManager.unmaximize,
            )
          else
            WindowCaptionButton.maximize(
              brightness: brightness,
              onPressed: windowManager.maximize,
            ),
          WindowCaptionButton.close(
            brightness: brightness,
            onPressed: windowManager.close,
          ),
        ],
      ),
    );
  }
}
