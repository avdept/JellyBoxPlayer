import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_backdrop.dart';

Future<ui.Image> solidImage(Color color, {int width = 4, int height = 4}) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width * 1.0, height * 1.0),
    Paint()..color = color,
  );
  return recorder.endRecording().toImage(width, height);
}

Future<Color> pixelAt(ui.Image image, int x, int y) async {
  final data = (await image.toByteData())!;
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

void main() {
  test('backdrop is a small dimmed cover that fades to black', () async {
    final rendered = await TvBackdrop.render(
      await solidImage(const Color(0xFFFF0000), width: 600, height: 600),
    );
    expect(rendered.width, TvBackdrop.width);
    expect(rendered.height, TvBackdrop.height);

    final top = await pixelAt(rendered, rendered.width ~/ 2, 2);
    final bottom = await pixelAt(
      rendered,
      rendered.width ~/ 2,
      rendered.height - 1,
    );
    expect(top.a, 1);
    expect(top.r, greaterThan(0.3));
    expect(top.r, lessThan(0.5));
    expect(top.g, 0);
    expect(bottom.r, lessThan(0.02));
  });

  test('same artwork is rendered once', () async {
    final image = MemoryImage(Uint8List.fromList(const [1, 2, 3]));
    expect(identical(TvBackdrop.of(image), TvBackdrop.of(image)), isTrue);
  });
}
