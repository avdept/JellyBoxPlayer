import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/conductor/conductor_client.dart';
import 'package:jplayer/src/data/conductor/conductor_models.dart';

void main() {
  final received = DateTime(2026, 8, 25, 12, 0, 0);

  HandoffRequest request({
    required int positionMs,
    required int ageMs,
    bool playing = true,
  }) => HandoffRequest(
    doc: SessionDoc(
      itemIds: const ['a', 'b'],
      trackPositionMs: positionMs,
      playing: playing,
    ),
    positionAgeMs: ageMs,
    targetDeviceId: 'phone',
    fromDeviceId: 'desktop',
    isForUs: true,
    receivedAt: received,
  );

  group('positionAt', () {
    test('adds the staleness the server reported', () {
      final result = request(
        positionMs: 90000,
        ageMs: 4000,
      ).positionAt(received);

      expect(result, const Duration(milliseconds: 94000));
    });

    test('adds the time spent handling the handoff locally', () {
      final result = request(
        positionMs: 90000,
        ageMs: 0,
      ).positionAt(received.add(const Duration(milliseconds: 600)));

      expect(result, const Duration(milliseconds: 90600));
    });

    test('adds the startup allowance so audio begins on time', () {
      final result = request(positionMs: 90000, ageMs: 0).positionAt(
        received,
        startupAllowance: const Duration(milliseconds: 250),
      );

      expect(result, const Duration(milliseconds: 90250));
    });

    test('sums every term', () {
      final result = request(positionMs: 90000, ageMs: 8000).positionAt(
        received.add(const Duration(milliseconds: 400)),
        startupAllowance: const Duration(milliseconds: 200),
      );

      expect(result, const Duration(milliseconds: 98600));
    });

    test('does not advance a paused queue', () {
      final result =
          request(
            positionMs: 90000,
            ageMs: 9000,
            playing: false,
          ).positionAt(
            received.add(const Duration(seconds: 3)),
            startupAllowance: const Duration(milliseconds: 500),
          );

      expect(result, const Duration(milliseconds: 90000));
    });

    test('never returns a negative position', () {
      final result = request(
        positionMs: 0,
        ageMs: 0,
      ).positionAt(received.subtract(const Duration(seconds: 5)));

      expect(result, Duration.zero);
    });

    test('a badly stale pull-model handoff still lands correctly', () {
      final result = request(
        positionMs: 60000,
        ageMs: 9800,
      ).positionAt(received.add(const Duration(milliseconds: 300)));

      expect(result, const Duration(milliseconds: 70100));
    });
  });

  group('SessionDoc.differsStructurallyFrom', () {
    const base = SessionDoc(
      backendRef: 'server-1',
      itemIds: ['a', 'b'],
      queuePosition: 0,
      trackPositionMs: 1000,
      playing: true,
    );

    test('ignores the position, which is handled by prediction', () {
      expect(
        base.copyWith(trackPositionMs: 999999).differsStructurallyFrom(base),
        isFalse,
      );
    });

    test('notices a track change', () {
      expect(
        base.copyWith(queuePosition: 1).differsStructurallyFrom(base),
        isTrue,
      );
    });

    test('notices pausing', () {
      expect(base.copyWith(playing: false).differsStructurallyFrom(base), true);
    });

    test('notices a new queue', () {
      expect(
        base.copyWith(itemIds: ['a', 'c']).differsStructurallyFrom(base),
        isTrue,
      );
    });
  });
}
