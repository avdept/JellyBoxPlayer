import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/resources/entypo_icons.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/widgets/position_slider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class FakePlaybackNotifier extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  FakePlaybackNotifier(super.state);
}

class MockMediaServerClient extends Mock implements MediaServerClient {}

const _song = LibraryItem(
  id: 'song-1',
  name: 'Roads',
  kind: ItemKind.song,
  albumArtist: 'Portishead',
  hasLyrics: true,
);

final _state = PlaybackState(
  album: null,
  songs: const [_song],
  status: PlaybackStatus.playing,
  position: const Duration(seconds: 30),
  cacheProgress: const Duration(seconds: 45),
  currentMediaIndex: 0,
);

void main() {
  setUpAll(() => registerFallbackValue(_song));

  late FakePlaybackNotifier playback;
  late MockMediaServerClient client;

  setUp(() {
    playback = FakePlaybackNotifier(_state);
    client = MockMediaServerClient();
    when(
      () => client.setFavorite(any(), favorite: any(named: 'favorite')),
    ).thenAnswer((_) async {});
    when(() => playback.updateSong(any())).thenReturn(null);
    when(playback.prev).thenAnswer((_) async {});
    when(playback.next).thenAnswer((_) async {});
    when(playback.playPause).thenAnswer((_) async {});
  });

  Future<void> pumpLandscapePlayer(
    WidgetTester tester, {
    Size size = const Size(1688, 780),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final container = createProviderContainer(
      overrides: [
        playbackProvider.overrideWith((_) => playback),
        mediaServerClientProvider.overrideWith((_) => client),
        lyricsProvider(_song.id).overrideWith((_) async => null),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: Themes.red,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [child!, const LandscapePlayer()],
          ),
          home: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LandscapePlayerScope', () {
    Future<List<List<String>>> pumpScope(
      WidgetTester tester, {
      required PlaybackState state,
    }) async {
      final requested = <List<String>>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          requested.add((call.arguments as List<Object?>).cast<String>());
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      tester.view
        ..physicalSize = const Size(780, 1688)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final container = createProviderContainer(
        overrides: [
          playbackProvider.overrideWith((_) => FakePlaybackNotifier(state)),
          mediaServerClientProvider.overrideWith((_) => client),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: Themes.red,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => LandscapePlayerScope(child: child!),
            home: const Scaffold(body: Text('library page')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return requested;
    }

    testWidgets('- keeps the phone in portrait while the queue is empty', (
      tester,
    ) async {
      final requested = await pumpScope(tester, state: PlaybackState.initial());

      expect(requested.last, ['DeviceOrientation.portraitUp']);
      expect(find.byType(LandscapePlayer), findsNothing);
    });

    testWidgets('- opens landscape up once a track is loaded', (tester) async {
      final requested = await pumpScope(tester, state: _state);

      expect(requested.last, contains('DeviceOrientation.landscapeLeft'));
      expect(requested.last, contains('DeviceOrientation.landscapeRight'));
    });
  });

  group('LandscapePlayer', () {
    testWidgets('- renders above the navigator without an Overlay ancestor', (
      tester,
    ) async {
      await pumpLandscapePlayer(tester);

      expect(find.text('Roads'), findsOneWidget);
      expect(find.text('Portishead'), findsOneWidget);
      expect(find.byType(PositionSlider), findsOneWidget);
      expect(find.byType(PlayPauseButton), findsOneWidget);
    });

    testWidgets('- shows elapsed and remaining time around the progress bar', (
      tester,
    ) async {
      await pumpLandscapePlayer(tester);

      expect(find.byType(PositionLabels), findsOneWidget);
      expect(find.text('0:30'), findsOneWidget);
    });

    testWidgets('- favourites the current song from the heart button', (
      tester,
    ) async {
      await pumpLandscapePlayer(tester);

      await tester.tap(find.byIcon(CupertinoIcons.heart));
      await tester.pumpAndSettle();

      verify(() => client.setFavorite('song-1', favorite: true)).called(1);
      verify(
        () => playback.updateSong(
          _song.copyWith(
            userData: _song.userData.copyWith(isFavorite: true),
          ),
        ),
      ).called(1);
    });

    testWidgets('- flips the middle section to the queue and back', (
      tester,
    ) async {
      await pumpLandscapePlayer(tester);
      expect(find.byType(NowPlayingQueueView), findsNothing);

      await tester.tap(find.byIcon(Icons.queue_music));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingQueueView), findsOneWidget);
      expect(find.byType(PositionSlider), findsNothing);
      expect(find.byIcon(CupertinoIcons.heart), findsNothing);
      expect(find.byIcon(Icons.lyrics_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.queue_music));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingQueueView), findsNothing);
      expect(find.byType(PositionSlider), findsOneWidget);
    });

    testWidgets('- flips the middle section to the lyrics', (tester) async {
      await pumpLandscapePlayer(tester);

      await tester.tap(find.byIcon(Icons.lyrics_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(LyricsView), findsOneWidget);
      expect(find.byType(PositionSlider), findsNothing);

      final buttons = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byIcon(Icons.queue_music),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(buttons.opacity, lessThan(1));
    });

    testWidgets('- lays out without overflow on a small phone', (
      tester,
    ) async {
      await pumpLandscapePlayer(tester, size: const Size(1280, 720));

      expect(find.text('Roads'), findsOneWidget);
      expect(find.byType(PositionSlider), findsOneWidget);

      await tester.tap(find.byIcon(Icons.queue_music));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingQueueView), findsOneWidget);
    });

    testWidgets('- drives the playback notifier from the transport buttons', (
      tester,
    ) async {
      await pumpLandscapePlayer(tester);

      await tester.tap(find.byIcon(Entypo.fast_forward));
      await tester.tap(find.byIcon(Entypo.fast_backward));
      await tester.tap(find.byType(PlayPauseButton));
      await tester.pump();

      verify(playback.next).called(1);
      verify(playback.prev).called(1);
      verify(playback.playPause).called(1);
    });
  });
}
