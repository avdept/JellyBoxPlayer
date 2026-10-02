import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/cast/cast_discovery.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscovery extends Mock
    implements GoogleCastDiscoveryManagerPlatformInterface {}

void main() {
  late _MockDiscovery manager;
  late CastDiscovery discovery;

  setUp(() {
    manager = _MockDiscovery();
    when(() => manager.startDiscovery()).thenAnswer((_) async {});
    when(() => manager.stopDiscovery()).thenAnswer((_) async {});
    discovery = CastDiscovery.of(manager);
  });

  test('keeps scanning while anyone still holds it', () async {
    await discovery.hold();
    await discovery.hold();
    verify(() => manager.startDiscovery()).called(1);

    await discovery.release();
    verifyNever(() => manager.stopDiscovery());

    await discovery.release();
    verify(() => manager.stopDiscovery()).called(1);
  });

  test('ignores a release nobody asked for', () async {
    await discovery.release();
    await discovery.hold();
    await discovery.release();

    verify(() => manager.stopDiscovery()).called(1);
  });

  test('shares one hold count per discovery manager', () async {
    await CastDiscovery.of(manager).hold();
    await CastDiscovery.of(manager).hold();
    await discovery.release();

    verify(() => manager.startDiscovery()).called(1);
    verifyNever(() => manager.stopDiscovery());
  });
}
