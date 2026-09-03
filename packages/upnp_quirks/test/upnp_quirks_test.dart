import 'package:test/test.dart';
import 'package:upnp_quirks/upnp_quirks.dart';

void main() {
  DeviceFingerprint fingerprint({
    String? manufacturer,
    String? modelName,
    String? friendlyName,
    Set<String> sinkMimeTypes = const {'audio/mpeg'},
  }) => DeviceFingerprint(
    manufacturer: manufacturer,
    modelName: modelName,
    friendlyName: friendlyName,
    deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
    actions: const {'Play', 'Stop', 'SetAVTransportURI', 'Seek'},
    sinkMimeTypes: sinkMimeTypes,
  );

  group('quirksFor', () {
    test('- hands back the defaults for a device we know nothing about', () {
      final quirks = quirksFor(
        fingerprint(manufacturer: 'Acme Audio', modelName: 'Box 3000'),
      );

      expect(quirks.queueNextTrack, isTrue);
      expect(quirks.sendTrackMetadata, isTrue);
      expect(quirks.seekUnit, SeekUnit.relativeTime);
      expect(quirks.volumeRange, 100);
      expect(quirks.pollInterval, const Duration(seconds: 1));
      expect(quirks.note, isNull);
    });

    test('- resolves to the defaults for every device without a table', () {
      final devices = [
        fingerprint(manufacturer: 'Sonos, Inc.', modelName: 'Play:5'),
        fingerprint(manufacturer: 'Samsung Electronics', modelName: 'HG55BU'),
        fingerprint(friendlyName: 'RINCON_B8E9375831C001400 - Play:5'),
      ];

      for (final device in devices) {
        expect(quirksFor(device).toJson(), DeviceQuirks.defaults.toJson());
      }
    });

    test('- matches nothing when the device says nothing about itself', () {
      expect(quirksFor(const DeviceFingerprint()).queueNextTrack, isTrue);
      expect(rulesFor(const DeviceFingerprint()), isEmpty);
    });
  });

  group('rules', () {
    test('- every rule records the evidence behind it', () {
      for (final rule in quirkRules) {
        expect(rule.name, isNotEmpty);
        expect(rule.evidence.length, greaterThan(40), reason: rule.name);
        expect(
          rule.matchAny.isNotEmpty || rule.requireAll.isNotEmpty,
          isTrue,
          reason: '${rule.name} would match every device',
        );
      }
    });

    test('- rule names are unique', () {
      final names = quirkRules.map((rule) => rule.name).toSet();

      expect(names, hasLength(quirkRules.length));
    });

    test('- reports which rules applied to a device', () {
      final applied = rulesFor(fingerprint(manufacturer: 'Sonos, Inc.'));

      expect(applied, hasLength(lessThanOrEqualTo(quirkRules.length)));
      for (final rule in applied) {
        expect(quirkRules, contains(rule));
      }
    });

    test('- matching is substring based over the whole fingerprint', () {
      const rule = QuirkRule(
        name: 'test',
        evidence: 'exercises the matcher without depending on the real table',
        matchAny: ['sonos', 'rincon'],
        apply: _noNextTrack,
      );

      expect(rule.matches(fingerprint(manufacturer: 'Sonos, Inc.')), isTrue);
      expect(
        rule.matches(fingerprint(friendlyName: 'RINCON_B8E937 - Play:5')),
        isTrue,
      );
      expect(rule.matches(fingerprint(manufacturer: 'Samsung')), isFalse);
      expect(rule.matches(const DeviceFingerprint()), isFalse);
      expect(rule.apply(DeviceQuirks.defaults).queueNextTrack, isFalse);
    });
  });

  group('quirk behaviour', () {
    test('- scales volume into the device range', () {
      const defaults = DeviceQuirks.defaults;
      const coarse = DeviceQuirks(volumeRange: 15);

      expect(defaults.volumeToWire(0.4), 40);
      expect(defaults.volumeFromWire(40), closeTo(0.4, 0.001));
      expect(coarse.volumeToWire(0.5), 8);
      expect(coarse.volumeFromWire(15), 1);
      expect(coarse.volumeToWire(2), 15);
      expect(coarse.volumeFromWire(30), 1);
    });

    test('- filters mime types the device claims but cannot play', () {
      const quirks = DeviceQuirks(unsupportedMimeTypes: {'audio/x-flac'});

      expect(
        quirks.playableMimeTypes({'audio/mpeg', 'audio/x-flac', 'audio/mp4'}),
        {'audio/mpeg', 'audio/mp4'},
      );
    });

    test('- serialises for a field report', () {
      final json = const DeviceQuirks(
        queueNextTrack: false,
        volumeRange: 15,
        unsupportedMimeTypes: {'audio/x-flac'},
        note: 'example',
      ).toJson();

      expect(json['queueNextTrack'], isFalse);
      expect(json['seekUnit'], 'REL_TIME');
      expect(json['pollIntervalMs'], 1000);
      expect(json['volumeRange'], 15);
      expect(json['unsupportedMimeTypes'], ['audio/x-flac']);
      expect(json['note'], 'example');
    });
  });

  group('DeviceFingerprint', () {
    test('- serialises what we know, skipping what we do not', () {
      final json = fingerprint(
        manufacturer: 'Sonos, Inc.',
        modelName: 'Play:5',
      ).toJson();

      expect(json['manufacturer'], 'Sonos, Inc.');
      expect(json['modelName'], 'Play:5');
      expect(json.containsKey('modelNumber'), isFalse);
      expect(json['actions'], contains('SetAVTransportURI'));
      expect(json['sinkMimeTypes'], ['audio/mpeg']);
    });

    test('- searches over every field it has', () {
      expect(
        fingerprint(friendlyName: 'Kitchen Play:5').searchable,
        contains('kitchen play:5'),
      );
    });
  });
}

DeviceQuirks _noNextTrack(DeviceQuirks base) =>
    base.copyWith(queueNextTrack: false);
