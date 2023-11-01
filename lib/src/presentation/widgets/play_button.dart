import 'package:flutter/material.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({
    this.onPressed,
    super.key,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: const Color(0xFF0066FF),
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) => Icon(
          Icons.play_arrow_outlined,
          size: constraints.biggest.shortestSide,
        ),
      ),
    );
  }
}
