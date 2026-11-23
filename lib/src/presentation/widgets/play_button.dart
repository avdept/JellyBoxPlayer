import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({
    this.onPressed,
    this.isLoading = false,
    this.color,
    super.key,
  });

  final VoidCallback? onPressed;
  final Color? color;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? AppColors.from(context).accent;
    return MaterialButton(
      onPressed: isLoading ? null : onPressed,
      color: fill,
      disabledColor: fill,
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;

          return isLoading
              ? SizedBox.square(
                  dimension: side * 0.8,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.play_arrow_outlined,
                  size: side,
                );
        },
      ),
    );
  }
}
