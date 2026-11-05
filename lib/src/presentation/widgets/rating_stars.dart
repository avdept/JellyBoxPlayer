import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef RatingChanged = FutureOr<void> Function(int rating);

class RatingStars extends StatefulWidget {
  const RatingStars({
    required this.rating,
    this.onChanged,
    this.size = 20,
    this.color,
    this.emptyColor,
    this.spacing = 0,
    this.touchPadding = EdgeInsets.zero,
    super.key,
  });

  final int rating;
  final RatingChanged? onChanged;
  final double size;
  final Color? color;
  final Color? emptyColor;
  final double spacing;
  final EdgeInsets touchPadding;

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  int? _hovered;
  int? _dragged;
  int? _pending;
  var _saving = false;

  @override
  void didUpdateWidget(RatingStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating && !_saving) _pending = null;
  }

  void _setHovered(int? value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  int _valueAt(Offset position) {
    final box = context.findRenderObject()! as RenderBox;
    final slack = widget.size;
    final stars = widget.touchPadding.deflateRect(Offset.zero & box.size);
    final outside =
        position.dy < stars.top - slack ||
        position.dy > stars.bottom + slack ||
        position.dx < -slack;
    if (outside) return 0;
    final fraction = (position.dx - stars.left) / stars.width;
    return (fraction * 5).ceil().clamp(position.dx < 0 ? 0 : 1, 5);
  }

  void _onTapUp(TapUpDetails details) {
    final value = _valueAt(details.localPosition);
    final current = _pending ?? widget.rating;
    unawaited(_commit(value == 1 && current == 1 ? 0 : value));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final value = _valueAt(details.localPosition);
    if (_dragged == value) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _dragged = value);
  }

  void _onDragEnd(DragEndDetails details) {
    final value = _dragged;
    _dragged = null;
    if (value != null) unawaited(_commit(value));
  }

  void _onDragCancel() {
    if (_dragged != null) setState(() => _dragged = null);
  }

  Future<void> _commit(int value) async {
    setState(() {
      _pending = value;
      _saving = true;
    });
    var saved = false;
    try {
      await widget.onChanged!(value);
      saved = true;
    } on Object {
      saved = false;
    }
    if (!mounted || _pending != value) return;
    setState(() {
      _saving = false;
      if (!saved || widget.rating == value) _pending = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = widget.color ?? scheme.primary;
    final empty = widget.emptyColor ?? scheme.onPrimary.withValues(alpha: 0.35);
    final editable = widget.onChanged != null;
    final preview = editable ? _dragged ?? _hovered : null;
    final current = _pending ?? widget.rating;
    final shown = preview ?? current;
    final dimmed = preview != null || _saving;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = 1; value <= 5; value++)
          Padding(
            padding: EdgeInsets.only(right: value < 5 ? widget.spacing : 0),
            child: _Star(
              filled: value <= shown,
              size: widget.size,
              color: value > shown
                  ? empty
                  : dimmed
                  ? filled.withValues(alpha: 0.6)
                  : filled,
              onHover: editable
                  ? (inside) => _setHovered(inside ? value : null)
                  : null,
            ),
          ),
      ],
    );
    if (!editable) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      onHorizontalDragStart: (details) => _onDragUpdate(
        DragUpdateDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
        ),
      ),
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: Padding(padding: widget.touchPadding, child: row),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.filled,
    required this.size,
    required this.color,
    required this.onHover,
  });

  final bool filled;
  final double size;
  final Color color;
  final ValueChanged<bool>? onHover;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: color,
    );
    final hover = onHover;
    if (hover == null) return icon;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hover(true),
      onExit: (_) => hover(false),
      child: icon,
    );
  }
}
