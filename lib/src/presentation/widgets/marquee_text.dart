import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class MarqueeText extends StatefulWidget {
  const MarqueeText(
    this.text, {
    this.style,
    this.gap = 32,
    this.velocity = 30,
    this.pause = const Duration(seconds: 2),
    this.bounce = false,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final double gap;
  final double velocity;
  final Duration pause;
  final bool bounce;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  );
  double? _distance;
  int _run = 0;

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _stop();
  }

  @override
  void dispose() {
    _run++;
    _controller.dispose();
    super.dispose();
  }

  void _stop() {
    _run++;
    _distance = null;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller
        ..stop()
        ..value = 0;
    });
  }

  void _scrollOver(double distance) {
    if (_distance == distance) return;
    _stop();
    _distance = distance;
    final run = _run;
    SchedulerBinding.instance.addPostFrameCallback((_) => _loop(run));
  }

  Future<void> _loop(int run) async {
    while (mounted && run == _run) {
      await Future<void>.delayed(widget.pause);
      final distance = _distance;
      if (!mounted || run != _run || distance == null) return;
      _controller.duration = Duration(
        milliseconds: (distance / widget.velocity * 1000).round(),
      );
      try {
        await _controller.forward(from: 0).orCancel;
        if (widget.bounce) {
          await Future<void>.delayed(widget.pause);
          if (!mounted || run != _run) return;
          await _controller.reverse().orCancel;
        }
      } on TickerCanceled {
        return;
      }
      if (mounted && run == _run) _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final text = Text(
      widget.text,
      style: style,
      maxLines: 1,
      softWrap: false,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final width = painter.width;
        final height = painter.height;
        painter.dispose();

        final still =
            width <= constraints.maxWidth ||
            MediaQuery.disableAnimationsOf(context);
        if (still) {
          if (_distance != null) _stop();
          return Text(
            widget.text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        final distance = widget.bounce
            ? width - constraints.maxWidth
            : width + widget.gap;
        _scrollOver(distance);

        return ClipRect(
          child: SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_controller.value * distance, 0),
                child: child,
              ),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: widget.bounce
                    ? text
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          text,
                          SizedBox(width: widget.gap),
                          text,
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
