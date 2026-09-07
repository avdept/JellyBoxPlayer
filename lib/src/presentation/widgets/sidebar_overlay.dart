import 'package:flutter/material.dart';

class SidebarOverlay extends StatelessWidget {
  const SidebarOverlay({
    required this.isShown,
    required this.onClose,
    required this.child,
    this.title,
    this.backgroundColor,
    this.width = 380,
    this.duration = const Duration(milliseconds: 250),
    super.key,
  });

  final bool isShown;
  final VoidCallback onClose;
  final Widget child;
  final String? title;
  final Color? backgroundColor;
  final double width;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelColor =
        (backgroundColor ??
                theme.bottomSheetTheme.backgroundColor ??
                Colors.black)
            .withValues(alpha: 0.88);

    return IgnorePointer(
      ignoring: !isShown,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: AnimatedOpacity(
                opacity: isShown ? 1 : 0,
                duration: duration,
                child: const ColoredBox(color: Colors.black54),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: width,
            child: AnimatedSlide(
              offset: isShown ? Offset.zero : const Offset(1, 0),
              duration: duration,
              curve: Curves.easeOutCubic,
              child: Material(
                color: panelColor,
                surfaceTintColor: Colors.transparent,
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
          ),
        ],
      ),
    );
  }
}
