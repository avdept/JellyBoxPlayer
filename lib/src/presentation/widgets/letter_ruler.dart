import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jplayer/src/data/backend/letter_index.dart';

class LetterRuler extends StatefulWidget {
  const LetterRuler({
    required this.onLetterSelected,
    this.letters = letterIndexLetters,
    this.reversed = false,
    this.width = defaultWidth,
    this.haptics = true,
    this.colorScheme,
    super.key,
  });

  static const defaultWidth = 24.0;
  static const bubbleSize = 52.0;
  static const hoverScales = [1.8, 1.45, 1.15];

  final ValueChanged<String> onLetterSelected;
  final List<String> letters;
  final bool reversed;
  final double width;
  final bool haptics;
  final ColorScheme? colorScheme;

  @override
  State<LetterRuler> createState() => _LetterRulerState();
}

class _LetterRulerState extends State<LetterRuler> {
  int? _activeIndex;
  int? _hoverIndex;

  List<String> get _letters =>
      widget.reversed ? widget.letters.reversed.toList() : widget.letters;

  int _indexAt(double dy, double height) =>
      ((dy / height) * _letters.length).floor().clamp(0, _letters.length - 1);

  double _scaleFor(int index) {
    final hovered = _hoverIndex;
    if (hovered == null) return 1;
    final distance = (index - hovered).abs();
    return distance < LetterRuler.hoverScales.length
        ? LetterRuler.hoverScales[distance]
        : 1;
  }

  void _hover(double dy, double height) {
    final index = _indexAt(dy, height);
    if (index == _hoverIndex) return;
    setState(() => _hoverIndex = index);
  }

  void _unhover() {
    if (_hoverIndex == null) return;
    setState(() => _hoverIndex = null);
  }

  void _select(double dy, double height) {
    final index = _indexAt(dy, height);
    if (index == _activeIndex) return;
    setState(() => _activeIndex = index);
    if (widget.haptics) unawaited(HapticFeedback.selectionClick());
    widget.onLetterSelected(_letters[index]);
  }

  void _release() {
    if (_activeIndex == null) return;
    setState(() => _activeIndex = null);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.maxHeight;
      final letters = _letters;
      final slot = height / letters.length;
      final fontSize = (slot * 0.72).clamp(6.0, 11.0);
      final colors = widget.colorScheme ?? Theme.of(context).colorScheme;
      final active = _activeIndex;
      final hovered = _hoverIndex;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) => _hover(event.localPosition.dy, height),
        onExit: (_) => _unhover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onTapDown: (details) => _select(details.localPosition.dy, height),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          onVerticalDragStart: (details) =>
              _select(details.localPosition.dy, height),
          onVerticalDragUpdate: (details) =>
              _select(details.localPosition.dy, height),
          onVerticalDragEnd: (_) => _release(),
          onVerticalDragCancel: _release,
          child: SizedBox(
            width: widget.width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    for (var i = 0; i < letters.length; i++)
                      Expanded(
                        child: Center(
                          child: AnimatedScale(
                            scale: _scaleFor(i),
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeOut,
                            child: Text(
                              letters[i],
                              style: TextStyle(
                                fontSize: fontSize,
                                height: 1,
                                fontWeight: FontWeight.w600,
                                color: i == active || i == hovered
                                    ? colors.primary
                                    : colors.onSurface.withValues(
                                        alpha: 0.65,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (active != null)
                  Positioned(
                    right: widget.width + 12,
                    top: ((active + 0.5) * slot - LetterRuler.bubbleSize / 2)
                        .clamp(0.0, height - LetterRuler.bubbleSize),
                    child: _LetterBubble(
                      letter: letters[active],
                      colors: colors,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LetterBubble extends StatelessWidget {
  const _LetterBubble({required this.letter, required this.colors});

  final String letter;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: colors.primary,
      borderRadius: BorderRadius.circular(LetterRuler.bubbleSize / 2),
      child: SizedBox.square(
        dimension: LetterRuler.bubbleSize,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: colors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
