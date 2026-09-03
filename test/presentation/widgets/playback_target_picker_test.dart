import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';
import 'package:jplayer/src/presentation/widgets/playback_target_picker.dart';

class _FakeRenderersNotifier extends UpnpRenderersNotifier {
  _FakeRenderersNotifier(List<UpnpRenderer> renderers)
    : super(UpnpControlPoint(dio: Dio())) {
    state = UpnpDiscoveryState(renderers: renderers);
  }

  @override
  Future<void> refresh({Duration timeout = const Duration(seconds: 4)}) async {}
}

class _FakeTarget implements PlaybackTarget {
  _FakeTarget(this.id, this.name, this.kind);

  @override
  final String id;
  @override
  final String name;
  @override
  final PlaybackTargetKind kind;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  UpnpRenderer rendererNamed(
    String name, {
    String? model,
    String? type,
    String host = '10.0.0.9',
    String? roomName,
  }) {
    final soap = UpnpSoapClient(dio: Dio());
    final control = Uri.parse('http://$host:9197/ctl');
    return UpnpRenderer(
      device: UpnpDevice(
        udn: 'uuid:$name-$host',
        friendlyName: name,
        deviceType: type ?? 'urn:schemas-upnp-org:device:MediaRenderer:1',
        location: Uri.parse('http://$host:9197/desc.xml'),
        services: const [],
        modelName: model,
        roomName: roomName,
      ),
      avTransport: AvTransport(soap: soap, controlUrl: control),
      sinkMimeTypes: const {'audio/mpeg'},
    );
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    required List<UpnpRenderer> renderers,
    PlaybackTarget? activeTarget,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upnpRenderersProvider.overrideWith(
            (ref) => _FakeRenderersNotifier(renderers),
          ),
          if (activeTarget != null)
            playbackTargetProvider.overrideWith(
              (ref) => PlaybackTargetNotifier(activeTarget),
            ),
        ],
        child: MaterialApp(
          home: Scaffold(body: PlaybackTargetMenu(onDone: () {})),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('- lists this device and every renderer in one list', (
    tester,
  ) async {
    await pumpPicker(
      tester,
      renderers: [
        rendererNamed('[TV1476] ROOM 7005', model: 'HG55BU800EUXEN'),
        rendererNamed('Kitchen', model: 'Sonos One'),
      ],
    );

    expect(find.text('Play on'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('[TV1476] ROOM 7005'), findsOneWidget);
    expect(find.text('10.0.0.9 · HG55BU800EUXEN'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('No DLNA devices found on this network.'), findsNothing);
  });

  testWidgets('- gives each entry its own icon', (tester) async {
    await pumpPicker(
      tester,
      renderers: [
        rendererNamed('[TV1476] ROOM 7005', model: 'HG55BU800EUXEN'),
        rendererNamed('Kitchen', model: 'Sonos One'),
        rendererNamed('Hi-Fi', model: 'Denon AVR-X2700H'),
      ],
    );

    expect(find.byIcon(Icons.tv), findsOneWidget);
    expect(find.byIcon(Icons.speaker), findsOneWidget);
    expect(find.byIcon(Icons.settings_input_component), findsOneWidget);
    expect(
      find.byIcon(Icons.laptop_mac).evaluate().length +
          find.byIcon(Icons.phone_iphone).evaluate().length +
          find.byIcon(Icons.smartphone).evaluate().length,
      1,
    );
  });

  testWidgets('- ticks the active renderer, not this device', (tester) async {
    final renderer = rendererNamed('Kitchen', model: 'Sonos One');
    await pumpPicker(
      tester,
      renderers: [renderer],
      activeTarget: _FakeTarget(
        renderer.id,
        renderer.name,
        PlaybackTargetKind.upnp,
      ),
    );

    final ticked = tester.widget<ListTile>(
      find.ancestor(of: find.text('Kitchen'), matching: find.byType(ListTile)),
    );
    expect(ticked.trailing, isA<Icon>());

    final local = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('This device'),
        matching: find.byType(ListTile),
      ),
    );
    expect(local.trailing, isNull);
  });

  testWidgets('- switches the target when a renderer is tapped', (
    tester,
  ) async {
    final renderer = rendererNamed('Kitchen', model: 'Sonos One');
    final container = ProviderContainer(
      overrides: [
        upnpRenderersProvider.overrideWith(
          (ref) => _FakeRenderersNotifier([renderer]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: PlaybackTargetMenu(onDone: () {})),
        ),
      ),
    );
    await tester.pump();

    expect(
      container.read(playbackTargetProvider).kind,
      PlaybackTargetKind.local,
    );

    await tester.tap(find.text('Kitchen'));
    await tester.pump();

    final target = container.read(playbackTargetProvider);
    expect(target.kind, PlaybackTargetKind.upnp);
    expect(target.id, renderer.id);
    expect(target.name, 'Kitchen');
  });

  testWidgets('- tells three identical speakers apart by address', (
    tester,
  ) async {
    await pumpPicker(
      tester,
      renderers: [
        rendererNamed('Sonos Play:5', model: 'Play:5', host: '10.0.0.11'),
        rendererNamed('Sonos Play:5', model: 'Play:5', host: '10.0.0.12'),
        rendererNamed(
          'Sonos Play:5',
          model: 'Play:5',
          host: '10.0.0.13',
          roomName: 'Office',
        ),
      ],
    );

    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Sonos Play:5'), findsNWidgets(2));
    expect(find.text('10.0.0.11 · Play:5'), findsOneWidget);
    expect(find.text('10.0.0.12 · Play:5'), findsOneWidget);
    expect(find.text('10.0.0.13 · Play:5'), findsOneWidget);
  });

  testWidgets('- says so when nothing was found', (tester) async {
    await pumpPicker(tester, renderers: const []);

    expect(find.text('No DLNA devices found on this network.'), findsOneWidget);
  });

  group('PlaybackTargetButton', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      double? size,
      double iconThemeSize = 26,
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          upnpRenderersProvider.overrideWith(
            (ref) => _FakeRenderersNotifier(const []),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: IconTheme.merge(
              data: IconThemeData(size: iconThemeSize),
              child: PlaybackTargetButton(size: size),
            ),
          ),
        ),
      ),
    );

    testWidgets('- matches the surrounding icon size in a player row', (
      tester,
    ) async {
      await pumpButton(tester);

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.iconSize, 26);
    });

    testWidgets('- carries a beta badge that does not eat the tap', (
      tester,
    ) async {
      await pumpButton(tester);

      expect(find.text('BETA'), findsOneWidget);

      await tester.tapAt(tester.getCenter(find.text('BETA')));
      await tester.pumpAndSettle();

      expect(find.text('Play on'), findsOneWidget);
    });

    testWidgets('- centres the badge text in its pill', (tester) async {
      await pumpButton(tester, iconThemeSize: 24);

      final label = tester.widget<Text>(find.text('BETA'));
      expect(label.style!.fontSize, 9);
      expect(label.textAlign, TextAlign.center);
      expect(label.strutStyle!.forceStrutHeight, isTrue);
      expect(label.strutStyle!.fontSize, 9);

      final pill = find
          .ancestor(of: find.text('BETA'), matching: find.byType(Container))
          .first;
      final pillRect = tester.getRect(pill);
      final textRect = tester.getRect(find.text('BETA'));

      expect(
        textRect.center.dx,
        moreOrLessEquals(pillRect.center.dx, epsilon: 0.75),
      );
      expect(
        textRect.center.dy - pillRect.center.dy,
        moreOrLessEquals(0.9, epsilon: 0.3),
      );
      expect(textRect.height, lessThanOrEqualTo(pillRect.height));
      expect(textRect.width, lessThanOrEqualTo(pillRect.width));
    });

    testWidgets('- opens the menu above the button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            upnpRenderersProvider.overrideWith(
              (ref) => _FakeRenderersNotifier(const []),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: PlaybackTargetButton(size: 44),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Play on'), findsNothing);

      final buttonRect = tester.getRect(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final menuRect = tester.getRect(find.byType(PlaybackTargetMenu));
      expect(find.text('Play on'), findsOneWidget);
      expect(menuRect.bottom, lessThanOrEqualTo(buttonRect.top));
      expect(menuRect.right, moreOrLessEquals(buttonRect.right, epsilon: 1));
      expect(menuRect.left, greaterThanOrEqualTo(0));
    });

    testWidgets('- closes when the target is picked', (tester) async {
      final renderer = rendererNamed('Kitchen', model: 'Sonos One');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            upnpRenderersProvider.overrideWith(
              (ref) => _FakeRenderersNotifier([renderer]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: Center(child: PlaybackTargetButton())),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kitchen'));
      await tester.pumpAndSettle();

      expect(find.text('Play on'), findsNothing);
    });

    testWidgets('- closes on a tap outside', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            upnpRenderersProvider.overrideWith(
              (ref) => _FakeRenderersNotifier(const []),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: PlaybackTargetButton(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Play on'), findsOneWidget);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Play on'), findsNothing);
    });

    testWidgets('- centres the menu on a phone-width screen', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            upnpRenderersProvider.overrideWith(
              (ref) => _FakeRenderersNotifier(const []),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Icon(Icons.shuffle),
                      const Icon(Icons.repeat),
                      PlaybackTargetButton(),
                      const Icon(Icons.favorite),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final buttonRect = tester.getRect(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final menuRect = tester.getRect(find.byType(PlaybackTargetMenu));
      expect(menuRect.left, greaterThanOrEqualTo(0));
      expect(menuRect.right, lessThanOrEqualTo(375));
      expect(menuRect.center.dx, moreOrLessEquals(375 / 2, epsilon: 1));
      expect(menuRect.bottom, lessThanOrEqualTo(buttonRect.top));
    });

    testWidgets('- tints the icon and badge with the colours it is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            upnpRenderersProvider.overrideWith(
              (ref) => _FakeRenderersNotifier(const []),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.dark(
                primary: Colors.blue,
                onPrimary: Colors.blue,
              ),
            ),
            home: const Scaffold(
              body: PlaybackTargetButton(
                color: Colors.white,
                activeColor: Colors.amber,
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.cast));
      expect(icon.color, Colors.white);

      final label = tester.widget<Text>(find.text('BETA'));
      expect(label.style!.color, Colors.white);

      final pill = tester.widget<Container>(
        find
            .ancestor(of: find.text('BETA'), matching: find.byType(Container))
            .first,
      );
      expect(
        (pill.decoration! as BoxDecoration).color,
        Colors.amber,
      );
    });

    testWidgets('- treats an explicit size as the button box, not the glyph', (
      tester,
    ) async {
      await pumpButton(tester, size: 44);

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.iconSize, lessThan(28));
      expect(
        button.constraints,
        BoxConstraints.tightFor(width: 44, height: 44),
      );

      final box = tester.getSize(find.byType(IconButton));
      expect(box.width, lessThanOrEqualTo(48));
      expect(box.height, lessThanOrEqualTo(48));
    });
  });
}
