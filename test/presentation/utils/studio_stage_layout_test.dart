import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/utils/studio_stage_layout.dart';

void main() {
  const controlsHeight = 190.0;

  StudioStageLayout layout(double width, double height) => StudioStageLayout.of(
    Size(width, height),
    controlsHeight: controlsHeight,
  );

  void expectControlsFit(StudioStageLayout stage, double height) {
    final controlsBottom =
        (height + stage.coverSize) / 2 + StudioStageLayout.gap + controlsHeight;
    expect(
      controlsBottom,
      lessThanOrEqualTo(height - StudioStageLayout.margin),
    );
  }

  test('- a tall screen keeps the full-size cover', () {
    final stage = layout(1920, 1080);
    expect(stage.mode, StudioStageMode.stacked);
    expect(stage.coverSize, StudioStageLayout.maxCover);
    expectControlsFit(stage, 1080);
  });

  test('- a shorter screen squeezes the cover so the controls still fit', () {
    final stage = layout(1440, 760);
    expect(stage.mode, StudioStageMode.stacked);
    expect(stage.coverSize, lessThan(760 * 0.5));
    expect(
      stage.coverSize,
      greaterThanOrEqualTo(StudioStageLayout.minStackedCover),
    );
    expectControlsFit(stage, 760);
  });

  test('- a screen too short to squeeze goes side by side', () {
    final stage = layout(1280, 520);
    expect(stage.mode, StudioStageMode.sideBySide);
    expect(stage.coverSize, 520 - 2 * StudioStageLayout.margin);
    expect(stage.controlsWidth, StudioStageLayout.maxSideControlsWidth);
    expect(
      stage.coverSize + StudioStageLayout.sideGap + stage.controlsWidth,
      lessThanOrEqualTo(1280 - 2 * StudioStageLayout.margin),
    );
  });

  test('- a small, narrow window keeps the squeezed stack', () {
    final stage = layout(320, 560);
    expect(stage.mode, StudioStageMode.stacked);
    expect(stage.coverSize, greaterThanOrEqualTo(0));
  });
}
