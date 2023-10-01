import 'package:flutter/material.dart';

class PlayPauseButton extends StatefulWidget {
  const PlayPauseButton({
    required this.stateNotifier,
    this.background,
    this.foreground,
    this.onPressed,
    super.key,
  });

  final ValueNotifier<bool> stateNotifier;
  final Color? background;
  final Color? foreground;
  final VoidCallback? onPressed;

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  void _onStateChanged() {
    if (_animationController.isAnimating) _animationController.stop();

    if (widget.stateNotifier.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.stateNotifier.addListener(_onStateChanged);
    _animationController = AnimationController(
      value: widget.stateNotifier.value ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stateNotifier != oldWidget.stateNotifier) {
      oldWidget.stateNotifier.removeListener(_onStateChanged);
      widget.stateNotifier.addListener(_onStateChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: widget.onPressed,
      color: widget.background,
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(8),
      minWidth: 0,
      child: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _animationController,
        color: widget.foreground,
      ),
    );
  }

  @override
  void dispose() {
    widget.stateNotifier.removeListener(_onStateChanged);
    _animationController.dispose();
    super.dispose();
  }
}
