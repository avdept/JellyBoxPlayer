import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';
import 'package:jplayer/src/presentation/widgets/hover_zoom.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.readableOn(fill),
                  ),
                )
              : Icon(
                  Icons.play_arrow_outlined,
                  size: side,
                  color: AppColors.readableOn(fill),
                );
        },
      ),
    );
  }
}

class HoverPlayButton extends ConsumerWidget {
  const HoverPlayButton({
    required this.onPressed,
    this.isLoading = false,
    this.size = 36,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => HoverZoom(
    builder: (context, hovered) => SizedBox.square(
      dimension: size,
      child: PlayButton(
        isLoading: isLoading,
        onPressed: onPressed,
        color: hovered ? ref.watch(accentColorProvider) : null,
      ),
    ),
  );
}
