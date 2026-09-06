import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/providers/cast_failure_provider.dart';

void main() {
  test('- names the device, the fallback, and the submitted report', () {
    const failure = CastFailure(deviceName: 'LSX II LT', reported: true);

    expect(failure.message, contains('Unable to cast to LSX II LT'));
    expect(failure.message, contains('switched back to this device'));
    expect(failure.message, contains('error report was submitted'));
    expect(failure.message, contains('Alex'));
  });

  test('- claims no report when diagnostics are off', () {
    const failure = CastFailure(deviceName: 'Kitchen Ceiling', reported: false);

    expect(
      failure.message,
      'Unable to cast to Kitchen Ceiling — switched back to this device.',
    );
  });

  test('- holds the latest failure until it is cleared', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(castFailureProvider), isNull);

    container.read(castFailureProvider.notifier).report('LSX II LT');
    expect(container.read(castFailureProvider)?.deviceName, 'LSX II LT');

    container.read(castFailureProvider.notifier).clear();
    expect(container.read(castFailureProvider), isNull);
  });
}
