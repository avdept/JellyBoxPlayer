import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
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

class FakeUserCredentials extends Fake implements UserCredentials {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthNotifier mockAuthNotifier;
  late MockServerProbeService mockProbeService;

  final faker = Faker.instance;

  Widget getWidgetUT() => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        authProvider.overrideWith(() => mockAuthNotifier),
        serverProbeServiceProvider.overrideWithValue(mockProbeService),
      ],
    ),
    home: const LoginPage(),
  );

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
    when(mockAuthNotifier.build).thenAnswer((_) async => true);
    when(() => mockAuthNotifier.login(any())).thenAnswer((_) async => null);
    when(() => mockProbeService.probe(any())).thenAnswer((_) async => null);
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
        when(() => mockProbeService.probe(any())).thenAnswer(
          (_) async => const PublicSystemInfoDTO(
            id: 'server-id',
            serverName: 'Living Room',
            version: '10.9.11',
          ),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'http://jelly.local');

        verify(() => mockProbeService.probe('http://jelly.local')).called(1);
        expect(find.text('Discovered: Living Room'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets(
      '- normalizes the url before probing it',
      (widgetTester) async {
        when(() => mockProbeService.probe(any())).thenAnswer(
          (_) async => const PublicSystemInfoDTO(
            id: 'server-id',
            serverName: 'Living Room',
            version: '10.9.11',
          ),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'jelly.local:8096');

        verify(
          () => mockProbeService.probe('http://jelly.local:8096'),
        ).called(1);
      },
    );

    testWidgets(
      '- shows nothing when the server is not a Jellyfin server',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'http://nope.local');

        verify(() => mockProbeService.probe('http://nope.local')).called(1);
        expect(find.textContaining('Discovered:'), findsNothing);
        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );

    testWidgets(
      '- clears the discovered server when the url is edited',
      (widgetTester) async {
        when(() => mockProbeService.probe(any())).thenAnswer(
          (_) async => const PublicSystemInfoDTO(
            id: 'server-id',
            serverName: 'Living Room',
            version: '10.9.11',
          ),
        );

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await enterServerUrlAndUnfocus(widgetTester, 'http://jelly.local');
        expect(find.text('Discovered: Living Room'), findsOneWidget);

        await widgetTester.enterText(
          find.widgetWithText(LabeledTextField, 'Server URL'),
          'http://jelly.local/other',
        );
        await widgetTester.pumpAndSettle();

        expect(find.text('Discovered: Living Room'), findsNothing);
        expect(find.byIcon(Icons.check_circle), findsNothing);
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
