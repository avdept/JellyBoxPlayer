import 'dart:math';
import 'dart:ui';

enum StudioStageMode { stacked, sideBySide }

class StudioStageLayout {
  const StudioStageLayout({
    required this.mode,
    required this.coverSize,
    required this.controlsWidth,
  });

  factory StudioStageLayout.of(Size area, {required double controlsHeight}) {
    final stackedControlsWidth = min(maxControlsWidth, area.width - 2 * margin);
    final stackedCover = [
      area.height * 0.5,
      area.width * 0.7,
      maxCover,
      area.height - 2 * (controlsHeight + gap + margin),
    ].reduce(min);
    final stacked = StudioStageLayout(
      mode: StudioStageMode.stacked,
      coverSize: max(0, stackedCover),
      controlsWidth: max(0, stackedControlsWidth),
    );
    if (stackedCover >= minStackedCover) return stacked;

    final sideControlsWidth = min(
      maxSideControlsWidth,
      (area.width - 2 * margin - sideGap) / 2,
    );
    final sideCover = [
      area.height - 2 * margin,
      area.width - 2 * margin - sideGap - sideControlsWidth,
      maxCover,
    ].reduce(min);
    if (sideCover <= stackedCover || sideControlsWidth < minSideControlsWidth) {
      return stacked;
    }
    return StudioStageLayout(
      mode: StudioStageMode.sideBySide,
      coverSize: sideCover,
      controlsWidth: sideControlsWidth,
    );
  }

  static const gap = 20.0;
  static const sideGap = 40.0;
  static const margin = 24.0;
  static const maxCover = 480.0;
  static const minStackedCover = 200.0;
  static const maxControlsWidth = 432.0;
  static const minSideControlsWidth = 260.0;
  static const maxSideControlsWidth = 400.0;

  final StudioStageMode mode;
  final double coverSize;
  final double controlsWidth;
}
