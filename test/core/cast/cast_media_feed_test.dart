import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/cast/cast_media_feed.dart';
import 'package:jplayer/src/core/enums/enums.dart';

const _channel = 'com.felnanuke.google_cast.remote_media_client';
const _iosChannel = 'google_cast.remote_media_client';

const _playing = '''
{"mediaSessionId":1,"playerState":"PLAYING","currentTime":2.1,"playbackRate":1,
"currentItemId":7,"activeTrackIds":"[]","shuffle":false,
"volume":{"level":1,"muted":false},"repeatMode":"REPEAT_OFF",
"media":{"contentId":"song-a","contentType":"audio/flac","streamType":"BUFFERED",
"duration":253.4,"tracks":[{"trackId":1,"type":"AUDIO"}],
"metadata":{"metadataType":3,"title":"RUNNING","artist":"NF"}},
"items":[{"itemId":7,"autoplay":true,"media":{"contentId":"song-a"}},
{"itemId":8,"autoplay":true,"media":{"contentId":"song-b"}}]}
''';

Future<void> _send(
  String method,
  Object? arguments, {
  String channel = _channel,
}) => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .handlePlatformMessage(
      channel,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CastChannelFeed feed;

  setUp(() => feed = CastChannelFeed.instance);

  test('- reads a receiver status that the Cast plugin cannot parse', () async {
    final statuses = <CastReceiverStatus>[];
    final subscription = feed.statuses.listen(statuses.add);
    addTearDown(subscription.cancel);

    await _send('onMediaStatusChanged', _playing);

    final status = statuses.single;
    expect(status.status, PlaybackStatus.playing);
    expect(status.mediaSessionId, 1);
    expect(status.itemId, 7);
    expect(status.contentId, 'song-a');
    expect(status.duration, const Duration(milliseconds: 253400));
    expect(status.finished, isFalse);
  });

  test('- reports the end of the queue and a receiver error apart', () async {
    final statuses = <CastReceiverStatus>[];
    final subscription = feed.statuses.listen(statuses.add);
    addTearDown(subscription.cancel);

    await _send(
      'onMediaStatusChanged',
      '{"playerState":"IDLE","idleReason":"FINISHED","currentItemId":9}',
    );
    await _send(
      'onMediaStatusChanged',
      '{"playerState":"IDLE","idleReason":"ERROR","currentItemId":9}',
    );

    expect(statuses.first.finished, isTrue);
    expect(statuses.first.status, PlaybackStatus.stopped);
    expect(statuses.last.status, PlaybackStatus.error);
    expect(statuses.last.failed, isTrue);
  });

  test('- treats a stop from another controller as a pause', () async {
    final statuses = <CastReceiverStatus>[];
    final subscription = feed.statuses.listen(statuses.add);
    addTearDown(subscription.cancel);

    await _send(
      'onMediaStatusChanged',
      '{"playerState":"IDLE","idleReason":"CANCELLED","currentItemId":9,'
          '"media":{"contentId":"song-a","contentUrl":"http://s/a.flac"}}',
    );
    await _send(
      'onMediaStatusChanged',
      '{"playerState":"IDLE","idleReason":"INTERRUPTED","currentItemId":9}',
    );

    expect(statuses.first.status, PlaybackStatus.paused);
    expect(statuses.first.contentUrl, 'http://s/a.flac');
    expect(statuses.last.status, PlaybackStatus.paused);
    expect(statuses.last.finished, isFalse);
  });

  test('- pairs queue item ids with their content', () async {
    final queues = <List<CastQueueEntry>>[];
    final subscription = feed.queue.listen(queues.add);
    addTearDown(subscription.cancel);

    await _send('onQueueStatusChanged', [
      '{"itemId":7,"media":{"contentId":"song-a"}}',
      '{"itemId":8,"media":{"contentId":"song-b"}}',
      '{"media":{"contentId":"no-id"}}',
    ]);

    expect([for (final entry in queues.single) entry.itemId], [7, 8]);
    expect(
      [for (final entry in queues.single) entry.contentId],
      [
        'song-a',
        'song-b',
      ],
    );
  });

  test('- passes the player position through in milliseconds', () async {
    final positions = <Duration>[];
    final subscription = feed.positions.listen(positions.add);
    addTearDown(subscription.cancel);

    await _send('onPlayerPositionChanged', {'progress': 12345});

    expect(positions.single, const Duration(milliseconds: 12345));
  });

  test('- shrugs off a payload it cannot read', () async {
    final statuses = <CastReceiverStatus>[];
    final subscription = feed.statuses.listen(statuses.add);
    addTearDown(subscription.cancel);

    await _send('onMediaStatusChanged', 'not json at all');
    await _send('onMediaStatusChanged', null);

    expect(statuses, isEmpty);
  });

  group('on iOS', () {
    Future<void> sendIos(String method, Object? arguments) =>
        _send(method, arguments, channel: _iosChannel);

    test('- reads the GCK media status map', () async {
      final statuses = <CastReceiverStatus>[];
      final subscription = feed.statuses.listen(statuses.add);
      addTearDown(subscription.cancel);

      await sendIos('onUpdateMediaStatus', {
        'mediaSessionID': 3,
        'playerState': 2,
        'idleReason': 0,
        'currentItemId': 7,
        'queueHasNextItem': true,
        'mediaInformation': {
          'contentID': 'song-a',
          'contentType': 'audio/flac',
          'duration': 253.4,
        },
      });
      await sendIos('onUpdateMediaStatus', {
        'playerState': 3,
        'idleReason': 0,
        'currentItemId': 7,
      });
      await sendIos('onUpdateMediaStatus', {
        'playerState': 4,
        'idleReason': 0,
        'currentItemId': 0,
      });

      expect(statuses[0].status, PlaybackStatus.playing);
      expect(statuses[0].mediaSessionId, 3);
      expect(statuses[0].itemId, 7);
      expect(statuses[0].contentId, 'song-a');
      expect(statuses[0].duration, const Duration(milliseconds: 253400));
      expect(statuses[1].status, PlaybackStatus.paused);
      expect(statuses[2].status, PlaybackStatus.buffering);
      expect(statuses[2].itemId, isNull);
    });

    test('- reports the end of the queue and a receiver error apart', () async {
      final statuses = <CastReceiverStatus>[];
      final subscription = feed.statuses.listen(statuses.add);
      addTearDown(subscription.cancel);

      await sendIos('onUpdateMediaStatus', {
        'playerState': 1,
        'idleReason': 1,
        'currentItemId': 9,
      });
      await sendIos('onUpdateMediaStatus', {
        'playerState': 1,
        'idleReason': 4,
        'currentItemId': 9,
      });

      expect(statuses.first.finished, isTrue);
      expect(statuses.first.status, PlaybackStatus.stopped);
      expect(statuses.last.status, PlaybackStatus.error);
      expect(statuses.last.failed, isTrue);
    });

    test('- treats a stop from another controller as a pause', () async {
      final statuses = <CastReceiverStatus>[];
      final subscription = feed.statuses.listen(statuses.add);
      addTearDown(subscription.cancel);

      await sendIos('onUpdateMediaStatus', {
        'playerState': 1,
        'idleReason': 2,
        'currentItemId': 9,
        'mediaInformation': {'contentURL': 'http://s/a.flac'},
      });

      expect(statuses.single.status, PlaybackStatus.paused);
      expect(statuses.single.contentUrl, 'http://s/a.flac');
    });

    test('- pairs queue item ids with their content', () async {
      final queues = <List<CastQueueEntry>>[];
      final subscription = feed.queue.listen(queues.add);
      addTearDown(subscription.cancel);

      await sendIos('updateQueueItems', [
        {
          'itemId': 7,
          'autoPlay': true,
          'mediaInformation': {'contentID': 'song-a'},
        },
        {
          'itemId': 8,
          'mediaInformation': {'contentID': 'song-b'},
        },
        {
          'mediaInformation': {'contentID': 'no-id'},
        },
      ]);

      expect([for (final entry in queues.single) entry.itemId], [7, 8]);
      expect(
        [for (final entry in queues.single) entry.contentId],
        ['song-a', 'song-b'],
      );
    });

    test('- passes the player position through in milliseconds', () async {
      final positions = <Duration>[];
      final subscription = feed.positions.listen(positions.add);
      addTearDown(subscription.cancel);

      await sendIos('onUpdatePlayerPosition', 61500);

      expect(positions.single, const Duration(milliseconds: 61500));
    });

    test('- shrugs off a status it cannot read', () async {
      final statuses = <CastReceiverStatus>[];
      final subscription = feed.statuses.listen(statuses.add);
      addTearDown(subscription.cancel);

      await sendIos('onUpdateMediaStatus', null);

      expect(statuses, isEmpty);
    });
  });
}
