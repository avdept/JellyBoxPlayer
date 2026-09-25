import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/output_controller.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optional_features/jellybox_cloud.dart';

class _Target implements PlaybackTarget {
  _Target(this.id, this.kind);

  @override
  final String id;
  @override
  final PlaybackTargetKind kind;

  @override
  String get name => id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Playback extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  _Playback(this.log, this._target) : super(PlaybackState.initial());

  final List<String> log;
  PlaybackTarget _target;

  @override
  PlaybackTarget get target => _target;

  @override
  Future<void> switchTarget(PlaybackTarget to, {bool carryQueue = true}) async {
    log.add('switch ${to.id}${carryQueue ? '' : ' empty'}');
    _target = to;
  }

  @override
  Future<void> reloadOnTarget() async => log.add('reload');
}

class _Cloud extends StateNotifier<CloudState>
    with Mock
    implements CloudNotifier {
  _Cloud(this.log, {this.claims = true}) : super(const CloudState());

  final List<String> log;
  final bool claims;

  @override
  Future<bool> claimHere() async {
    log.add('claim');
    return claims;
  }

  @override
  Future<void> handoffTo(String deviceId) async => log.add('handoff $deviceId');
}

const _iphone = ConductorDevice(
  id: 'iphone',
  name: 'iPhone',
  platform: 'ios',
  isRenderer: true,
);

void main() {
  final local = _Target('local', PlaybackTargetKind.local);
  final kef = _Target('uuid:kef', PlaybackTargetKind.upnp);

  late List<String> log;

  OutputController controllerWith({
    ConductorDevice? elsewhere,
    PlaybackTarget? current,
    bool claims = true,
  }) {
    final container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(local),
        remoteRendererProvider.overrideWithValue(elsewhere),
        playbackProvider.overrideWith((_) => _Playback(log, current ?? local)),
        cloudProvider.overrideWith((_) => _Cloud(log, claims: claims)),
      ],
    );
    addTearDown(container.dispose);
    return container.read(outputControllerProvider);
  }

  setUp(() => log = []);

  group('while another device is playing', () {
    test('a speaker takes the session over from that device', () async {
      await controllerWith(elsewhere: _iphone).playOn(kef);

      expect(log, ['switch uuid:kef empty', 'claim']);
    });

    test('this device takes the session over from that device', () async {
      await controllerWith(elsewhere: _iphone, current: kef).playHere();

      expect(log, ['switch local empty', 'claim']);
    });

    test('a refused claim leaves the local queue on the new output', () async {
      await controllerWith(elsewhere: _iphone, claims: false).playOn(kef);

      expect(log, ['switch uuid:kef empty', 'claim', 'reload']);
    });
  });

  test('with nothing playing elsewhere a speaker just takes over', () async {
    await controllerWith().playOn(kef);

    expect(log, ['switch uuid:kef']);
  });

  test('handing off while casting releases the speaker', () async {
    await controllerWith(current: kef).handOffTo(_iphone);

    expect(log, ['handoff iphone', 'switch local']);
  });

  test('handing off from this device leaves its output alone', () async {
    await controllerWith().handOffTo(_iphone);

    expect(log, ['handoff iphone']);
  });
}
