import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/android_auto/cover_art_uri.dart';

void main() {
  final server = Uri.parse('https://jf.example/Items/1/Images/Primary?tag=a');

  test('hides a server url behind an opaque key', () {
    final covers = RemoteCoverArt();
    final uri = covers.register(server);

    expect(uri.scheme, 'content');
    expect(uri.authority, coverArtAuthority);
    expect(uri.pathSegments.first, remoteCoverSegment);
    expect(uri.toString(), isNot(contains('jf.example')));
    expect(covers.urlFor(uri.pathSegments.last), server.toString());
  });

  test('gives the same url the same key', () {
    final covers = RemoteCoverArt();

    expect(covers.register(server), covers.register(server));
  });

  test('knows nothing about keys it did not hand out', () {
    expect(RemoteCoverArt().urlFor('deadbeef'), isNull);
  });

  test('forgets the least recently registered url past its capacity', () {
    final covers = RemoteCoverArt(capacity: 2);
    final first = covers.register(Uri.parse('https://jf.example/1'));
    final second = covers.register(Uri.parse('https://jf.example/2'));
    covers
      ..register(Uri.parse('https://jf.example/1'))
      ..register(Uri.parse('https://jf.example/3'));

    expect(covers.urlFor(first.pathSegments.last), isNotNull);
    expect(covers.urlFor(second.pathSegments.last), isNull);
  });

  test('leaves server urls alone without a registry', () {
    expect(androidCoverArtUri(server), same(server));
  });

  test('keeps non-network uris as they are', () {
    final resource = Uri.parse('android.resource://app/drawable/icon');

    expect(
      androidCoverArtUri(resource, remote: RemoteCoverArt()),
      same(resource),
    );
  });
}
