import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/data/storages/cast_session_storage.dart';
import 'package:jplayer/src/domain/playback/cast_session_resume.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockControlPoint extends Mock implements UpnpControlPoint {}

class _MockAvTransport extends Mock implements AvTransport {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final location = Uri.parse('http://192.168.0.20:49152/description.xml');

  late _MockControlPoint controlPoint;
  late _MockAvTransport transport;
  late CastSessionResume resume;

  UpnpRenderer renderer({String udn = 'uuid:kef'}) => UpnpRenderer(
    device: UpnpDevice(
      udn: udn,
      friendlyName: 'KEF LS50',
      deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
      location: location,
      services: const [],
    ),
    avTransport: transport,
  );

  void deviceReports(
    AvTransportState state, {
    String? trackUri,
    Duration position = Duration.zero,
  }) {
    when(transport.transportInfo).thenAnswer(
      (_) async => AvTransportInfo(state: state, status: 'OK'),
    );
    when(transport.positionInfo).thenAnswer(
      (_) async => AvPositionInfo(position: position, trackUri: trackUri),
    );
  }

  Future<void> saveSession() => CastSessionStorage().save(
    serverId: 'srv',
    session: CastSession(
      udn: 'uuid:kef',
      location: location,
      name: 'KEF LS50',
    ),
  );

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://example.org'));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controlPoint = _MockControlPoint();
    transport = _MockAvTransport();
    resume = CastSessionResume(
      controlPoint,
      searchTimeout: const Duration(milliseconds: 20),
    );
    when(
      () => controlPoint.describe(location),
    ).thenAnswer((_) async => renderer());
    when(
      () => controlPoint.discoverRenderers(timeout: any(named: 'timeout')),
    ).thenAnswer((_) => const Stream<UpnpRenderer>.empty());
  });

  test('- returns nothing without a saved session', () async {
    expect(await resume.find('srv'), isNull);
    verifyNever(() => controlPoint.describe(any()));
  });

  test("- leaves another server's session alone", () async {
    await saveSession();

    expect(await resume.find('other'), isNull);
    verifyNever(() => controlPoint.describe(any()));
    expect(await CastSessionStorage().load('srv'), isNotNull);
  });

  test('- finds the renderer still playing and keeps the session', () async {
    await saveSession();
    deviceReports(
      AvTransportState.playing,
      trackUri: 'http://192.168.0.9:8096/Audio/song-1/universal',
      position: const Duration(seconds: 42),
    );

    final session = await resume.find('srv');

    expect(session, isNotNull);
    expect(session!.playing, isTrue);
    expect(session.trackUri.path, '/Audio/song-1/universal');
    expect(session.position, const Duration(seconds: 42));
    expect(session.renderer.id, 'uuid:kef');
    expect(await CastSessionStorage().load('srv'), isNotNull);
  });

  test('- reports a paused renderer as paused', () async {
    await saveSession();
    deviceReports(
      AvTransportState.pausedPlayback,
      trackUri: 'http://192.168.0.9:8096/Audio/song-1/universal',
    );

    final session = await resume.find('srv');

    expect(session, isNotNull);
    expect(session!.playing, isFalse);
  });

  test('- drops the session when the renderer stopped', () async {
    await saveSession();
    deviceReports(AvTransportState.stopped);

    expect(await resume.find('srv'), isNull);
    expect(await CastSessionStorage().load('srv'), isNull);
  });

  test('- drops the session when the renderer plays nothing', () async {
    await saveSession();
    deviceReports(AvTransportState.playing);

    expect(await resume.find('srv'), isNull);
    expect(await CastSessionStorage().load('srv'), isNull);
  });

  test('- searches the network when the saved address answers as a '
      'different device', () async {
    await saveSession();
    when(
      () => controlPoint.describe(location),
    ).thenAnswer((_) async => renderer(udn: 'uuid:other'));
    when(
      () => controlPoint.discoverRenderers(timeout: any(named: 'timeout')),
    ).thenAnswer(
      (_) => Stream.fromIterable([renderer(udn: 'uuid:other'), renderer()]),
    );
    deviceReports(
      AvTransportState.playing,
      trackUri: 'http://192.168.0.9:8096/Audio/song-1/universal',
    );

    final session = await resume.find('srv');

    expect(session, isNotNull);
    expect(session!.renderer.id, 'uuid:kef');
  });

  test('- drops the session when the renderer is gone', () async {
    await saveSession();
    when(() => controlPoint.describe(location)).thenAnswer((_) async => null);

    expect(await resume.find('srv'), isNull);
    expect(await CastSessionStorage().load('srv'), isNull);
  });

  test('- drops the session when probing the renderer fails', () async {
    await saveSession();
    when(transport.transportInfo).thenThrow(StateError('no route'));

    expect(await resume.find('srv'), isNull);
    expect(await CastSessionStorage().load('srv'), isNull);
  });
}
