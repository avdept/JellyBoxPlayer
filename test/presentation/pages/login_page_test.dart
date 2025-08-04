import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/presentation/pages/login_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockAuthNotifier extends StateNotifier<AsyncValue<bool?>>
    with Mock
    implements AuthNotifier {
  MockAuthNotifier(super.state);
}

class FakeUserCredentials extends Fake implements UserCredentials {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthNotifier mockAuthNotifier;

  final faker = Faker.instance;

  Widget getWidgetUT() => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => mockAuthNotifier),
      ],
    ),
    home: const LoginPage(),
  );

  setUpAll(() {
    registerFallbackValue(FakeUserCredentials());
  });

  setUp(() {
    mockAuthNotifier = MockAuthNotifier(const AsyncData(true));
    when(() => mockAuthNotifier.login(any())).thenAnswer((_) async => null);
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
        await widgetTester.tap(find.widgetWithText(ShadowedButton, 'Sign in'));
        await widgetTester.pumpAndSettle();
        verify(() => mockAuthNotifier.login(credentials)).called(1);
      },
    );
  });
}
