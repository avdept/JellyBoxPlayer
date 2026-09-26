import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/quality_extras.dart';
import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';

void main() {
  const flac = AudioSourceInfo(
    codec: 'flac',
    bitRate: 1000000,
    sampleRate: 96000,
  );
  const aac = AudioSourceInfo(codec: 'aac', bitRate: 256000, sampleRate: 48000);

  test('- keeps both qualities side by side', () {
    final extras = QualityExtras.of(original: flac, streamed: aac);

    expect(QualityExtras.original(extras), flac);
    expect(QualityExtras.streamed(extras), aac);
    expect(QualityExtras.heard(extras), aac);
  });

  test('- hears the original when nothing was streamed', () {
    final extras = QualityExtras.of(original: flac);

    expect(QualityExtras.streamed(extras), isNull);
    expect(QualityExtras.heard(extras), flac);
  });

  test('- reads nothing from missing extras', () {
    expect(QualityExtras.streamed(null), isNull);
    expect(QualityExtras.heard(null), const AudioSourceInfo());
  });
}
