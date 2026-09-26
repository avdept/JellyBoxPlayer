import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/frosted_panel.dart';

class SidebarOverlay extends StatelessWidget {
  const SidebarOverlay({
    required this.isShown,
    required this.onClose,
    required this.child,
    this.title,
    this.width = 380,
    this.duration = const Duration(milliseconds: 250),
    super.key,
  });

  final bool isShown;
  final VoidCallback onClose;
  final Widget child;
  final String? title;
  final double width;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      ignoring: !isShown,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: isShown ? 1 : 0, end: isShown ? 1 : 0),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, panel) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: value,
                  child: const ColoredBox(color: Colors.black54),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: -width * (1 - value),
              width: width,
              child: Visibility(
                visible: value > 0,
                maintainState: true,
                child: panel!,
              ),
            ),
          ],
        ),
        child: FrostedPanel(
          elevation: 12,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        color: theme.colorScheme.onPrimary,
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
