import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/didl_lite.dart';
import 'package:xml/xml.dart';

void main() {
  const didlNs = 'urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/';
  const dcNs = 'http://purl.org/dc/elements/1.1/';
  const upnpNs = 'urn:schemas-upnp-org:metadata-1-0/upnp/';

  String build({
    String title = 'Track',
    String? artist = 'Artist',
    String? album = 'Album',
    Uri? artUri,
    Uri? uri,
    Duration duration = const Duration(minutes: 3, seconds: 21),
    bool seekable = true,
    bool transcoded = false,
  }) => buildDidlLite(
    itemId: 'song-1',
    title: title,
    uri: uri ?? Uri.parse('http://jelly.local:8096/Audio/song-1/universal'),
    mimeType: 'audio/mpeg',
    duration: duration,
    artist: artist,
    album: album,
    artUri: artUri,
    seekable: seekable,
    transcoded: transcoded,
  );

  XmlElement itemOf(String didl) =>
      XmlDocument.parse(didl).rootElement.childElements.single;

  test('- describes the track a renderer needs', () {
    final item = itemOf(build());

    expect(item.getAttribute('id'), 'song-1');
    expect(item.getAttribute('parentID'), '-1');
    expect(item.getAttribute('restricted'), '1');
    expect(item.getElement('title', namespace: dcNs)?.innerText, 'Track');
    expect(
      item.getElement('class', namespace: upnpNs)?.innerText,
      'object.item.audioItem.musicTrack',
    );

    final res = item.getElement('res', namespace: didlNs)!;
    expect(res.innerText, 'http://jelly.local:8096/Audio/song-1/universal');
    expect(res.getAttribute('duration'), '0:03:21.000');
  });

  test('- survives characters that would break hand-written xml', () {
    const nasty = 'Tom & Jerry <"quoted"> \'apostrophe\'';
    final url = Uri.parse(
      'http://jelly.local:8096/Audio/x/universal?ApiKey=k&Container=mp3,m4a',
    );

    final item = itemOf(build(title: nasty, artist: nasty, uri: url));

    // Parsed back out, the values must equal exactly what went in.
    expect(item.getElement('title', namespace: dcNs)?.innerText, nasty);
    expect(item.getElement('artist', namespace: upnpNs)?.innerText, nasty);
    expect(item.getElement('res', namespace: didlNs)?.innerText, '$url');
  });

  test('- keeps the ampersand escaped in the wire form', () {
    final didl = build(
      uri: Uri.parse('http://jelly.local:8096/Audio/x?a=1&b=2'),
    );

    expect(didl, contains('a=1&amp;b=2'));
    expect(didl, isNot(contains('a=1&b=2')));
  });

  test('- omits fields the server did not give us', () {
    final item = itemOf(build(artist: null, album: null));

    expect(item.getElement('creator', namespace: dcNs), isNull);
    expect(item.getElement('artist', namespace: upnpNs), isNull);
    expect(item.getElement('album', namespace: upnpNs), isNull);
    expect(item.getElement('albumArtURI', namespace: upnpNs), isNull);
  });

  test('- omits empty strings the same way as nulls', () {
    final item = itemOf(build(artist: '', album: ''));

    expect(item.getElement('artist', namespace: upnpNs), isNull);
    expect(item.getElement('album', namespace: upnpNs), isNull);
  });

  test('- carries album art when there is any', () {
    final art = Uri.parse('http://jelly.local:8096/Items/x/Images/Primary');
    final item = itemOf(build(artUri: art));

    expect(item.getElement('albumArtURI', namespace: upnpNs)?.innerText, '$art');
  });

  test('- leaves out a duration it does not know', () {
    final item = itemOf(build(duration: Duration.zero));

    expect(
      item.getElement('res', namespace: didlNs)?.getAttribute('duration'),
      isNull,
    );
  });

  test('- states seek and transcode support in protocolInfo', () {
    String protocolInfo(String didl) => itemOf(didl)
        .getElement('res', namespace: didlNs)!
        .getAttribute('protocolInfo')!;

    expect(
      protocolInfo(build()),
      'http-get:*:audio/mpeg:DLNA.ORG_OP=01;DLNA.ORG_CI=0;'
      'DLNA.ORG_FLAGS=01700000000000000000000000000000',
    );
    expect(protocolInfo(build(seekable: false)), contains('DLNA.ORG_OP=00'));
    expect(protocolInfo(build(transcoded: true)), contains('DLNA.ORG_CI=1'));
  });

  test('- declares the namespaces renderers look for', () {
    final root = XmlDocument.parse(build()).rootElement;

    expect(root.name.local, 'DIDL-Lite');
    expect(root.getAttribute('xmlns'), didlNs);
    expect(root.getAttribute('xmlns:dc'), dcNs);
    expect(root.getAttribute('xmlns:upnp'), upnpNs);
    expect(
      root.getAttribute('xmlns:dlna'),
      'urn:schemas-dlna-org:metadata-1-0/',
    );
  });

  test('- emits no xml declaration, since it is nested in soap', () {
    expect(build(), startsWith('<DIDL-Lite'));
  });
}
