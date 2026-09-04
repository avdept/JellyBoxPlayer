import 'package:jplayer/src/core/upnp/upnp_duration.dart';

String buildDidlLite({
  required String itemId,
  required String title,
  required Uri uri,
  required String mimeType,
  required Duration duration,
  String? artist,
  String? album,
  Uri? artUri,
  bool seekable = true,
  bool transcoded = false,
}) {
  final operations = seekable ? '01' : '00';
  final conversion = transcoded ? '1' : '0';
  final protocolInfo =
      'http-get:*:$mimeType:DLNA.ORG_OP=$operations;DLNA.ORG_CI=$conversion;'
      'DLNA.ORG_FLAGS=01700000000000000000000000000000';

  final buffer = StringBuffer()
    ..write('<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" ')
    ..write('xmlns:dc="http://purl.org/dc/elements/1.1/" ')
    ..write('xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" ')
    ..write('xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">')
    ..write('<item id="${_escape(itemId)}" parentID="-1" restricted="1">')
    ..write('<dc:title>${_escape(title)}</dc:title>')
    ..write('<upnp:class>object.item.audioItem.musicTrack</upnp:class>');

  if (artist != null && artist.isNotEmpty) {
    buffer
      ..write('<dc:creator>${_escape(artist)}</dc:creator>')
      ..write('<upnp:artist>${_escape(artist)}</upnp:artist>');
  }
  if (album != null && album.isNotEmpty) {
    buffer.write('<upnp:album>${_escape(album)}</upnp:album>');
  }
  if (artUri != null) {
    buffer.write(
      '<upnp:albumArtURI>${_escape('$artUri')}</upnp:albumArtURI>',
    );
  }

  buffer
    ..write('<res protocolInfo="${_escape(protocolInfo)}"')
    ..write(
      duration > Duration.zero
          ? ' duration="${formatUpnpDuration(duration)}.000"'
          : '',
    )
    ..write('>${_escape('$uri')}</res>')
    ..write('</item></DIDL-Lite>');

  return buffer.toString();
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
