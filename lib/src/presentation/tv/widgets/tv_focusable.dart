import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';

typedef TvFocusBuilder = Widget Function(BuildContext context, bool focused);

class TvFocusable extends StatefulWidget {
  const TvFocusable({
    required this.builder,
    this.onSelect,
    this.onLongSelect,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.scrollOnFocus = true,
    this.scrollAlignment = 0.5,
    this.debugLabel,
    super.key,
  });

  final TvFocusBuilder builder;
  final VoidCallback? onSelect;
  final VoidCallback? onLongSelect;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool scrollOnFocus;
  final double scrollAlignment;
  final String? debugLabel;

  static final selectKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  };

  static final menuKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.contextMenu,
  };

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  FocusNode? _ownNode;
  Timer? _longPress;
  bool _longFired = false;
  bool _focused = false;

  FocusNode get _node =>
      widget.focusNode ??
      (_ownNode ??= FocusNode(debugLabel: widget.debugLabel));

  bool get _interactive =>
      widget.enabled &&
      (widget.onSelect != null || widget.onLongSelect != null);

  @override
  void dispose() {
    _longPress?.cancel();
    _ownNode?.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_interactive) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (TvFocusable.menuKeys.contains(key) && widget.onLongSelect != null) {
      if (event is KeyDownEvent) widget.onLongSelect!();
      return KeyEventResult.handled;
    }
    if (!TvFocusable.selectKeys.contains(key)) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      _longFired = false;
      _longPress?.cancel();
      if (widget.onLongSelect != null) {
        _longPress = Timer(TvTokens.longSelect, () {
          _longFired = true;
          widget.onLongSelect!();
        });
      }
      return KeyEventResult.handled;
    }
    // Android sends a held key as repeats; the first one is the long press.
    if (event is KeyRepeatEvent) {
      if (!_longFired && widget.onLongSelect != null) {
        _longPress?.cancel();
        _longFired = true;
        widget.onLongSelect!();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _longPress?.cancel();
      if (!_longFired) widget.onSelect?.call();
      _longFired = false;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onFocusChange(bool focused) {
    if (!mounted) return;
    setState(() => _focused = focused);
    widget.onFocusChange?.call(focused);
    if (!focused || !widget.scrollOnFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: widget.scrollAlignment,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _tap() {
    _node.requestFocus();
    widget.onSelect?.call();
  }

  void _longTap() {
    _node.requestFocus();
    widget.onLongSelect?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      canRequestFocus: widget.enabled,
      onKeyEvent: _onKey,
      onFocusChange: _onFocusChange,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _interactive ? _tap : null,
        onLongPress: _interactive && widget.onLongSelect != null
            ? _longTap
            : null,
        child: widget.builder(context, _focused),
      ),
    );
  }
}

class TvFocusFrame extends StatelessWidget {
  const TvFocusFrame({
    required this.focused,
    required this.child,
    this.borderRadius = TvTokens.cardRadius,
    this.scale = TvTokens.focusScale,
    super.key,
  });

  final bool focused;
  final Widget child;
  final BorderRadius borderRadius;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: focused ? scale : 1,
      duration: TvTokens.focusDuration,
      curve: TvTokens.focusCurve,
      child: AnimatedContainer(
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: focused ? TvTokens.glow() : const [],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: focused ? TvTokens.focusRing : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: ClipRRect(borderRadius: borderRadius, child: child),
      ),
    );
  }
}
