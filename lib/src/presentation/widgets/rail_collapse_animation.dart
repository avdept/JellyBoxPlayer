import 'package:flutter/material.dart';

const railCollapseDuration = Duration(milliseconds: 320);
const Curve railWidthCurve = Curves.easeInOut;
const Curve railAlignCurve = Interval(0, 0.45, curve: Curves.easeInOut);
const Curve railLabelCurve = Interval(0.5, 1, curve: Curves.easeInOut);

class RailCollapseAnimation extends InheritedNotifier<Animation<double>> {
  const RailCollapseAnimation({
    required Animation<double> animation,
    required super.child,
    super.key,
  }) : super(notifier: animation);

  static double progressOf(BuildContext context, Curve curve) {
    final animation = context
        .dependOnInheritedWidgetOfExactType<RailCollapseAnimation>()
        ?.notifier;
    return curve.transform((animation?.value ?? 1).clamp(0, 1));
  }
}

class CollapsibleLabel extends StatelessWidget {
  const CollapsibleLabel({
    required this.child,
    this.alignment = Alignment.centerRight,
    this.slide = 0.7,
    super.key,
  });

  final Widget child;
  final Alignment alignment;
  final double slide;

  @override
  Widget build(BuildContext context) {
    final t = RailCollapseAnimation.progressOf(context, railLabelCurve);

    if (t == 0) return const SizedBox.shrink();

    return ClipRect(
      child: Align(
        alignment: alignment,
        widthFactor: t,
        child: FractionalTranslation(
          translation: Offset(-slide * (1 - t), 0),
          child: Opacity(
            opacity: (t * 3).clamp(0, 1),
            child: DefaultTextStyle.merge(
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.clip,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
