import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/discord/discord_activity.dart';
import 'package:jplayer/src/core/discord/discord_frame.dart';
import 'package:jplayer/src/core/discord/discord_presence_client.dart';
import 'package:jplayer/src/core/discord/discord_transport.dart';

class _FakeTransport implements DiscordTransport {
  final _controller = StreamController<List<int>>();
  final _reader = DiscordFrameReader();
  final sent = <DiscordFrame>[];

  bool closed = false;

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  void send(List<int> data) => sent.addAll(_reader.add(data));

  @override
  Future<void> close() async {
    closed = true;
    if (!_controller.isClosed) await _controller.close();
  }

  void fail() => _controller.addError(const SocketException('dropped'));

  void emit(int opcode, Map<String, Object?> payload) =>
      _controller.add(encodeDiscordFrame(opcode, payload));

  Future<void> becomeReady() async {
    emit(DiscordOpcode.frame, {'cmd': 'DISPATCH', 'evt': 'READY'});
    await pumpEventQueue();
  }

  List<DiscordFrame> get activities =>
      sent.where((frame) => frame.payload['cmd'] == 'SET_ACTIVITY').toList();

  Map<String, Object?>? get lastActivity {
    final args = activities.last.payload['args']! as Map<String, Object?>;
    return args['activity'] as Map<String, Object?>?;
  }
}

void main() {
  late _FakeTransport transport;
  late DiscordPresenceClient client;

  setUp(() {
    transport = _FakeTransport();
    client = DiscordPresenceClient(
      applicationId: '1234567890',
      connect: () async => transport,
      sendBudget: 2,
      sendWindow: const Duration(milliseconds: 60),
    );
  });

  tearDown(() => client.stop());

  Future<void> start() async {
    client.start();
    await pumpEventQueue();
  }

  test('handshakes with the application id', () async {
    await start();

    expect(transport.sent, hasLength(1));
    expect(transport.sent.single.opcode, DiscordOpcode.handshake);
    expect(transport.sent.single.payload, {'v': 1, 'client_id': '1234567890'});
  });

  test('holds the activity until Discord reports READY', () async {
    await start();
    client.setActivity(DiscordActivity.listening(title: 'Bloom'));
    await pumpEventQueue();

    expect(transport.activities, isEmpty);
    expect(client.isReady, isFalse);

    await transport.becomeReady();

    expect(client.isReady, isTrue);
    expect(transport.lastActivity, containsPair('details', 'Bloom'));
    expect(transport.lastActivity, containsPair('type', 2));
  });

  test('sends the process id alongside the activity', () async {
    await start();
    await transport.becomeReady();
    client.setActivity(DiscordActivity.listening(title: 'Bloom'));
    await pumpEventQueue();

    final args = transport.activities.last.payload['args']!;
    expect((args as Map<String, Object?>)['pid'], isA<int>());
  });

  test('answers a ping with a matching pong', () async {
    await start();
    await transport.becomeReady();

    transport.emit(DiscordOpcode.ping, {'nonce': 'abc'});
    await pumpEventQueue();

    final pong = transport.sent.last;
    expect(pong.opcode, DiscordOpcode.pong);
    expect(pong.payload, {'nonce': 'abc'});
  });

  test('does not resend an unchanged activity', () async {
    await start();
    await transport.becomeReady();

    client.setActivity(DiscordActivity.listening(title: 'Bloom'));
    await pumpEventQueue();
    client.setActivity(DiscordActivity.listening(title: 'Bloom'));
    await pumpEventQueue();

    expect(transport.activities, hasLength(1));
  });

  test('sends immediately while the budget lasts', () async {
    await start();
    await transport.becomeReady();

    client.setActivity(DiscordActivity.listening(title: 'First'));
    await pumpEventQueue();
    client.setActivity(DiscordActivity.listening(title: 'Second'));
    await pumpEventQueue();

    expect(transport.activities, hasLength(2));
    expect(transport.lastActivity, containsPair('details', 'Second'));
  });

  test('defers past the budget and sends only the latest state', () async {
    await start();
    await transport.becomeReady();

    client
      ..setActivity(DiscordActivity.listening(title: 'First'))
      ..setActivity(DiscordActivity.listening(title: 'Second'));
    await pumpEventQueue();
    client
      ..setActivity(DiscordActivity.listening(title: 'Third'))
      ..setActivity(DiscordActivity.listening(title: 'Fourth'));
    await pumpEventQueue();

    expect(transport.activities, hasLength(2));
    expect(transport.lastActivity, containsPair('details', 'Second'));

    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(transport.activities, hasLength(3));
    expect(transport.lastActivity, containsPair('details', 'Fourth'));
  });

  test('clears the activity and closes the transport on stop', () async {
    await start();
    await transport.becomeReady();
    client.setActivity(DiscordActivity.listening(title: 'Bloom'));
    await pumpEventQueue();

    await client.stop();

    expect(transport.lastActivity, isNull);
    expect(transport.closed, isTrue);
    expect(client.isReady, isFalse);
  });

  test('stops retrying when Discord rejects the application id', () async {
    var connections = 0;
    client = DiscordPresenceClient(
      applicationId: 'not-an-app',
      connect: () async {
        connections++;
        return transport;
      },
      retryDelays: const [Duration(milliseconds: 10)],
    );

    await start();
    transport.emit(DiscordOpcode.close, {
      'code': 4000,
      'message': 'Invalid Client ID',
    });
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();

    expect(connections, 1);
    expect(transport.closed, isTrue);
  });

  test('reconnects when Discord closes for a transient reason', () async {
    final reconnected = _FakeTransport();
    var connections = 0;
    client = DiscordPresenceClient(
      applicationId: '1234567890',
      connect: () async {
        connections++;
        return connections == 1 ? transport : reconnected;
      },
      retryDelays: const [Duration(milliseconds: 10)],
    );

    await start();
    transport.emit(DiscordOpcode.close, {'code': 4003});
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();

    expect(connections, 2);
  });

  test('reconnects and restores the activity when the socket drops', () async {
    final reconnected = _FakeTransport();
    var connections = 0;
    client = DiscordPresenceClient(
      applicationId: '1234567890',
      connect: () async {
        connections++;
        return connections == 1 ? transport : reconnected;
      },
      retryDelays: const [Duration(milliseconds: 10)],
    );

    await start();
    await transport.becomeReady();
    client.setActivity(DiscordActivity.listening(title: 'Bloom'));
    await pumpEventQueue();
    expect(transport.activities, hasLength(1));

    transport.fail();
    await pumpEventQueue();
    expect(client.isReady, isFalse);
    expect(transport.closed, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();
    expect(connections, 2);
    expect(reconnected.sent.first.opcode, DiscordOpcode.handshake);

    await reconnected.becomeReady();

    expect(reconnected.lastActivity, containsPair('details', 'Bloom'));
  });
}
