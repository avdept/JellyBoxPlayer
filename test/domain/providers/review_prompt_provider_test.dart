import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/providers/review_prompt_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const policy = ReviewPromptPolicy(
    minCompletedTracks: 3,
    minAge: Duration(days: 2),
    cooldown: Duration(days: 30),
  );

  late DateTime now;

  Future<ReviewPromptNotifier> build({
    Map<String, Object> initial = const {},
    bool supported = true,
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return ReviewPromptNotifier(
      prefs,
      policy: policy,
      supported: supported,
      now: () => now,
    );
  }

  setUp(() => now = DateTime(2026, 9, 15));

  test(
    'stamps first launch and stays quiet until the account is old enough',
    () async {
      final notifier = await build();
      for (var i = 0; i < 5; i++) {
        notifier.recordTrackCompleted();
      }
      expect(notifier.state, isFalse);

      now = now.add(const Duration(days: 2));
      notifier.recordTrackCompleted();
      expect(notifier.state, isTrue);
    },
  );

  test('needs the completed-track threshold', () async {
    final notifier = await build();
    now = now.add(const Duration(days: 10));
    notifier
      ..recordTrackCompleted()
      ..recordTrackCompleted();
    expect(notifier.state, isFalse);
    notifier.recordTrackCompleted();
    expect(notifier.state, isTrue);
  });

  test('marking prompted resets the count and enforces the cooldown', () async {
    final notifier = await build();
    now = now.add(const Duration(days: 10));
    for (var i = 0; i < 3; i++) {
      notifier.recordTrackCompleted();
    }
    expect(notifier.state, isTrue);

    await notifier.markPrompted();
    expect(notifier.state, isFalse);

    now = now.add(const Duration(days: 10));
    for (var i = 0; i < 3; i++) {
      notifier.recordTrackCompleted();
    }
    expect(notifier.state, isFalse);

    now = now.add(const Duration(days: 30));
    notifier.recordTrackCompleted();
    expect(notifier.state, isTrue);
  });

  test('survives a restart through persisted counters', () async {
    final first = await build();
    now = now.add(const Duration(days: 10));
    first
      ..recordTrackCompleted()
      ..recordTrackCompleted();

    final prefs = await SharedPreferences.getInstance();
    final restarted = ReviewPromptNotifier(
      prefs,
      policy: policy,
      supported: true,
      now: () => now,
    )..recordTrackCompleted();
    expect(restarted.state, isTrue);
  });

  test('does nothing on unsupported builds', () async {
    final notifier = await build(supported: false);
    now = now.add(const Duration(days: 10));
    for (var i = 0; i < 10; i++) {
      notifier.recordTrackCompleted();
    }
    expect(notifier.state, isFalse);
  });
}
