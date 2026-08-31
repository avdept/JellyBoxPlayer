import 'dart:async';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/server_discovery_protocol.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_discovery_service.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/discovered_servers_provider.dart';
import 'package:jplayer/src/presentation/pages/login_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockAuthNotifier extends AsyncNotifier<bool?>
    with Mock
    implements AuthNotifier {}

class MockServerProbeService extends Mock implements ServerProbeService {}

class MockServerDiscoveryService extends Mock
    implements ServerDiscoveryService {}

class FakeUserCredentials extends Fake implements UserCredentials {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthNotifier mockAuthNotifier;
  late MockServerProbeService mockProbeService;
  late MockServerDiscoveryService mockDiscoveryService;

  final faker = Faker.instance;

  Widget getWidgetUT() => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        authProvider.overrideWith(() => mockAuthNotifier),
        serverProbeServiceProvider.overrideWithValue(mockProbeService),
        serverDiscoveryServiceProvider.overrideWithValue(mockDiscoveryService),
      ],
    ),
    home: const LoginPage(),
  );

  ServerProbeResult discoveryResult(
    String serverUrl, {
    ServerType serverType = ServerType.jellyfin,
    String serverName = 'Living Room',
  }) => ServerProbeResult(
    serverUrl: serverUrl,
    serverType: serverType,
    info: PublicSystemInfoDTO(
      id: 'server-id',
      serverName: serverName,
      version: '10.9.11',
    ),
  );

  void announcesServers(List<ServerAnnouncement> announcements) {
    when(
      () => mockDiscoveryService.discover(),
    ).thenAnswer((_) => Stream.fromIterable(announcements));
  }

  StreamController<ServerAnnouncement> announcesSlowly() {
    final controller = StreamController<ServerAnnouncement>();
    addTearDown(() => controller.close().ignore());
    when(
      () => mockDiscoveryService.discover(),
    ).thenAnswer((_) => controller.stream);
    return controller;
  }

  void findsServerAt(
    String url, {
    String name = 'Living Room',
    ServerType type = ServerType.jellyfin,
  }) {
    when(() => mockProbeService.discover(url)).thenAnswer(
      (_) async => discoveryResult(url, serverType: type, serverName: name),
    );
  }

  ServerAnnouncement announcement({
    required String address,
    ServerType serverType = ServerType.jellyfin,
  }) => ServerAnnouncement(
    id: address,
    address: address,
    serverType: serverType,
    name: 'Announced',
  );

  String serverUrlFieldText(WidgetTester widgetTester) => widgetTester
      .widget<EditableText>(find.byType(EditableText).first)
      .controller
      .text;

  Future<void> enterServerUrlAndUnfocus(
    WidgetTester widgetTester,
    String url,
  ) async {
    await widgetTester.enterText(
      find.widgetWithText(LabeledTextField, 'Server URL'),
      url,
    );
    await widgetTester.pump();
    await widgetTester.tap(find.widgetWithText(LabeledTextField, 'Login'));
    await widgetTester.pumpAndSettle();
  }

  setUpAll(() {
    registerFallbackValue(FakeUserCredentials());
  });

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
    mockProbeService = MockServerProbeService();
    mockDiscoveryService = MockServerDiscoveryService();
    announcesServers(const []);
    when(mockAuthNotifier.build).thenAnswer((_) async => true);
    when(() => mockAuthNotifier.login(any())).thenAnswer((_) async => null);
    when(() => mockProbeService.discover(any())).thenAnswer((_) async => null);
  });

  group('LoginPage', () {
    testWidgets(
      '- renders correctly',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        expect(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(LabeledTextField, 'Login'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(LabeledTextField, 'Password'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ShadowedButton, 'Sign in'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- can log in with user credentials',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final credentials = UserCredentials(
          username: faker.internet.email(),
          pw: faker.hacker.noun(),
          serverUrl: faker.internet.url(),
        );
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          credentials.serverUrl,
        );
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Login'),
          credentials.username,
        );
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Password'),
          credentials.pw,
        );
        final signInFinder = find.widgetWithText(ShadowedButton, 'Sign in');
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();
        verify(() => mockAuthNotifier.login(credentials)).called(1);
      },
    );

    testWidgets(
      '- shows the discovered server when the url field loses focus',
      (widgetTester) async {
        when(() => mockProbeService.discover(any())).thenAnswer(
          (_) async => discoveryResult('http://jelly.local'),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'http://jelly.local');

        verify(() => mockProbeService.discover('http://jelly.local')).called(1);
        expect(find.text('Discovered: Jellyfin server'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets(
      '- names Emby when an Emby server is discovered',
      (widgetTester) async {
        when(() => mockProbeService.discover(any())).thenAnswer(
          (_) async => discoveryResult(
            'http://emby.local:8096',
            serverType: ServerType.emby,
          ),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'http://emby.local:8096');

        expect(find.text('Discovered: Emby server'), findsOneWidget);
        expect(find.text('Discovered: Jellyfin server'), findsNothing);
      },
    );

    testWidgets(
      '- discovers a server entered without a scheme',
      (widgetTester) async {
        when(() => mockProbeService.discover(any())).thenAnswer(
          (_) async => discoveryResult('http://jelly.local:8096'),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'jelly.local:8096');

        verify(() => mockProbeService.discover('jelly.local:8096')).called(1);
        expect(find.text('Discovered: Jellyfin server'), findsOneWidget);
      },
    );

    testWidgets(
      '- signs in with the scheme discovery resolved',
      (widgetTester) async {
        when(() => mockProbeService.discover(any())).thenAnswer(
          (_) async => discoveryResult('https://jelly.example.com'),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'jelly.example.com');
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Login'),
          'alex',
        );
        final signInFinder = find.widgetWithText(ShadowedButton, 'Sign in');
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();

        final credentials =
            verify(() => mockAuthNotifier.login(captureAny())).captured.single
                as UserCredentials;
        expect(credentials.serverUrl, 'https://jelly.example.com');
      },
    );

    testWidgets(
      '- falls back to http when discovery finds nothing',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'jelly.local:8096');
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Login'),
          'alex',
        );
        final signInFinder = find.widgetWithText(ShadowedButton, 'Sign in');
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();

        final credentials =
            verify(() => mockAuthNotifier.login(captureAny())).captured.single
                as UserCredentials;
        expect(credentials.serverUrl, 'http://jelly.local:8096');
      },
    );

    testWidgets(
      '- shows nothing when the server is not a Jellyfin server',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'http://nope.local');

        verify(() => mockProbeService.discover('http://nope.local')).called(1);
        expect(find.textContaining('Discovered:'), findsNothing);
        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );

    testWidgets(
      '- clears the discovered server when the url is edited',
      (widgetTester) async {
        when(() => mockProbeService.discover(any())).thenAnswer(
          (_) async => discoveryResult('http://jelly.local'),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'http://jelly.local');
        expect(find.text('Discovered: Jellyfin server'), findsOneWidget);

        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          'http://jelly.local/other',
        );
        await widgetTester.pumpAndSettle();

        expect(find.text('Discovered: Jellyfin server'), findsNothing);
        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );

    testWidgets(
      '- shows the auto discovering placeholder while scanning',
      (widgetTester) async {
        announcesSlowly();

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);

        expect(
          find.text(ServerUrlField.discoveringPlaceholder),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      '- drops discovery for good once the user types',
      (widgetTester) async {
        final discovery = announcesSlowly();
        findsServerAt('http://192.168.1.10:8096');

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          'my.server',
        );
        await widgetTester.pump();

        expect(find.text(ServerUrlField.discoveringPlaceholder), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        discovery.add(announcement(address: 'http://192.168.1.10:8096'));
        await widgetTester.pumpAndSettle();

        expect(find.text('Living Room'), findsNothing);
        expect(serverUrlFieldText(widgetTester), 'my.server');
      },
    );

    testWidgets(
      '- replaces the field with the server that was found',
      (widgetTester) async {
        announcesServers([announcement(address: 'http://192.168.1.10:8096')]);
        findsServerAt('http://192.168.1.10:8096');

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pumpAndSettle();

        expect(find.text('Living Room'), findsOneWidget);
        expect(find.text('http://192.168.1.10:8096'), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      },
    );

    testWidgets(
      '- the pencil turns the found server into an editable field',
      (widgetTester) async {
        announcesServers([announcement(address: 'http://192.168.1.10:8096')]);
        findsServerAt('http://192.168.1.10:8096');

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.byIcon(Icons.edit));
        await widgetTester.pumpAndSettle();

        expect(find.byIcon(Icons.edit), findsNothing);
        expect(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          findsOneWidget,
        );
        expect(serverUrlFieldText(widgetTester), 'http://192.168.1.10:8096');
      },
    );

    testWidgets(
      '- offers a dropdown when more than one server is found',
      (widgetTester) async {
        announcesServers([
          announcement(address: 'http://192.168.1.10:8096'),
          announcement(address: 'http://192.168.1.11:8096'),
        ]);
        findsServerAt('http://192.168.1.10:8096');
        findsServerAt(
          'http://192.168.1.11:8096',
          name: 'Basement',
          type: ServerType.emby,
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pumpAndSettle();

        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
        expect(find.text('Basement'), findsNothing);

        await widgetTester.tap(find.text('Living Room'));
        await widgetTester.pumpAndSettle();
        expect(find.text('Basement'), findsOneWidget);

        await widgetTester.tap(find.text('Basement'));
        await widgetTester.pumpAndSettle();

        expect(find.text('Basement'), findsOneWidget);
        expect(find.text('http://192.168.1.11:8096'), findsOneWidget);
      },
    );

    testWidgets(
      '- keeps the spinner while more servers may still arrive',
      (widgetTester) async {
        final discovery = announcesSlowly();
        findsServerAt('http://192.168.1.10:8096');

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        discovery.add(announcement(address: 'http://192.168.1.10:8096'));
        await widgetTester.pump();
        await widgetTester.pump(const Duration(milliseconds: 50));

        expect(find.text('Living Room'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await discovery.close();
        await widgetTester.pump(const Duration(milliseconds: 100));

        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '- squares off the bottom of the field while the dropdown is open',
      (widgetTester) async {
        announcesServers([
          announcement(address: 'http://192.168.1.10:8096'),
          announcement(address: 'http://192.168.1.11:8096'),
        ]);
        findsServerAt('http://192.168.1.10:8096');
        findsServerAt('http://192.168.1.11:8096', name: 'Basement');

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pumpAndSettle();

        BorderRadius surfaceRadius() =>
            widgetTester
                    .widget<Material>(find.byKey(ServerUrlField.surfaceKey))
                    .borderRadius!
                as BorderRadius;

        expect(surfaceRadius().bottomLeft.x, ServerUrlField.radius);

        await widgetTester.tap(find.text('Living Room'));
        await widgetTester.pumpAndSettle();

        expect(surfaceRadius().bottomLeft.x, 0);
        expect(surfaceRadius().topLeft.x, ServerUrlField.radius);

        await widgetTester.tap(find.text('Basement'));
        await widgetTester.pumpAndSettle();

        expect(surfaceRadius().bottomLeft.x, ServerUrlField.radius);
      },
    );

    testWidgets(
      '- keeps the spinner square',
      (widgetTester) async {
        announcesSlowly();

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);

        final size = widgetTester.getSize(
          find.byType(CircularProgressIndicator),
        );
        expect(size.width, size.height);
      },
    );

    testWidgets(
      '- highlights the dropdown row under the pointer',
      (widgetTester) async {
        announcesServers([
          announcement(address: 'http://192.168.1.10:8096'),
          announcement(address: 'http://192.168.1.11:8096'),
        ]);
        findsServerAt('http://192.168.1.10:8096');
        findsServerAt('http://192.168.1.11:8096', name: 'Basement');

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text('Living Room'));
        await widgetTester.pumpAndSettle();

        Color? rowColor() => widgetTester
            .widget<Container>(
              find
                  .ancestor(
                    of: find.text('Basement'),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .color;

        expect(rowColor(), Colors.transparent);

        final pointer = await widgetTester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await pointer.addPointer(location: Offset.zero);
        addTearDown(pointer.removePointer);
        await pointer.moveTo(widgetTester.getCenter(find.text('Basement')));
        await widgetTester.pumpAndSettle();

        expect(rowColor(), isNot(Colors.transparent));
      },
    );

    testWidgets(
      '- opens the dropdown at the full width of the field',
      (widgetTester) async {
        announcesServers([
          announcement(address: 'http://192.168.1.10:8096'),
          announcement(address: 'http://192.168.1.11:8096'),
        ]);
        findsServerAt('http://192.168.1.10:8096');
        findsServerAt('http://192.168.1.11:8096', name: 'Basement');

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pumpAndSettle();
        final fieldWidth = widgetTester
            .getSize(find.byType(ServerUrlField))
            .width;

        await widgetTester.tap(find.text('Living Room'));
        await widgetTester.pumpAndSettle();

        final itemWidth = widgetTester
            .getSize(find.byType(PopupMenuItem<DiscoveredServer>).first)
            .width;
        expect(itemWidth, fieldWidth);
      },
    );

    testWidgets(
      '- signs in with the server picked on the network',
      (widgetTester) async {
        when(
          () => mockAuthNotifier.login(any(), serverType: ServerType.emby),
        ).thenAnswer((_) async => null);
        announcesServers([
          announcement(
            address: 'http://192.168.1.11:8096',
            serverType: ServerType.emby,
          ),
        ]);
        when(
          () => mockProbeService.discover('http://192.168.1.11:8096'),
        ).thenAnswer(
          (_) async => discoveryResult(
            'http://192.168.1.11:8096/emby',
            serverType: ServerType.emby,
          ),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pumpAndSettle();
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Login'),
          'alex',
        );
        final signInFinder = find.widgetWithText(ShadowedButton, 'Sign in');
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();

        final credentials =
            verify(
                  () => mockAuthNotifier.login(
                    captureAny(),
                    serverType: ServerType.emby,
                  ),
                ).captured.single
                as UserCredentials;
        expect(credentials.serverUrl, 'http://192.168.1.11:8096/emby');
      },
    );

    testWidgets(
      '- shows the error returned by the login attempt',
      (widgetTester) async {
        when(() => mockAuthNotifier.login(any())).thenAnswer(
          (_) async => AuthNotifier.invalidCredentialsError,
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          'http://jelly.local',
        );
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Login'),
          'alex',
        );
        final signInFinder = find.widgetWithText(ShadowedButton, 'Sign in');
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();

        expect(
          find.text(AuthNotifier.invalidCredentialsError),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- requires a server url and a login',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final signInFinder = find.widgetWithText(ShadowedButton, 'Sign in');
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();

        expect(find.text('Server URL and login are required'), findsOneWidget);
        verifyNever(() => mockAuthNotifier.login(any()));
      },
    );

    testWidgets(
      '- clears a previous error on the next attempt',
      (widgetTester) async {
        when(() => mockAuthNotifier.login(any())).thenAnswer(
          (_) async => AuthNotifier.serverUnreachableError,
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final signInFinder = find.widgetWithText(ShadowedButton, 'Sign in');
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();
        expect(find.text('Server URL and login are required'), findsOneWidget);

        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          'http://jelly.local',
        );
        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Login'),
          'alex',
        );
        await widgetTester.ensureVisible(signInFinder);
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(signInFinder);
        await widgetTester.pumpAndSettle();

        expect(find.text('Server URL and login are required'), findsNothing);
        expect(
          find.text(AuthNotifier.serverUnreachableError),
          findsOneWidget,
        );
      },
    );
  });
}
