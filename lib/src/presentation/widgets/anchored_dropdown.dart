import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DropDirection { up, down }

enum DropAlignment { start, center, end }

class AnchoredDropdownController {
  _AnchoredDropdownState? _state;

  bool get isOpen => _state?.isOpen ?? false;

  void open() => _state?.open();

  void close() => _state?.close();

  void toggle() => isOpen ? close() : open();

  void _attach(_AnchoredDropdownState state) => _state = state;

  void _detach(_AnchoredDropdownState state) {
    if (_state == state) _state = null;
  }
}

class AnchoredDropdown extends StatefulWidget {
  const AnchoredDropdown({
    required this.controller,
    required this.menuBuilder,
    required this.child,
    this.direction = DropDirection.down,
    this.alignment = DropAlignment.end,
    this.gap = 8,
    this.margin = 12,
    this.dismissOnTapOutside = true,
    super.key,
  });

  final AnchoredDropdownController controller;
  final WidgetBuilder menuBuilder;
  final Widget child;
  final DropDirection direction;
  final DropAlignment alignment;
  final double gap;
  final double margin;
  final bool dismissOnTapOutside;

  @override
  State<AnchoredDropdown> createState() => _AnchoredDropdownState();
}

class _AnchoredDropdownState extends State<AnchoredDropdown> {
  final _portal = OverlayPortalController();

  Rect _anchor = Rect.zero;

  bool get isOpen => _portal.isShowing;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(AnchoredDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  void open() {
    setState(() => _anchor = _anchorRect());
    _portal.show();
  }

  void close() {
    if (_portal.isShowing) _portal.hide();
  }

  Rect _anchorRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    return box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (context) => Stack(
      children: [
        if (widget.dismissOnTapOutside)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
            ),
          ),
        CustomSingleChildLayout(
          delegate: _DropLayout(
            anchor: _anchor,
            direction: widget.direction,
            alignment: widget.alignment,
            gap: widget.gap,
            margin: widget.margin,
          ),
          child: widget.menuBuilder(context),
        ),
      ],
    ),
    child: widget.child,
  );
}

class _DropLayout extends SingleChildLayoutDelegate {
  const _DropLayout({
    required this.anchor,
    required this.direction,
    required this.alignment,
    required this.gap,
    required this.margin,
  });

  final Rect anchor;
  final DropDirection direction;
  final DropAlignment alignment;
  final double gap;
  final double margin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          math.max(0, constraints.maxWidth - margin * 2),
          math.max(0, constraints.maxHeight - margin * 2),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      Offset(_horizontal(size, childSize), _vertical(size, childSize));

  double _horizontal(Size size, Size childSize) {
    final maxLeft = math.max(margin, size.width - childSize.width - margin);
    return switch (alignment) {
      DropAlignment.center => (size.width - childSize.width) / 2,
      DropAlignment.start => anchor.left.clamp(margin, maxLeft),
      DropAlignment.end => (anchor.right - childSize.width).clamp(
        margin,
        maxLeft,
      ),
    };
  }

  double _vertical(Size size, Size childSize) {
    final above = anchor.top - childSize.height - gap;
    final below = anchor.bottom + gap;
    final maxTop = math.max(margin, size.height - childSize.height - margin);

    return switch (direction) {
      DropDirection.up => above >= margin ? above : math.min(below, maxTop),
      DropDirection.down => below <= maxTop ? below : math.max(margin, above),
    };
  }

  @override
  bool shouldRelayout(_DropLayout oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.direction != direction ||
      oldDelegate.alignment != alignment ||
      oldDelegate.gap != gap ||
      oldDelegate.margin != margin;
}
