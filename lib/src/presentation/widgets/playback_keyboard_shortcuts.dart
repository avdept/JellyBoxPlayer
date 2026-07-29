import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

/// Handles app-wide playback shortcuts on desktop.
///
/// Space toggles play/pause, unless a text input has focus or a focused
/// descendant (a button, for example) already handled the key.
class PlaybackKeyboardShortcuts extends ConsumerWidget {
  const PlaybackKeyboardShortcuts({required this.child, super.key});

  final Widget child;

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  bool get _isTextInputFocused {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isDesktop) return child;

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.space ||
            _isTextInputFocused) {
          return KeyEventResult.ignored;
        }
        unawaited(ref.read(playbackProvider.notifier).playPause());
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}
