import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';

void main() {
  const home = 'http://jellyfin.home';
  const relay = 'https://cloud.jellybox.app/r/key';
  const cover = '/Items/a1/Images/Primary?fillWidth=420&tag=t';

  const onRelay = ArtworkRoute(addresses: [home, relay], active: relay);

  test('- files a cover under the same key at home and over the tunnel', () {
    expect(onRelay.keyFor('$home$cover'), cover);
    expect(onRelay.keyFor('$relay$cover'), cover);
  });

  test('- fetches a cover built for home through the active address', () {
    expect(onRelay.fetchUrl('$home$cover'), '$relay$cover');
    expect(onRelay.fetchUrl('$relay$cover'), '$relay$cover');
  });

  test('- leaves addresses of other hosts alone', () {
    const elsewhere = 'http://jellyfin.homelab/Items/a1/Images/Primary';

    expect(onRelay.keyFor(elsewhere), elsewhere);
    expect(onRelay.fetchUrl(elsewhere), elsewhere);
  });
}
