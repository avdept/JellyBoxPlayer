import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late _MockAudioPlayer player;
  late StreamController<LoopMode> loopModes;

  setUpAll(() => registerFallbackValue(LoopMode.off));

  setUp(() {
    player = _MockAudioPlayer();
    loopModes = StreamController<LoopMode>.broadcast();
    when(() => player.loopMode).thenReturn(LoopMode.off);
    when(() => player.loopModeStream).thenAnswer((_) => loopModes.stream);
    when(() => player.setLoopMode(any())).thenAnswer((_) async {});
  });

  Future<ProviderContainer> attach(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final probe = Provider<Future<void>>(
      (ref) => rememberRepeatMode(ref, player),
    );
    await container.read(probe);
    return container;
  }

  test('- applies the saved repeat mode to the player', () async {
    await attach({
      'app_settings': jsonEncode({'repeat_mode': 'all'}),
    });

    verify(() => player.setLoopMode(LoopMode.all)).called(1);
  });

  test('- leaves the player alone when nothing was saved', () async {
    await attach({});

    verifyNever(() => player.setLoopMode(any()));
  });

  test('- remembers each repeat mode change', () async {
    final container = await attach({});

    loopModes.add(LoopMode.one);
    await pumpEventQueue();

    expect(
      container
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.repeatMode),
      'one',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      jsonDecode(prefs.getString('app_settings')!),
      containsPair('repeat_mode', 'one'),
    );
  });
}
