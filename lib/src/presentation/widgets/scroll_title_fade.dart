import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ScrollTitleFade extends ValueNotifier<double> {
  ScrollTitleFade({
    required this.controller,
    required this.titleKey,
    this.inset = 0,
  }) : super(0) {
    controller.addListener(update);
  }

  final ScrollController controller;
  final GlobalKey titleKey;
  double inset;

  void update() {
    final titleContext = titleKey.currentContext;
    if (!(titleContext?.mounted ?? false) || !controller.hasClients) return;
    final scrollable =
        controller.position.context.notificationContext!.findRenderObject()!
            as RenderBox;
    final titleBox = titleContext!.findRenderObject()! as RenderBox;
    final top = titleBox.localToGlobal(Offset.zero, ancestor: scrollable).dy;
    final height = titleBox.size.height;
    if (height == 0) return;
    final visible = (top - inset + height) / height;
    value = 1 - visible.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    controller.removeListener(update);
    super.dispose();
  }
}

class FadingNavTitle extends StatelessWidget {
  const FadingNavTitle({required this.opacity, required this.child, super.key});

  final ValueListenable<double> opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: opacity,
    builder: (context, opacity, child) => Transform.translate(
      offset: Offset(0, 8 - 8 * opacity),
      child: Opacity(opacity: opacity, child: child),
    ),
    child: child,
  );
}
