import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class FakePlaybackNotifier extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  FakePlaybackNotifier(super.state);
}

const _songId = 'song-1';

final _synced = LyricsDTO.fromJson({
  'Metadata': {'IsSynced': true},
  'Lyrics': [
    {'Text': 'first line', 'Start': 0},
    {'Text': 'second line', 'Start': 100000000},
    {'Text': 'third line', 'Start': 200000000},
  ],
});

final _unsynced = LyricsDTO.fromJson({
  'Metadata': {'IsSynced': false},
  'Lyrics': [
    {'Text': 'plain one'},
    {'Text': 'plain two'},
  ],
});

PlaybackState _stateAt(Duration position, {bool hasLyrics = true}) =>
    PlaybackState(
      album: null,
      songs: [
        ItemDTO(
          id: _songId,
          name: 'Roads',
          type: 'Audio',
          hasLyrics: hasLyrics,
        ),
      ],
      status: PlaybackStatus.playing,
      position: position,
      cacheProgress: Duration.zero,
      currentMediaIndex: 0,
    );

void main() {
  setUpAll(() => registerFallbackValue(Duration.zero));

  late FakePlaybackNotifier playback;

  Future<void> pumpLyricsView(
    WidgetTester tester, {
    required PlaybackState state,
    LyricsDTO? lyrics,
  }) async {
    playback = FakePlaybackNotifier(state);
    final container = createProviderContainer(
      overrides: [
        playbackProvider.overrideWith((_) => playback),
        lyricsProvider(_songId).overrideWith((_) async => lyrics),
      ],
    );
    await tester.pumpWidget(
      createTestApp(
        providerContainer: container,
        home: const Scaffold(body: LyricsView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextStyle styleOf(WidgetTester tester, String text) => tester
      .widgetList<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      )
      .first
      .style;

  group('LyricsView', () {
    testWidgets('- renders every line of the lyrics', (tester) async {
      await pumpLyricsView(
        tester,
        state: _stateAt(Duration.zero),
        lyrics: _synced,
      );

      expect(find.text('first line'), findsOneWidget);
      expect(find.text('second line'), findsOneWidget);
      expect(find.text('third line'), findsOneWidget);
    });

    testWidgets('- highlights the line matching the playback position', (
      tester,
    ) async {
      await pumpLyricsView(
        tester,
        state: _stateAt(const Duration(seconds: 12)),
        lyrics: _synced,
      );

      final active = styleOf(tester, 'second line');
      final inactive = styleOf(tester, 'third line');

      expect(active.fontWeight, FontWeight.w700);
      expect(active.color, Colors.white);
      expect(inactive.fontWeight, FontWeight.w500);
      expect(inactive.color, isNot(Colors.white));
      expect(active.fontSize, greaterThan(inactive.fontSize!));
    });

    testWidgets('- leaves unsynced lyrics solid white with no active line', (
      tester,
    ) async {
      await pumpLyricsView(
        tester,
        state: _stateAt(const Duration(seconds: 12)),
        lyrics: _unsynced,
      );

      for (final line in ['plain one', 'plain two']) {
        final style = styleOf(tester, line);
        expect(style.color, Colors.white);
        expect(style.fontWeight, FontWeight.w500);
      }
    });

    testWidgets('- seeks to a line when it is tapped', (tester) async {
      await pumpLyricsView(
        tester,
        state: _stateAt(Duration.zero),
        lyrics: _synced,
      );
      when(() => playback.seek(any())).thenAnswer((_) async {});

      await tester.tap(find.text('third line'));
      await tester.pump();

      verify(() => playback.seek(const Duration(seconds: 20))).called(1);
    });

    testWidgets('- ignores taps on unsynced lines', (tester) async {
      await pumpLyricsView(
        tester,
        state: _stateAt(Duration.zero),
        lyrics: _unsynced,
      );
      when(() => playback.seek(any())).thenAnswer((_) async {});

      await tester.tap(find.text('plain two'));
      await tester.pump();

      verifyNever(() => playback.seek(any()));
    });

    testWidgets('- reports when the track has no lyrics', (tester) async {
      await pumpLyricsView(
        tester,
        state: _stateAt(Duration.zero, hasLyrics: false),
        lyrics: null,
      );

      expect(find.text('No lyrics for this track'), findsOneWidget);
    });

    testWidgets('- reports when the server returns nothing', (tester) async {
      await pumpLyricsView(
        tester,
        state: _stateAt(Duration.zero),
        lyrics: null,
      );

      expect(find.text('No lyrics for this track'), findsOneWidget);
    });
  });
}
