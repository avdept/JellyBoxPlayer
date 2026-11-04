import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/swipeable_artwork.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

typedef _Props = ({List<MediaItem> queue, int? index});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MediaItem item(String id) => MediaItem(id: id, title: id);
  final localQueue = [item('l0'), item('l1'), item('l2')];
  final remoteQueue = [item('r0'), item('r1'), item('r2')];

  Future<ValueNotifier<_Props>> pumpArtwork(
    WidgetTester tester,
    _Props initial,
  ) async {
    final props = ValueNotifier<_Props>(initial);
    addTearDown(props.dispose);
    await tester.pumpWidget(
      createTestApp(
        providerContainer: createProviderContainer(),
        home: Scaffold(
          body: ValueListenableBuilder<_Props>(
            valueListenable: props,
            builder: (_, value, _) => SwipeableArtwork(
              queue: value.queue,
              currentIndex: value.index,
              artworkBuilder: (item) => Center(child: Text(item?.id ?? '')),
              horizontalPadding: 8,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return props;
  }

  PageController controllerOf(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller!;

  testWidgets('lands on the current track after a remote queue refills', (
    tester,
  ) async {
    final props = await pumpArtwork(tester, (queue: localQueue, index: 1));
    final controller = controllerOf(tester);
    expect(controller.page, 1.0);

    props.value = (queue: const [], index: null);
    await tester.pumpAndSettle();
    props.value = (queue: const [], index: 1);
    await tester.pumpAndSettle();
    expect(controller.page, 0.0);

    props.value = (queue: remoteQueue, index: 1);
    await tester.pumpAndSettle();
    expect(controller.page, 1.0);
    expect(find.text('r1'), findsOneWidget);
  });

  testWidgets('lands on the current track when the queue arrives after the '
      'index', (tester) async {
    final props = await pumpArtwork(tester, (queue: const [], index: 2));
    final controller = controllerOf(tester);

    props.value = (queue: remoteQueue, index: 2);
    await tester.pumpAndSettle();
    expect(controller.page, 2.0);
  });

  testWidgets('follows a track change that arrives mid-drag', (tester) async {
    final props = await pumpArtwork(tester, (queue: localQueue, index: 0));
    final controller = controllerOf(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    props.value = (queue: localQueue, index: 1);
    await tester.pump();
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.page, 1.0);
  });

  testWidgets('disposes cleanly while a move waits for a drag to settle', (
    tester,
  ) async {
    final props = await pumpArtwork(tester, (queue: localQueue, index: 0));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    props.value = (queue: localQueue, index: 2);
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await gesture.up();
    expect(tester.takeException(), isNull);
  });
}
