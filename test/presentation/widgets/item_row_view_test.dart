import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class _FakePlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _FakePlayback(super.state);

  final calls = <String>[];

  @override
  Future<void> pause() async {
    calls.add('pause');
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    state = state.copyWith(status: PlaybackStatus.playing);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) => createTestApp(
    providerContainer: createProviderContainer(),
    home: Center(child: child),
  );

  const album = LibraryItem(
    id: 'album-1',
    name: 'Raised on Whipped Cream',
    kind: ItemKind.album,
    albumArtist: 'Killradio',
    productionYear: 2004,
  );

  testWidgets('- shows the name and, for an album, the artist', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const ItemRowView(item: album)));

    expect(find.text('Raised on Whipped Cream'), findsOneWidget);
    expect(find.text('Killradio'), findsOneWidget);
    expect(find.textContaining('2004'), findsNothing);
  });

  testWidgets('- shows no subtitle for an album with no artist', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ItemRowView(
          item: LibraryItem(
            id: 'album-2',
            name: 'Untitled',
            kind: ItemKind.album,
          ),
        ),
      ),
    );

    expect(
      tester.widget<SimpleListTile>(find.byType(SimpleListTile)).subtitle,
      isNull,
    );
  });

  testWidgets('- shows no subtitle for a playlist', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ItemRowView(
          item: LibraryItem(
            id: 'playlist-1',
            name: 'Road trip',
            kind: ItemKind.playlist,
          ),
        ),
      ),
    );

    expect(find.text('Road trip'), findsOneWidget);
    expect(
      tester.widget<SimpleListTile>(find.byType(SimpleListTile)).subtitle,
      isNull,
    );
  });

  testWidgets('- reports the tapped item, like a card does', (tester) async {
    LibraryItem? tapped;
    await tester.pumpWidget(
      wrap(ItemRowView(item: album, onTap: (item) => tapped = item)),
    );

    await tester.tap(find.text('Raised on Whipped Cream'));
    await tester.pump();

    expect(tapped, album);
  });

  testWidgets('- offers play only when a handler is given', (tester) async {
    await tester.pumpWidget(wrap(const ItemRowView(item: album)));
    expect(find.byType(CirclePlayButton), findsNothing);

    LibraryItem? played;
    await tester.pumpWidget(
      wrap(
        ItemRowView(
          item: album,
          onPlayPressed: (item) async => played = item,
        ),
      ),
    );
    expect(find.byType(CirclePlayButton), findsOneWidget);

    await tester.tap(find.byType(CirclePlayButton));
    await tester.pump();

    expect(played, album);
  });

  testWidgets('- uses the same blue play button as the cards', (tester) async {
    await tester.pumpWidget(
      wrap(ItemRowView(item: album, onPlayPressed: (_) async {})),
    );

    final button = tester.widget<MaterialButton>(
      find.descendant(
        of: find.byType(CirclePlayButton),
        matching: find.byType(MaterialButton),
      ),
    );

    expect(button.color, const Color(0xFF0066FF));
    expect(button.shape, const CircleBorder());
    expect(find.byIcon(Icons.play_arrow_outlined), findsOneWidget);
  });

  testWidgets('- shows a spinner while play is in flight', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      wrap(ItemRowView(item: album, onPlayPressed: (_) => completer.future)),
    );

    await tester.tap(find.byType(CirclePlayButton));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  group('hover', () {
    Color? tileColor(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(SimpleListTile),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (container.decoration as BoxDecoration?)?.color;
    }

    Future<TestGesture> hoverOver(WidgetTester tester, Finder finder) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(finder));
      await tester.pumpAndSettle();
      return gesture;
    }

    testWidgets('- highlights the row while the pointer is over it', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(ItemRowView(item: album, onTap: (_) {})));
      final tile = find.byType(SimpleListTile);
      expect(tileColor(tester), Colors.transparent);

      final gesture = await hoverOver(tester, tile);
      expect(tileColor(tester), isNot(Colors.transparent));

      await gesture.moveTo(const Offset(-100, -100));
      await tester.pumpAndSettle();
      expect(tileColor(tester), Colors.transparent);
    });

    testWidgets('- does not highlight a row that cannot be tapped', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ItemRowView(item: album)));

      await hoverOver(tester, find.byType(SimpleListTile));

      expect(tileColor(tester), Colors.transparent);
    });
  });

  group('the playing set', () {
    late _FakePlayback playback;

    Widget wrapPlaying(Widget child, {required PlaybackStatus status}) {
      playback = _FakePlayback(
        PlaybackState.initial().copyWith(sourceId: album.id, status: status),
      );
      return createTestApp(
        providerContainer: createProviderContainer(
          overrides: [
            playbackProvider.overrideWith((_) => playback),
            itemGlowColorProvider.overrideWith((_, _) async => null),
          ],
        ),
        home: Center(child: child),
      );
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }

    testWidgets('- pauses instead of restarting it', (tester) async {
      var restarts = 0;
      await tester.pumpWidget(
        wrapPlaying(
          ItemRowView(item: album, onPlayPressed: (_) async => restarts++),
          status: PlaybackStatus.playing,
        ),
      );
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byType(CirclePlayButton));
      await tester.pump();

      expect(playback.calls, ['pause']);
      expect(restarts, 0);
      expect(find.byIcon(Icons.play_arrow_outlined), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('- resumes it where it was paused', (tester) async {
      var restarts = 0;
      await tester.pumpWidget(
        wrapPlaying(
          ItemRowView(item: album, onPlayPressed: (_) async => restarts++),
          status: PlaybackStatus.paused,
        ),
      );

      await tester.tap(find.byType(CirclePlayButton));
      await tester.pump();

      expect(playback.calls, ['resume']);
      expect(restarts, 0);
      await unmount(tester);
    });

    testWidgets('- plays another item from the start', (tester) async {
      LibraryItem? played;
      const other = LibraryItem(
        id: 'album-2',
        name: 'Other',
        kind: ItemKind.album,
      );
      await tester.pumpWidget(
        wrapPlaying(
          ItemRowView(
            item: other,
            onPlayPressed: (item) async => played = item,
          ),
          status: PlaybackStatus.playing,
        ),
      );
      expect(find.byIcon(Icons.play_arrow_outlined), findsOneWidget);

      await tester.tap(find.byType(CirclePlayButton));
      await tester.pump();

      expect(played, other);
      expect(playback.calls, isEmpty);
      await unmount(tester);
    });
  });
}
