import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTarget implements PlaybackTarget {
  _FakeTarget({required this.id, required this.kind});

  @override
  final String id;
  @override
  final PlaybackTargetKind kind;

  final applied = <double>[];

  @override
  Future<void> setVolume(double level) async => applied.add(level);

  @override
  Future<double?> currentVolume() async => 0.7;

  @override
  String get name => 'Fake';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<(VolumeNotifier, _FakeTarget, AppSettingsNotifier)> notifierFor(
    _FakeTarget target, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final settings = AppSettingsNotifier(
      await SharedPreferences.getInstance(),
    );
    return (VolumeNotifier(target, settings), target, settings);
  }

  test('- starts a new speaker at 10 percent', () async {
    final (notifier, target, _) = await notifierFor(
      _FakeTarget(id: 'uuid:kef', kind: PlaybackTargetKind.upnp),
    );
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.level, 0.1);
    expect(target.applied, [0.1]);
  });

  test('- resumes the level the speaker was left at', () async {
    final (notifier, target, _) = await notifierFor(
      _FakeTarget(id: 'uuid:kef', kind: PlaybackTargetKind.upnp),
      prefs: {
        'app_settings': '{"renderer_volumes":{"uuid:kef":0.35}}',
      },
    );
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.level, 0.35);
    expect(target.applied, [0.35]);
  });

  test('- remembers a change per speaker', () async {
    final (notifier, _, settings) = await notifierFor(
      _FakeTarget(id: 'uuid:kef', kind: PlaybackTargetKind.upnp),
    );
    await notifier.setLevel(0.4);

    expect(settings.rendererVolume('uuid:kef'), 0.4);
    expect(settings.rendererVolume('uuid:wiim'), isNull);
    expect(
      settings.numberOf(AppSetting.playerVolume),
      1.0,
      reason: 'the local player level is untouched',
    );
  });

  test('- keeps speakers apart', () async {
    final (kef, _, settings) = await notifierFor(
      _FakeTarget(id: 'uuid:kef', kind: PlaybackTargetKind.upnp),
    );
    await kef.setLevel(0.4);

    final wiim = VolumeNotifier(
      _FakeTarget(id: 'uuid:wiim', kind: PlaybackTargetKind.upnp),
      settings,
    );
    await Future<void>.delayed(Duration.zero);
    expect(wiim.state.level, 0.1, reason: 'unseen speaker gets the default');
    await wiim.setLevel(0.6);

    expect(settings.rendererVolume('uuid:kef'), 0.4);
    expect(settings.rendererVolume('uuid:wiim'), 0.6);
  });

  test('- leaves the local player on its own persisted level', () async {
    final (notifier, target, settings) = await notifierFor(
      _FakeTarget(id: 'local', kind: PlaybackTargetKind.local),
      prefs: {'app_settings': '{"player_volume":0.8}'},
    );
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.level, 0.8);
    expect(target.applied, [0.8]);

    await notifier.setLevel(0.5);
    expect(settings.numberOf(AppSetting.playerVolume), 0.5);
    expect(settings.rendererVolume('local'), isNull);
  });

  test('- muting does not overwrite the remembered level', () async {
    final (notifier, target, settings) = await notifierFor(
      _FakeTarget(id: 'uuid:kef', kind: PlaybackTargetKind.upnp),
    );
    await notifier.setLevel(0.4);
    await notifier.toggleMute();

    expect(target.applied.last, 0);
    expect(settings.rendererVolume('uuid:kef'), 0.4);

    await notifier.toggleMute();
    expect(notifier.state.level, 0.4);
    expect(target.applied.last, 0.4);
  });
}
