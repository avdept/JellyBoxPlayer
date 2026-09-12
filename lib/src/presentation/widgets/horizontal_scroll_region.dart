import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef HorizontalScrollBuilder =
    Widget Function(BuildContext context, ScrollController controller);

class HorizontalScrollRegion extends StatefulWidget {
  const HorizontalScrollRegion({
    required this.builder,
    this.controlsHeight,
    this.controlsInset = 8,
    super.key,
  });

  final HorizontalScrollBuilder builder;
  final double? controlsHeight;
  final double controlsInset;

  @override
  State<HorizontalScrollRegion> createState() => _HorizontalScrollRegionState();
}

class _HorizontalScrollRegionState extends State<HorizontalScrollRegion> {
  static const _edgeTolerance = 1.0;
  static const _pageFraction = 0.45;
  static const _pageDuration = Duration(milliseconds: 550);

  final _controller = ScrollController();
  final _hovered = ValueNotifier<bool>(false);
  final _canScrollBack = ValueNotifier<bool>(false);
  final _canScrollForward = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEdges);
  }

  void _syncEdges() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions || !position.hasPixels) return;
    _canScrollBack.value =
        position.pixels > position.minScrollExtent + _edgeTolerance;
    _canScrollForward.value =
        position.pixels < position.maxScrollExtent - _edgeTolerance;
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) _syncEdges();
    return false;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (event.kind != PointerDeviceKind.mouse) return;
    if (HardwareKeyboard.instance.isShiftPressed) return;
    final delta = event.scrollDelta;
    if (delta.dy == 0 || delta.dx != 0) return;
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    final target = (position.pixels + delta.dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;

    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => position.pointerScroll(delta.dy),
    );
  }

  void _page(int direction) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final step = position.viewportDimension * _pageFraction;
    final target = (position.pixels + step * direction).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: MouseRegion(
        onEnter: (_) => _hovered.value = true,
        onExit: (_) => _hovered.value = false,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _onMetrics,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.builder(context, _controller),
              _control(
                alignment: Alignment.centerLeft,
                enabled: _canScrollBack,
                icon: Icons.chevron_left,
                onPressed: () => _page(-1),
              ),
              _control(
                alignment: Alignment.centerRight,
                enabled: _canScrollForward,
                icon: Icons.chevron_right,
                onPressed: () => _page(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _control({
    required Alignment alignment,
    required ValueNotifier<bool> enabled,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final button = _EdgeChevron(icon: icon, onPressed: onPressed);
    final visibility = ValueListenableBuilder(
      valueListenable: _hovered,
      builder: (context, hovered, child) => ValueListenableBuilder(
        valueListenable: enabled,
        builder: (context, canScroll, child) {
          final visible = hovered && canScroll;
          return IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: child,
            ),
          );
        },
        child: child,
      ),
      child: button,
    );

    return Positioned(
      left: alignment.x < 0 ? widget.controlsInset : null,
      right: alignment.x > 0 ? widget.controlsInset : null,
      top: 0,
      bottom: widget.controlsHeight == null ? 0 : null,
      height: widget.controlsHeight,
      child: Center(child: visibility),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncEdges)
      ..dispose();
    _hovered.dispose();
    _canScrollBack.dispose();
    _canScrollForward.dispose();
    super.dispose();
  }
}

class _EdgeChevron extends StatelessWidget {
  const _EdgeChevron({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 28, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
