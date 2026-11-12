import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_popularity.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  LibraryItem song(
    String id,
    String name, {
    Map<String, String> ids = const {},
  }) => LibraryItem(id: id, name: name, kind: ItemKind.song, externalIds: ids);

  ListenBrainzRecording recording(String mbid, String name) =>
      ListenBrainzRecording(mbid: mbid, name: name);

  group('rankByListenBrainz', () {
    test('- orders songs by their recording rank and drops the rest', () {
      final ranked = rankByListenBrainz(
        [
          song(
            's1',
            'Glory Box',
            ids: {
              ExternalIdProvider.musicBrainzRecording: 'mb-glory',
            },
          ),
          song(
            's2',
            'Roads',
            ids: {
              ExternalIdProvider.musicBrainzTrack: 'mb-roads',
            },
          ),
          song(
            's3',
            'Unknown Tune',
            ids: {
              ExternalIdProvider.musicBrainzRecording: 'mb-nowhere',
            },
          ),
        ],
        [recording('mb-roads', 'Roads'), recording('mb-glory', 'Glory Box')],
      );

      expect(ranked.map((song) => song.id), ['s2', 's1']);
    });

    test(
      '- matches untagged songs by title, ignoring case and punctuation',
      () {
        final ranked = rankByListenBrainz(
          [song('s1', "Sour Times (Nobody's Love)"), song('s2', 'Roads')],
          [
            recording('mb-roads', 'Roads'),
            recording('mb-sour', 'Sour Times: Nobody’s Love'),
          ],
        );

        expect(ranked.map((song) => song.id), ['s2', 's1']);
      },
    );

    test('- keeps one song per recording when the library has duplicates', () {
      final ranked = rankByListenBrainz(
        [
          song(
            'album-copy',
            'Roads',
            ids: {
              ExternalIdProvider.musicBrainzRecording: 'mb-roads',
            },
          ),
          song('compilation-copy', 'Roads'),
        ],
        [recording('mb-roads', 'Roads')],
      );

      expect(ranked.map((song) => song.id), ['album-copy']);
    });

    test(
      '- prefers the recording id over a title that matches another rank',
      () {
        final ranked = rankByListenBrainz(
          [
            song(
              's1',
              'Roads',
              ids: {
                ExternalIdProvider.musicBrainzRecording: 'mb-live',
              },
            ),
          ],
          [recording('mb-roads', 'Roads'), recording('mb-live', 'Roads')],
        );

        expect(ranked.single.id, 's1');
      },
    );
  });

  test('ListenBrainzRecording.fromJson reads the popularity payload', () {
    final recording = ListenBrainzRecording.fromJson({
      'recording_mbid': 'mb-roads',
      'recording_name': 'Roads',
      'total_listen_count': 12345,
      'total_user_count': 678,
    });

    expect(recording.mbid, 'mb-roads');
    expect(recording.name, 'Roads');
    expect(recording.listenCount, 12345);
  });
}
