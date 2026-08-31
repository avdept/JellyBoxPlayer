import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';

const _showDelay = Duration(milliseconds: 350);
const _fadeDuration = Duration(milliseconds: 120);

class RailTooltip extends StatefulWidget {
  const RailTooltip({
    required this.message,
    required this.child,
    this.enabled = true,
    this.gap = 10,
    super.key,
  });

  final String message;
  final Widget child;
  final bool enabled;
  final double gap;

  @override
  State<RailTooltip> createState() => _RailTooltipState();
}

class _RailTooltipState extends State<RailTooltip> {
  final _link = LayerLink();
  final _controller = OverlayPortalController();
  Timer? _timer;

  @override
  void didUpdateWidget(RailTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _hide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleShow() {
    if (!widget.enabled) return;
    _timer?.cancel();
    _timer = Timer(_showDelay, () {
      if (mounted && widget.enabled) _controller.show();
    });
  }

  void _hide() {
    _timer?.cancel();
    if (_controller.isShowing) _controller.hide();
  }

  Widget _bubble(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.centerRight,
        followerAnchor: Alignment.centerLeft,
        offset: Offset(widget.gap, 0),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: _fadeDuration,
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Themes.changelogSurface,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _scheduleShow(),
        onExit: (_) => _hide(),
        child: Listener(
          onPointerDown: (_) => _hide(),
          child: OverlayPortal(
            controller: _controller,
            overlayLocation: OverlayChildLocation.rootOverlay,
            overlayChildBuilder: _bubble,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
