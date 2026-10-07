import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

final bool _isHyprland =
    Platform.environment.containsKey('HYPRLAND_INSTANCE_SIGNATURE') ||
    (Platform.environment['XDG_CURRENT_DESKTOP']?.toLowerCase() == 'hyprland');

final bool needsWindowResizeFrame = Platform.isLinux && !_isHyprland;

final bool showsDesktopTitleBar = needsWindowResizeFrame || Platform.isWindows;

class DesktopTitleBar extends StatefulWidget {
  const DesktopTitleBar({super.key});

  @override
  State<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends State<DesktopTitleBar> with WindowListener {
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

class WindowResizeFrame extends StatefulWidget {
  const WindowResizeFrame({required this.child, super.key});

  final Widget child;

  @override
  State<WindowResizeFrame> createState() => _WindowResizeFrameState();
}

class _WindowResizeFrameState extends State<WindowResizeFrame>
    with WindowListener {
  bool _isMaximized = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncWindowState());
  }

  Future<void> _syncWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    final isFullScreen = await windowManager.isFullScreen();
    if (!mounted) return;
    setState(() {
      _isMaximized = isMaximized;
      _isFullScreen = isFullScreen;
    });
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  void onWindowEnterFullScreen() => setState(() => _isFullScreen = true);

  @override
  void onWindowLeaveFullScreen() => setState(() => _isFullScreen = false);

  @override
  Widget build(BuildContext context) {
    if (!needsWindowResizeFrame) return widget.child;
    return DragToResizeArea(
      enableResizeEdges: _isMaximized || _isFullScreen ? const [] : null,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }
}
